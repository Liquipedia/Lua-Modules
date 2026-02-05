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
    "get_git_deploy_reason",
    "get_wiki_api_url",
    "get_wikis",
    "read_cookie_jar",
    "read_file_from_path",
    "write_to_github_summary_file",
]

DEPLOY_TRIGGER = os.getenv("DEPLOY_TRIGGER")
GITHUB_STEP_SUMMARY_FILE = os.getenv("GITHUB_STEP_SUMMARY")
USER_AGENT = f"GitHub Autodeploy Bot/2.0.0 ({ os.getenv("WIKI_UA_EMAIL") })"
WIKI_BASE_URL = os.getenv("WIKI_BASE_URL")
HEADER = {
    "User-Agent": USER_AGENT,
    "accept": "application/json",
    "Accept-Encoding": "gzip",
}


def get_wikis() -> set[str]:
    response = requests.get(
        "https://liquipedia.net/api.php",
        headers=HEADER,
    )
    wikis = response.json()
    time.sleep(4)
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
