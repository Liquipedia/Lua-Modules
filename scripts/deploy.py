import itertools
import os
import pathlib
import re
import sys
import time

from typing import Iterable

import requests

from deploy_util import (
    DEPLOY_TRIGGER,
    HEADER,
    get_git_deploy_reason,
    get_wiki_api_url,
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
                response = session.post(
                    get_wiki_api_url(wiki),
                    headers=HEADER,
                    params={"format": "json", "action": "edit"},
                    data={
                        "title": page,
                        "text": file_content,
                        "summary": f"Git: {deploy_reason}",
                        "bot": "true",
                        "recreate": "true",
                        "token": token,
                    },
                ).json()
                result = response["edit"].get("result")
                if result == "Success":
                    no_change = response["edit"].get("nochange")
                    if len(no_change) == 0 and DEPLOY_TRIGGER == "push":
                        print(f"::notice file={str(file_path)}::No change made")
                    elif len(no_change) != 0 and DEPLOY_TRIGGER != "push":
                        print(f"::warning file={str(file_path)}::File changed")
                    print("...done")
                    write_to_github_summary_file(
                        f":information_source: {str(file_path)} successfully deployed"
                    )
                else:
                    all_modules_deployed = False
                    print(f"::warning file={str(file_path)}::failed to deploy")
                    write_to_github_summary_file(
                        f":warning: {str(file_path)} failed to deploy"
                    )
                time.sleep(4)
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

    for wiki, files in itertools.groupby(lua_files, lambda path: path.parts[2]):
        all_modules_deployed = deploy_all_files_for_wiki(
            wiki, list(files), git_deploy_reason
        )

    if not all_modules_deployed:
        print("::warning::Some modules were not deployed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
