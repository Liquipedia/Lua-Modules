import functools
import os
import time

import requests

from deploy_util import HEADER, get_wiki_api_url, read_cookie_jar

__all__ = ["get_token"]

WIKI_USER = os.getenv("WIKI_USER")
WIKI_PASSWORD = os.getenv("WIKI_PASSWORD")

loggedin: set[str] = set()


def login(wiki: str):
    if wiki in loggedin:
        return
    cookie_jar = read_cookie_jar(wiki)
    print(f"...logging in on { wiki }")
    with requests.Session() as session:
        session.cookies = cookie_jar
        token_response = session.post(
            get_wiki_api_url(wiki),
            headers=HEADER,
            params={
                "format": "json",
                "action": "query",
                "meta": "tokens",
                "type": "login",
            },
        ).json()
        session.post(
            get_wiki_api_url(wiki),
            headers=HEADER,
            data={
                "lgname": WIKI_USER,
                "lgpassword": WIKI_PASSWORD,
                "lgtoken": token_response["query"]["tokens"]["logintoken"],
            },
            params={"format": "json", "action": "login"},
        )
        loggedin.add(wiki)
        cookie_jar.save(ignore_discard=True)
        time.sleep(4)


@functools.cache
def get_token(wiki: str) -> str:
    login(wiki)

    with requests.Session() as session:
        session.cookies = read_cookie_jar(wiki)
        token_response = session.post(
            get_wiki_api_url(wiki),
            headers=HEADER,
            params={
                "format": "json",
                "action": "query",
                "meta": "tokens",
            },
        ).json()
        return token_response["query"]["tokens"]["csrftoken"]
