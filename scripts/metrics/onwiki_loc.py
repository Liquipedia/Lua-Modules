#!/usr/bin/env python3
"""Metric 2: on-wiki Lua LOC per wiki (Module namespace code NOT managed in this repo).

For each wiki, fetches all pages in the Module namespace (ns 828) via the
MediaWiki API and counts lines of code, excluding:

  * pages that are deployed from this repo — identified by matching page
    titles against the ``-- page=Module:...`` headers of files in that
    wiki's own repo dir (lua/wikis/<wiki>). Commons gets no special
    treatment: a page whose title only exists in the commons repo dir is an
    on-wiki copy and counts as on-wiki code;
  * archive / sandbox / dev pages — titles matching (case-insensitive)
    ``Archive/``, ``/Archive``, ``/sandbox`` or ``/dev`` as path segments
    (segment-anchored so e.g. ``.../Developer`` is NOT excluded);
  * documentation subpages — titles ending in ``/doc``.

Usage:
    WIKI_BASE_URL=https://liquipedia.net python3 scripts/metrics/onwiki_loc.py [options]

Options:
    --wikis dota2,valorant   only these wikis (default: all dirs in lua/wikis)
    --delay 2.0              seconds between API requests (be nice to prod)
    --csv                    per-wiki summary CSV for time-series appending
    --csv-pages              per-page CSV (wiki, title, lines, loc) instead
    --pages / --no-pages     list on-wiki-only pages under each wiki in table
                             mode (default: --pages)
    --links                  count WhatLinksHere per on-wiki page — distinct
                             pages linking to or invoking the module, counting
                             only the main, Project and Portal namespaces.
                             One request per module; counts exact up to 500
                             per link type, capped above
    --links-exact            exact counts via batched queries with full
                             pagination (implies --links; request count scales
                             with total links, not module count)

This is read-only and uses the public API; no login needed. Set a descriptive
User-Agent below per API etiquette. If you'd rather not crawl the API, the
same numbers can come from a maintenance query against the page/text tables —
this script is the portable version.
"""

import argparse
import csv
import gzip
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from datetime import date
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
WIKIS_DIR = REPO_ROOT / 'lua' / 'wikis'
MODULE_NS = 828  # Scribunto Module namespace

USER_AGENT = 'LiquipediaMetrics/1.0 (standardization+phoenix tracking; engineering)'

# Segment-anchored exclusions, case-insensitive: Archive, sandbox, dev as a
# full path segment (covers /dev/XXX too). ':' counts as a boundary so
# top-level pages like Module:Archive/X and Module:Sandbox/X are excluded,
# while e.g. Module:Developer is not.
# Documentation subpages (Module:X/doc) are also excluded.
EXCLUDE_RE = re.compile(
    r'(^|[/:])(archive|sandbox|dev)(/|$)|/doc$',
    re.IGNORECASE,
)

PAGE_HEADER_RE = re.compile(r'^--\s*page\s*=\s*(Module:.+?)\s*$', re.MULTILINE)


def deployed_titles(wiki: str) -> dict[str, Path]:
    """Map deployed page title -> repo file, from this wiki's repo dir only.

    Commons gets no special treatment: a Module page existing on e.g.
    valorant whose title only matches a commons repo file is an on-wiki
    copy/override and counts as on-wiki code.
    """
    titles: dict[str, Path] = {}
    source_dir = WIKIS_DIR / wiki
    if source_dir.is_dir():
        for lua_file in source_dir.rglob('*.lua'):
            head = lua_file.read_text(encoding='utf-8', errors='replace')[:500]
            match = PAGE_HEADER_RE.search(head)
            if match:
                titles[match.group(1)] = lua_file
    return titles


def api_query(base_url: str, wiki: str, params: dict) -> dict:
    query = {
        'format': 'json',
        'formatversion': '2',
        **params,
    }
    url = f'{base_url}/{wiki}/api.php?{urllib.parse.urlencode(query)}'
    request = urllib.request.Request(url, headers={
        'User-Agent': USER_AGENT,
        'Accept-Encoding': 'gzip',  # required by liquipedia.net/api-terms-of-use
    })
    with urllib.request.urlopen(request, timeout=60) as response:
        body = response.read()
        if response.headers.get('Content-Encoding') == 'gzip':
            body = gzip.decompress(body)
        return json.loads(body)


def fetch_modules(base_url: str, wiki: str, delay: float):
    """Yield (title, content) for every Module-namespace page on the wiki."""
    cont: dict = {}
    while True:
        data = api_query(base_url, wiki, {
            'action': 'query',
            'generator': 'allpages',
            'gapnamespace': str(MODULE_NS),
            'gaplimit': '50',
            'prop': 'revisions',
            'rvprop': 'content',
            'rvslots': 'main',
            **cont,
        })
        for page in data.get('query', {}).get('pages', []):
            revisions = page.get('revisions')
            if not revisions:
                continue
            content = revisions[0].get('slots', {}).get('main', {}).get('content', '')
            yield page['title'], content
        cont = data.get('continue')
        if not cont:
            return
        time.sleep(delay)


def resolve_link_namespaces(base_url: str, wiki: str) -> list[int]:
    """Namespace ids that count as real usage: main, Project, Portal."""
    data = api_query(base_url, wiki, {
        'action': 'query',
        'meta': 'siteinfo',
        'siprop': 'namespaces',
    })
    wanted = []
    for ns in data['query']['namespaces'].values():
        canonical = ns.get('canonical', '')
        if ns['id'] == 0 or canonical in ('Liquipedia', 'Project', 'Portal') or ns.get('name') in ('Liquipedia', 'Project', 'Portal'):
            wanted.append(ns['id'])
    return wanted


def count_what_links_here(base_url: str, wiki: str, titles: list[str], ns_ids: list[int],
                          delay: float, exhaustive: bool) -> dict[str, int]:
    """WhatLinksHere counts per title, restricted to the given namespaces:
    distinct pages linking to or transcluding/#invoke-ing each title.

    Default mode: one request per title (list=embeddedin|backlinks combined),
    counts exact up to 500 per link type, capped above that. Per-title queries
    are required for a trustworthy cap: batched prop queries share one result
    limit sequentially across the batch, so one heavy module starves the rest.

    Exhaustive mode (--links-exact): batched prop=linkshere|transcludedin,
    50 titles per request, continuation followed to the end. Exact counts;
    request count scales with total links rather than title count, so this is
    often FASTER than default on lightly-linked wikis but unbounded on
    heavily-used modules.
    """
    ns_filter = '|'.join(str(ns) for ns in ns_ids)
    linking_pages: dict[str, set[int]] = {title: set() for title in titles}

    if not exhaustive:
        for title in titles:
            data = api_query(base_url, wiki, {
                'action': 'query',
                'list': 'embeddedin|backlinks',
                'eititle': title,
                'bltitle': title,
                'einamespace': ns_filter,
                'blnamespace': ns_filter,
                'eilimit': '500',
                'bllimit': '500',
            })
            for list_module in ('embeddedin', 'backlinks'):
                for entry in data.get('query', {}).get(list_module, []):
                    linking_pages[title].add(entry['pageid'])
            time.sleep(delay)
        return {title: len(pages) for title, pages in linking_pages.items()}

    for start in range(0, len(titles), 50):
        chunk = titles[start:start + 50]
        cont: dict = {}
        while True:
            data = api_query(base_url, wiki, {
                'action': 'query',
                'titles': '|'.join(chunk),
                'prop': 'linkshere|transcludedin',
                'lhprop': 'pageid',
                'tiprop': 'pageid',
                'lhnamespace': ns_filter,
                'tinamespace': ns_filter,
                'lhlimit': '500',
                'tilimit': '500',
                **cont,
            })
            for page in data.get('query', {}).get('pages', []):
                links = linking_pages.get(page.get('title'))
                if links is None:
                    continue
                for entry in page.get('linkshere', []) + page.get('transcludedin', []):
                    links.add(entry['pageid'])
            cont = data.get('continue')
            if not cont:
                break
            time.sleep(delay)
        time.sleep(delay)
    return {title: len(pages) for title, pages in linking_pages.items()}


def count_loc(content: str) -> tuple[int, int]:
    lines = content.splitlines()
    loc = sum(
        1 for line in lines
        if line.strip() and not line.strip().startswith('--')
    )
    return len(lines), loc


def analyze_wiki(base_url: str, wiki: str, delay: float, check_links: bool,
                 links_exact: bool) -> tuple[dict, list]:
    """Return (summary stats, list of on-wiki-only pages).

    Pages are (title, lines, loc) tuples, plus a WhatLinksHere count
    (main/Project/Portal namespaces only) when check_links is set.
    """
    deployed = deployed_titles(wiki)
    stats = {
        'date': date.today().isoformat(),
        'wiki': wiki,
        'onwiki_pages': 0,
        'onwiki_lines': 0,
        'onwiki_loc': 0,
        'excluded_pages': 0,
    }
    pages: list[tuple[str, int, int]] = []
    for title, content in fetch_modules(base_url, wiki, delay):
        if EXCLUDE_RE.search(title):
            stats['excluded_pages'] += 1
            continue
        if title in deployed:
            continue
        lines, loc = count_loc(content)
        stats['onwiki_pages'] += 1
        stats['onwiki_lines'] += lines
        stats['onwiki_loc'] += loc
        pages.append((title, lines, loc))
    pages.sort(key=lambda page: page[2], reverse=True)
    if check_links:
        ns_ids = resolve_link_namespaces(base_url, wiki)
        link_counts = count_what_links_here(
            base_url, wiki, [title for title, _, _ in pages], ns_ids, delay, links_exact)
        pages = [
            (title, lines, loc, link_counts[title])
            for title, lines, loc in pages
        ]
    return stats, pages


def main() -> None:
    import os
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base-url', default=os.getenv('WIKI_BASE_URL', 'https://liquipedia.net'))
    parser.add_argument('--wikis', help='comma-separated wiki list (default: all dirs in lua/wikis)')
    parser.add_argument('--delay', type=float, default=2.0)
    parser.add_argument('--csv', action='store_true', help='per-wiki summary CSV')
    parser.add_argument('--csv-pages', action='store_true', help='per-page CSV instead of summary')
    parser.add_argument('--pages', action=argparse.BooleanOptionalAction, default=True,
                        help='list the on-wiki-only pages under each wiki in table mode')
    parser.add_argument('--links', action='store_true',
                        help='count WhatLinksHere per on-wiki page (main/Project/Portal '
                             'namespaces only; extra API requests per page; counts cap '
                             'at 500 per link type)')
    parser.add_argument('--links-exact', action='store_true',
                        help='follow pagination for exact WhatLinksHere counts '
                             '(slower; implies --links)')
    args = parser.parse_args()
    if args.links_exact:
        args.links = True

    if args.wikis:
        wikis = [w.strip() for w in args.wikis.split(',') if w.strip()]
    else:
        wikis = sorted(
            d.name for d in WIKIS_DIR.iterdir()
            if d.is_dir() and d.name != 'commons'
        )

    fieldnames = [
        'date', 'wiki', 'onwiki_pages', 'onwiki_lines', 'onwiki_loc',
        'excluded_pages',
    ]
    writer = None
    if args.csv_pages:
        writer = csv.writer(sys.stdout)
        writer.writerow(['date', 'wiki', 'title', 'lines', 'loc'] + (['links'] if args.links else []))
    elif args.csv:
        writer = csv.DictWriter(sys.stdout, fieldnames=fieldnames)
        writer.writeheader()
    else:
        print(f"{'wiki':<20} {'pages':>6} {'lines':>9} {'loc':>9}")

    totals = dict.fromkeys(fieldnames[2:], 0)
    for wiki in wikis:
        try:
            stats, pages = analyze_wiki(args.base_url, wiki, args.delay, args.links, args.links_exact)
        except Exception as error:  # keep going; one broken wiki shouldn't kill the run
            print(f'ERROR {wiki}: {error}', file=sys.stderr)
            continue
        for key in totals:
            totals[key] += stats[key]
        if args.csv_pages:
            for page in pages:
                writer.writerow([stats['date'], wiki, *page])
            sys.stdout.flush()
        elif args.csv:
            writer.writerow(stats)
            sys.stdout.flush()
        else:
            print(
                f"{stats['wiki']:<20} {stats['onwiki_pages']:>6} {stats['onwiki_lines']:>9} "
                f"{stats['onwiki_loc']:>9}"
            )
            if args.pages:
                for page in pages:
                    title, lines, loc = page[:3]
                    suffix = f', {page[3]} usages' if args.links else ''
                    print(f'    {title}  ({loc} loc{suffix})')
        time.sleep(args.delay)

    if not args.csv and not args.csv_pages:
        print('-' * 47)
        print(
            f"{'TOTAL':<20} {totals['onwiki_pages']:>6} {totals['onwiki_lines']:>9} "
            f"{totals['onwiki_loc']:>9}"
        )


if __name__ == '__main__':
    main()
