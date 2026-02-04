import os
import pathlib
import sys

from typing import Iterable

from deploy_util import get_wikis
from protect_page import *

WIKI_TO_PROTECT = os.getenv("WIKI_TO_PROTECT")


def check_for_local_version(module: str, wiki: str):
    if wiki == "commons":
        return False
    return pathlib.Path(f"./lua/wikis/{wiki}/{module}.lua").exists()


def protect_if_has_no_local_version(module: str, wiki: str):
    page = "Module:" + module
    if check_for_local_version(module, wiki):
        protect_non_existing_page(page, wiki)


def main():
    lua_files: Iterable[pathlib.Path]
    if len(sys.argv[1:]) > 0:
        lua_files = [pathlib.Path(arg) for arg in sys.argv[1:]]
    elif WIKI_TO_PROTECT:
        lua_files = pathlib.Path("./").glob("lua/wikis/**/*.lua")
    else:
        print("Nothing to protect")
        exit(0)

    for file_to_protect in lua_files:
        print(f"::group::Checking { str(file_to_protect) }")
        wiki = file_to_protect.parts[2]
        module = "/".join(file_to_protect.parts[3:])[:-4]
        page = "Module:" + module
        if WIKI_TO_PROTECT:
            if wiki == WIKI_TO_PROTECT:
                protect_existing_page(page, wiki)
            elif wiki == "commons":
                protect_if_has_no_local_version(module, WIKI_TO_PROTECT)
        elif wiki != "commons":
            protect_existing_page(page, wiki)
        else:  # commons case
            protect_existing_page(page, wiki)
            for deploy_wiki in get_wikis():
                protect_if_has_no_local_version(module, deploy_wiki)
        print("::endgroup::")
    handle_protect_errors()


if __name__ == "__main__":
    main()
