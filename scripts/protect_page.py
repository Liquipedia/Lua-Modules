import time

from typing import Iterable, Literal

import requests

from deploy_util import (
    HEADER,
    SLEEP_DURATION,
    get_wiki_api_url,
    read_cookie_jar,
    write_to_github_summary_file,
)
from login_and_get_token import get_token
from mediawiki_session import MediaWikiSession, MediaWikiSessionError

__all__ = [
    "protect_non_existing_page",
    "protect_non_existing_pages",
    "protect_existing_page",
    "protect_existing_pages",
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
    print(f"...wiki = {wiki}")
    print(f"...page = {page}")
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

        time.sleep(SLEEP_DURATION)
        if response.get("error"):
            print(
                f"::warning::could not ({protect_mode}) protect {page} on {wiki}: {response['error']['info']}"
            )
            protect_errors.append(f"{protect_mode}:{wiki}:{page}")
            return
        protections = response["protect"].get("protections")
        for protection in protections:
            if protection[protect_mode] == "allow-only-sysop":
                return
        print(f"::warning::could not ({protect_mode}) protect {page} on {wiki}")
        protect_errors.append(f"{protect_mode}:{wiki}:{page}")


def protect_pages(
    session: MediaWikiSession,
    pages: Iterable[str],
    protect_mode: Literal["edit", "create"],
):
    protect_options: str
    if protect_mode == "edit":
        protect_options = "edit=allow-only-sysop|move=allow-only-sysop"
    elif protect_mode == "create":
        protect_options = "create=allow-only-sysop"
    else:
        raise ValueError(f"invalid protect mode: {protect_mode}")
    print(f"...wiki = {session.wiki}")
    for page in pages:
        print(f"...page = {page}")
        try:
            protections = session.make_action(
                "protect",
                data={
                    "title": page,
                    "protections": protect_options,
                    "reason": "Git maintained",
                    "expiry": "infinite",
                    "bot": "true",
                    "token": session.token,
                },
            )
            for protection in protections:
                if protection[protect_mode] == "allow-only-sysop":
                    return
            print(
                f"::warning::could not ({protect_mode}) protect {page} on {session.wiki}"
            )
            protect_errors.append(f"{protect_mode}:{session.wiki}:{page}")
        except MediaWikiSessionError as e:
            print(
                f"::warning::could not ({protect_mode}) protect {page} on {session.wiki}: {str(e)}"
            )
            protect_errors.append(f"{protect_mode}:{session.wiki}:{page}")
        finally:
            session.cooldown()


def check_if_page_exists(page: str, wiki: str) -> bool:
    with requests.Session() as session:
        session.cookies = read_cookie_jar(wiki)

        result = session.post(
            get_wiki_api_url(wiki),
            headers=HEADER,
            params={"format": "json", "action": "query"},
            data={"titles": page, "prop": "info"},
        ).json()

        time.sleep(SLEEP_DURATION)
        return "-1" not in result["query"]["pages"]


def protect_non_existing_page(page: str, wiki: str):
    if check_if_page_exists(page, wiki):
        print(f"::warning::{page} already exists on {wiki}")
        protect_errors.append(f"create:{wiki}:{page}")
    else:
        protect_page(page, wiki, "create")


def protect_non_existing_pages(session: MediaWikiSession, pages: Iterable[str]):
    def filter_non_existing_pages(page: str) -> bool:
        try:
            result = session.post(
                "query",
                data={"titles": page, "prop": "info"},
            )
            if "-1" in result["pages"]:
                return True
            print(f"::warning::{page} already exists on {session.wiki}")
            protect_errors.append(f"create:{session.wiki}:{page}")
            return False
        finally:
            time.sleep(SLEEP_DURATION)

    protect_pages(session, filter(filter_non_existing_pages, pages), "create")


def protect_existing_page(page: str, wiki: str):
    protect_page(page, wiki, "edit")


def protect_existing_pages(session: MediaWikiSession, pages: Iterable[str]):
    protect_pages(session, pages, "edit")


def handle_protect_errors():
    if len(protect_errors) == 0:
        return
    print("::warning::Some pages could not be protected")
    write_to_github_summary_file(":warning: Some pages could not be protected")
    print("::group::Failed protections")
    for protect_error in protect_errors:
        print(f"... {protect_error}")
    print("::endgroup::")
    exit(1)
