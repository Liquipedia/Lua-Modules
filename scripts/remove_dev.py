import os
import time

import requests

from deploy_util import (
    HEADER,
    SLEEP_DURATION,
    get_wiki_api_url,
    get_wikis,
    read_cookie_jar,
    write_to_github_summary_file,
)
from login_and_get_token import get_token, login

LUA_DEV_ENV_NAME = os.getenv("LUA_DEV_ENV_NAME")

remove_errors: list[str] = list()


def remove_page(session: requests.Session, page: str, wiki: str):
    print(f"deleting {wiki}:{page}")
    token = get_token(wiki)

    result = session.post(
        get_wiki_api_url(wiki),
        headers=HEADER,
        params={
            "format": "json",
            "action": "delete",
        },
        data={
            "title": page,
            "reason": f"Remove {LUA_DEV_ENV_NAME}",
            "token": token,
        },
    ).json()
    time.sleep(SLEEP_DURATION)

    if "delete" not in result.keys():
        print(f"::warning::could not delete {page} on {wiki}")
        write_to_github_summary_file(f":warning: could not delete {page} on {wiki}")
        remove_errors.append(f"{wiki}:{page}")


def search_and_remove(wiki: str):
    with requests.Session() as session:
        search_result = session.post(
            get_wiki_api_url(wiki),
            headers=HEADER,
            params={"format": "json", "action": "query"},
            data={
                "list": "search",
                "srsearch": f"intitle:{LUA_DEV_ENV_NAME}",
                "srnamespace": 828,
                "srlimit": 5000,
                "srprop": "",
            },
        ).json()
        time.sleep(SLEEP_DURATION)

        # Handle API error responses and missing or empty search results safely.
        if "error" in search_result:
            error_info = search_result.get("error")
            print(f"::warning::search API error on {wiki}: {error_info}")
            write_to_github_summary_file(
                f":warning: search API error on {wiki}: {error_info}"
            )
            return

        pages = search_result.get("query", {}).get("search") or []
        if len(pages) == 0:
            return

        login(wiki)
        session.cookies = read_cookie_jar(wiki)

        for page in pages:
            if os.getenv("INCLUDE_SUB_ENVS") == "true" or page["title"].endswith(
                LUA_DEV_ENV_NAME
            ):
                remove_page(session, page["title"], wiki)


def main():
    for wiki in get_wikis():
        if wiki == "commons" and os.getenv("INCLUDE_COMMONS") != "true":
            continue
        search_and_remove(wiki)
    if len(remove_errors) == 0:
        exit(0)
    print("::warning::Could not delete some pages on some wikis")
    write_to_github_summary_file("::warning::Could not delete some pages on some wikis")
    print("::group::Failed protections")
    for remove_error in remove_errors:
        print(remove_error)
    print("endgroup")
    exit(1)


if __name__ == "__main__":
    main()
