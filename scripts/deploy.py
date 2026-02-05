import itertools
import os
import pathlib
import re
import sys

from typing import Iterable

import requests

from deploy_util import (
    get_git_deploy_reason,
    deploy_file_to_wiki,
    read_cookie_jar,
    read_file_from_path,
    write_to_github_summary_file,
)
from login_and_get_token import get_token

HEADER_PATTERN = re.compile(
    r"\A---\n" r"-- @Liquipedia\n" r"-- page=(?P<pageName>[^\n]*)\n"
)


def deploy_all_files_for_wiki(
    wiki: str, file_paths: Iterable[pathlib.Path], deploy_reason: str
) -> bool:
    all_modules_deployed = True
    token = get_token(wiki)
    with requests.Session() as session:
        session.cookies = read_cookie_jar(wiki)
        for file_path in file_paths:
            print(f"::group::Checking {str(file_path)}")
            file_content = read_file_from_path(file_path)
            header_match = HEADER_PATTERN.match(file_content)
            if not header_match:
                print("...skipping - no magic comment found")
                write_to_github_summary_file(f"{str(file_path)} skipped")
            else:
                page = header_match.groupdict()["pageName"] + (
                    os.getenv("LUA_DEV_ENV_NAME") or ""
                )
                module_deployed, _ = deploy_file_to_wiki(
                    session, file_path, file_content, wiki, page, token, deploy_reason
                )
                all_modules_deployed = all_modules_deployed and module_deployed
            print("::endgroup::")
    return all_modules_deployed


def main():
    all_modules_deployed = True
    lua_files: Iterable[pathlib.Path]
    git_deploy_reason: str
    if len(sys.argv[1:]) == 0:
        lua_files = pathlib.Path("./lua/wikis/").rglob("*.lua")
        git_deploy_reason = "Automated Weekly Re-Sync"
    else:
        lua_files = [pathlib.Path(arg) for arg in sys.argv[1:]]
        git_deploy_reason = get_git_deploy_reason()

    for wiki, files in itertools.groupby(sorted(lua_files), lambda path: path.parts[2]):
        all_modules_deployed = deploy_all_files_for_wiki(
            wiki, list(files), git_deploy_reason
        )

    if not all_modules_deployed:
        print("::warning::Some modules were not deployed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
