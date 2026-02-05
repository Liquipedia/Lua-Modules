import time

from typing import Literal

import requests

from deploy_util import (
    HEADER,
    get_wiki_api_url,
    read_cookie_jar,
    write_to_github_summary_file,
)
from login_and_get_token import get_token

__all__ = [
    "protect_non_existing_page",
    "protect_existing_page",
    "handle_protect_errors",
]

protect_errors = list()


def protect_page(page: str, wiki: str, protect_mode: Literal["edit", "create"]):
    protect_options: str
    if protect_mode == "edit":
        protect_options = "edit=allow-only-sysop|move=allow-only-sysop"
    elif protect_mode == "create":
        protect_options = "create=allow-only-sysop"
    else:
        raise ValueError(f"invalid protect mode: {protect_mode}")
    print(f"...wiki = { wiki }")
    print(f"...page = { page }")
    token = get_token(wiki)
    with requests.Session() as session:
        session.cookies = read_cookie_jar(wiki)
        response = session.post(
            get_wiki_api_url(wiki),
            headers=HEADER,
            params={"format": "json", "action": "protect"},
            data={
                "title": page,
                "protections": protect_options,
                "reason": "Git maintained",
                "expiry": "infinite",
                "bot": "true",
                "token": token,
            },
        ).json()

        time.sleep(4)
        protections = response["protect"]["protections"]
        for protection in protections:
            if protection[protect_mode] == "allow-only-sysop":
                return
        print(f"::warning::could not ({protect_mode}) protect {page} on {wiki}")
        protect_errors.append(f"{protect_mode}:{wiki}:{page}")


def check_if_page_exists(page: str, wiki: str) -> bool:
    with requests.Session() as session:
        session.cookies = read_cookie_jar(wiki)

        result = session.post(
            get_wiki_api_url(wiki),
            headers=HEADER,
            params={"format": "json", "action": "query"},
            data={"titles": page, "prop": "info"},
        ).text

        time.sleep(4)
        return 'missing":"' in result


def protect_non_existing_page(page: str, wiki: str):
    if check_if_page_exists(page, wiki):
        print(f"::warning::{page} already exists on {wiki}")
        protect_errors.append(f"create:{wiki}:{page}")
    else:
        protect_page(page, wiki, "create")


def protect_existing_page(page: str, wiki: str):
    protect_page(page, wiki, "edit")


def handle_protect_errors():
    if len(protect_errors) == 0:
        return
    print("::warning::Some templates could not be protected")
    write_to_github_summary_file(":warning: Some templates could not be protected")
    print("::group::Failed protections")
    for protect_error in protect_errors:
        print(f"... {protect_error}")
    print("::endgroup::")
    exit(1)
