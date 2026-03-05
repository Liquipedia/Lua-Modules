import functools
import os
import pathlib
import subprocess
import time

import requests

__all__ = [
    "HEADER",
    "SLEEP_DURATION",
    "get_git_deploy_reason",
    "get_wikis",
    "read_file_from_path",
    "write_to_github_summary_file",
]

GITHUB_STEP_SUMMARY_FILE = os.getenv("GITHUB_STEP_SUMMARY")
USER_AGENT = f"GitHub Autodeploy Bot/2.0.0 ({os.getenv('WIKI_UA_EMAIL')})"

HEADER = {
    "User-Agent": USER_AGENT,
    "accept": "application/json",
    "Accept-Encoding": "gzip",
}
SLEEP_DURATION = 4


@functools.cache
def get_wikis() -> frozenset[str]:
    response = requests.get(
        "https://liquipedia.net/api.php",
        headers=HEADER,
    )
    wikis = response.json()
    time.sleep(SLEEP_DURATION)
    return frozenset(wikis["allwikis"].keys())


def get_git_deploy_reason():
    return (
        subprocess.check_output(["git", "log", "-1", "--pretty='%h %s'"])
        .decode()
        .strip()
    )


def read_file_from_path(file_path: pathlib.Path) -> str:
    with file_path.open("r") as file:
        return file.read()


def write_to_github_summary_file(text: str):
    if not GITHUB_STEP_SUMMARY_FILE:
        return
    with open(GITHUB_STEP_SUMMARY_FILE, "a") as summary:
        summary.write(f"{text}\n")
