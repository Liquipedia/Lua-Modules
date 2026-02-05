import functools
import http.cookiejar
import os
import pathlib
import subprocess
import time

import requests

__all__ = [
    "DEPLOY_TRIGGER",
    "HEADER",
    "SLEEP_DURATION",
    "deploy_file_to_wiki",
    "get_git_deploy_reason",
    "get_wiki_api_url",
    "get_wikis",
    "read_cookie_jar",
    "read_file_from_path",
    "write_to_github_summary_file",
]

DEPLOY_TRIGGER = os.getenv("DEPLOY_TRIGGER")
GITHUB_STEP_SUMMARY_FILE = os.getenv("GITHUB_STEP_SUMMARY")
USER_AGENT = f"GitHub Autodeploy Bot/2.0.0 ({os.getenv('WIKI_UA_EMAIL')})"
WIKI_BASE_URL = os.getenv("WIKI_BASE_URL")
HEADER = {
    "User-Agent": USER_AGENT,
    "accept": "application/json",
    "Accept-Encoding": "gzip",
}
SLEEP_DURATION = 4


def get_wikis() -> set[str]:
    response = requests.get(
        "https://liquipedia.net/api.php",
        headers=HEADER,
    )
    wikis = response.json()
    time.sleep(SLEEP_DURATION)
    return set(wikis["allwikis"].keys())


@functools.cache
def get_wiki_api_url(wiki: str) -> str:
    return f"{WIKI_BASE_URL}/{wiki}/api.php"


def get_git_deploy_reason():
    return (
        subprocess.check_output(["git", "log", "-1", "--pretty='%h %s'"])
        .decode()
        .strip()
    )


def deploy_file_to_wiki(
    session: requests.Session,
    file_path: pathlib.Path,
    file_content: str,
    wiki: str,
    target_page: str,
    token: str,
    deploy_reason: str,
) -> tuple[bool, bool]:
    change_made = False
    deployed = True
    response = session.post(
        get_wiki_api_url(wiki),
        headers=HEADER,
        params={"format": "json", "action": "edit"},
        data={
            "title": target_page,
            "text": file_content,
            "summary": f"Git: {deploy_reason}",
            "bot": "true",
            "recreate": "true",
            "token": token,
        },
    ).json()
    result = response["edit"].get("result")
    new_rev_id = response["edit"].get("newrevid")
    if result == "Success":
        if new_rev_id is not None:
            change_made = True
            if DEPLOY_TRIGGER != "push":
                print(f"::warning file={str(file_path)}::File changed")
        print(f"...{result}")
        print("...done")
        write_to_github_summary_file(
            f":information_source: {str(file_path)} successfully deployed"
        )

    else:
        print(f"::warning file={str(file_path)}::failed to deploy")
        write_to_github_summary_file(f":warning: {str(file_path)} failed to deploy")
        deployed = False
    time.sleep(SLEEP_DURATION)
    return deployed, change_made


def read_cookie_jar(wiki: str) -> http.cookiejar.FileCookieJar:
    ckf = f"cookie_{wiki}.ck"
    cookie_jar = http.cookiejar.LWPCookieJar(filename=ckf)
    try:
        cookie_jar.load(ignore_discard=True)
    except OSError:
        pass
    return cookie_jar


def read_file_from_path(file_path: pathlib.Path) -> str:
    with file_path.open("r") as file:
        return file.read()


def write_to_github_summary_file(text: str):
    if not GITHUB_STEP_SUMMARY_FILE:
        return
    with open(GITHUB_STEP_SUMMARY_FILE, "a") as summary:
        summary.write(f"{text}\n")
