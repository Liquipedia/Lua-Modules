import asyncio
import itertools
import os
import pathlib
import re
import sys
import subprocess

from typing import Iterable

import aiohttp

from login_and_get_token import *

DEPLOY_TRIGGER = os.getenv("DEPLOY_TRIGGER")
HEADER_PATTERN = re.compile(
    r"\A---\n" r"-- @Liquipedia\n" r"-- page=(?P<pageName>[^\n]*)\n"
)
GITHUB_STEP_SUMMARY_FILE = os.getenv("GITHUB_STEP_SUMMARY")

all_modules_deployed: bool = True
gh_summary_write_lock = asyncio.Lock()


async def write_to_github_summary_file(text: str):
    if not GITHUB_STEP_SUMMARY_FILE:
        return
    await gh_summary_write_lock.acquire()
    try:
        with open(GITHUB_STEP_SUMMARY_FILE, "a") as summary:
            summary.write(f"{text}\n")
    finally:
        gh_summary_write_lock.release()


async def deploy_all_files_for_wiki(
    wiki: str, file_paths: Iterable[pathlib.Path], deploy_reason: str
):
    token = await get_token(wiki)
    ckf = f"cookie_{wiki}.ck"
    cookie_jar = aiohttp.CookieJar()
    if os.path.exists(ckf):
        cookie_jar.load(ckf)
    session = aiohttp.ClientSession(
        f"{WIKI_BASE_URL}/{wiki}/",
        headers={"User-Agent": USER_AGENT, "Accept-Encoding": "gzip"},
        cookie_jar=cookie_jar,
    )
    for file_path in file_paths:
        output: list[str] = [f"::group::Checking {str(file_path)}"]
        with file_path.open("r") as file:
            file_content = file.read()
            header_match = HEADER_PATTERN.match(file_content)
            if not header_match:
                output.append("...skipping - no magic comment found")
                await write_to_github_summary_file(f"{str(file_path)} skipped")
            else:
                page = header_match.groupdict()["pageName"] + (
                    os.getenv("LUA_DEV_ENV_NAME") or ""
                )
                response = await session.post(
                    "api.php",
                    params={"format": "json", "action": "edit"},
                    data={
                        "title": page,
                        "text": file_content,
                        "summary": f"Git: {deploy_reason.strip()}",
                        "bot": "true",
                        "recreate": "true",
                        "token": token,
                    },
                )
                parsed_response = await response.json()
                result = parsed_response["edit"]["result"]
                if result == "Success":
                    no_change = parsed_response["edit"]["nochange"]
                    if len(no_change) == 0 and DEPLOY_TRIGGER == "push":
                        output.append(f"::notice file={str(file_path)}::No change made")
                    elif len(no_change) != 0 and DEPLOY_TRIGGER != "push":
                        output.append(f"::warning file={str(file_path)}::File changed")
                    output.append("...done")
                    await write_to_github_summary_file(
                        f":information_source: {str(file_path)} successfully deployed"
                    )
                else:
                    all_modules_deployed = False
                    output.append(f"::warning file={str(file_path)}::failed to deploy")
                    await write_to_github_summary_file(
                        f":warning: {str(file_path)} failed to deploy"
                    )
                await asyncio.sleep(4)
            output.append("::endgroup::")
            print("\n".join(output))
    await session.close()


async def async_main():
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

    # # Asynchronous deploy is disabled due to rate limit
    # deploy_tasks: list[asyncio.Task] = list()
    # for wiki, files in itertools.groupby(lua_files, lambda path: path.parts[2]):
    #     deploy_tasks.append(
    #         asyncio.Task(
    #             deploy_all_files_for_wiki(wiki, list(files), git_deploy_reason)
    #         )
    #     )
    # await asyncio.wait(deploy_tasks)

    for wiki, files in itertools.groupby(lua_files, lambda path: path.parts[2]):
        await deploy_all_files_for_wiki(wiki, list(files), git_deploy_reason)

    if not all_modules_deployed:
        print("::warning::Some modules were not deployed!")
        sys.exit(1)


asyncio.run(async_main())
