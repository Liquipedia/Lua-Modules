import itertools
import os
import pathlib
import sys

from deploy_util import get_wikis
from mediawiki_session import MediaWikiSession
from protect_page import (
    protect_non_existing_pages,
    protect_existing_pages,
    handle_protect_errors,
)

WIKI_TO_PROTECT = os.getenv("WIKI_TO_PROTECT")


def protect_new_wiki(wiki_to_protect: str):
    lua_files = itertools.chain(
        pathlib.Path("./lua/wikis/commons/").rglob("*.lua"),
        pathlib.Path("./lua/wikis/" + wiki_to_protect + "/").rglob("*.lua"),
    )

    commons_modules: set[str] = set()
    local_modules: set[str] = set()

    for file_to_protect in sorted(lua_files):
        wiki = file_to_protect.parts[2]
        module = "/".join(file_to_protect.parts[3:])[:-4]
        page = "Module:" + module

        if wiki == wiki_to_protect:
            local_modules.add(page)
        elif wiki == "commons":
            commons_modules.add(page)

    with MediaWikiSession(wiki_to_protect) as session:
        protect_non_existing_pages(session, commons_modules - local_modules)
        protect_existing_pages(session, local_modules)

    handle_protect_errors()


def main():
    if WIKI_TO_PROTECT:
        protect_new_wiki(WIKI_TO_PROTECT)
        return
    elif len(sys.argv[1:]) == 0:
        print("Nothing to protect")
        exit(0)

    lua_files = [pathlib.Path(arg) for arg in sys.argv[1:]]

    files_to_protect_by_wiki: dict[str, set[str]] = dict()

    for wiki, files_to_protect in itertools.groupby(
        sorted(lua_files), lambda path: path.parts[2]
    ):
        files_to_protect_by_wiki[wiki] = set(
            [
                "Module:" + "/".join(file_to_protect.parts[3:])[:-4]
                for file_to_protect in files_to_protect
            ]
        )

    new_commons_modules = files_to_protect_by_wiki.get("commons")

    if new_commons_modules:
        for wiki in get_wikis():
            with MediaWikiSession(wiki) as session:
                if wiki == "commons":
                    protect_existing_pages(session, new_commons_modules)
                else:
                    new_local_modules = files_to_protect_by_wiki.get(wiki)
                    if new_local_modules:
                        protect_existing_pages(session, new_local_modules)
                        protect_non_existing_pages(
                            session, new_commons_modules - new_local_modules
                        )
                    else:
                        protect_non_existing_pages(session, new_commons_modules)
    else:
        for wiki, new_modules in files_to_protect_by_wiki:
            with MediaWikiSession(wiki) as session:
                protect_existing_pages(session, new_modules)

    handle_protect_errors()


if __name__ == "__main__":
    main()
