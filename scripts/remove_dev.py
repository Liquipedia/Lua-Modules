import os
import time

import requests

from deploy_util import (
    HEADER,
    SLEEP_DURATION,
    get_wiki_api_url,
    get_wikis,
    read_cookie_jar,
    write_to_github_summary_file,
)
from login_and_get_token import get_token, login

LUA_DEV_ENV_NAME = os.getenv("LUA_DEV_ENV_NAME")

remove_errors: list[str] = list()


def remove_page(session: requests.Session, page: str, wiki: str):
    print(f"deleting {wiki}:{page}")
    token = get_token(wiki)

    result = session.post(
        get_wiki_api_url(wiki),
        headers=HEADER,
        params={
            "format": "json",
            "action": "delete",
        },
        data={
            "title": page,
            "reason": f"Remove {LUA_DEV_ENV_NAME}",
            "token": token,
        },
    ).json()
    time.sleep(SLEEP_DURATION)

    if "delete" not in result.keys():
        print(f"::warning::could not delete {page} on {wiki}")
        write_to_github_summary_file(f":warning: could not delete {page} on {wiki}")
        remove_errors.append(f"{wiki}:{page}")


def search_and_remove(wiki: str):
    with requests.Session() as session:
        search_result = session.post(
            get_wiki_api_url(wiki),
            headers=HEADER,
            params={"format": "json", "action": "query"},
            data={
                "list": "search",
                "srsearch": f"intitle:{LUA_DEV_ENV_NAME}",
                "srnamespace": 828,
                "srlimit": 5000,
                "srprop": "",
            },
        ).json()
        time.sleep(SLEEP_DURATION)
        pages = search_result["query"].get("search")

        if len(pages) == 0:
            return

        login(wiki)
        session.cookies = read_cookie_jar(wiki)

        for page in pages:
            if os.getenv("INCLUDE_SUB_ENVS") == "true" or page["title"].endswith(
                LUA_DEV_ENV_NAME
            ):
                remove_page(session, page["title"], wiki)


def main():
    for wiki in get_wikis():
        if wiki == "commons" and os.getenv("INCLUDE_COMMONS") == "true":
            continue
        search_and_remove(wiki)


if __name__ == "__main__":
    main()
