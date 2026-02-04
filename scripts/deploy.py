import http.cookiejar
import itertools
import os
import pathlib
import re
import sys
import subprocess
import time

from typing import Iterable

import requests

from login_and_get_token import *

DEPLOY_TRIGGER = os.getenv("DEPLOY_TRIGGER")
HEADER_PATTERN = re.compile(
    r"\A---\n" r"-- @Liquipedia\n" r"-- page=(?P<pageName>[^\n]*)\n"
)
GITHUB_STEP_SUMMARY_FILE = os.getenv("GITHUB_STEP_SUMMARY")


all_modules_deployed: bool = True


def write_to_github_summary_file(text: str):
    if not GITHUB_STEP_SUMMARY_FILE:
        return
    with open(GITHUB_STEP_SUMMARY_FILE, "a") as summary:
        summary.write(f"{text}\n")


def read_file_from_path(file_path: pathlib.Path) -> str:
    with file_path.open("r") as file:
        return file.read()


def deploy_all_files_for_wiki(
    wiki: str, file_paths: Iterable[pathlib.Path], deploy_reason: str
):
    token = get_token(wiki)
    ckf = f"cookie_{wiki}.ck"
    cookie_jar = http.cookiejar.LWPCookieJar(filename=ckf)
    try:
        cookie_jar.load(ignore_discard=True)
    except:
        pass
    with requests.Session() as session:
        session.cookies = cookie_jar
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
                    f"{WIKI_BASE_URL}/{wiki}/api.php",
                    headers={
                        "User-Agent": USER_AGENT,
                        "accept": "application/json",
                        "Accept-Encoding": "gzip",
                    },
                    params={"format": "json", "action": "edit"},
                    data={
                        "title": page,
                        "text": file_content,
                        "summary": f"Git: {deploy_reason.strip()}",
                        "bot": "true",
                        "recreate": "true",
                        "token": token,
                    },
                ).json()
                result = response["edit"]["result"]
                if result == "Success":
                    no_change = response["edit"]["nochange"]
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


def main():
    lua_files: Iterable[pathlib.Path]
    git_deploy_reason: str
    if len(sys.argv[1:]) == 0:
        lua_files = pathlib.Path("./").glob("lua/wikis/**/*.lua")
        git_deploy_reason = "Automated Weekly Re-Sync"
    else:
        lua_files = [pathlib.Path(arg) for arg in sys.argv[1:]]
        git_deploy_reason = subprocess.check_output(
            ["git", "log", "-1", "--pretty='%h %s'"]
        ).decode()

    for wiki, files in itertools.groupby(lua_files, lambda path: path.parts[2]):
        deploy_all_files_for_wiki(wiki, list(files), git_deploy_reason)

    if not all_modules_deployed:
        print("::warning::Some modules were not deployed!")
        sys.exit(1)


main()
