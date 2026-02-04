import http.cookiejar
import os
import time

import requests

__all__ = ["USER_AGENT", "WIKI_BASE_URL", "get_token"]

USER_AGENT = f"GitHub Autodeploy Bot/1.1.0 ({ os.getenv("WIKI_UA_EMAIL") })"
WIKI_BASE_URL = os.getenv("WIKI_BASE_URL")
WIKI_USER = os.getenv("WIKI_USER")
WIKI_PASSWORD = os.getenv("WIKI_PASSWORD")

loggedin: set[str] = set()


def login(wiki: str):
    if wiki in loggedin:
        return
    ckf = f"cookie_{wiki}.ck"
    cookie_jar = http.cookiejar.LWPCookieJar(filename=ckf)
    try:
        cookie_jar.load(ignore_discard=True)
    except:
        pass
    print(f"...logging in on { wiki }")
    with requests.Session() as session:
        session.cookies = cookie_jar
        token_response = session.post(
            f"{WIKI_BASE_URL}/{wiki}/api.php",
            headers={"User-Agent": USER_AGENT, "Accept-Encoding": "gzip"},
            cookies=cookie_jar,
            params={
                "format": "json",
                "action": "query",
                "meta": "tokens",
                "type": "login",
            },
        ).json()
        session.post(
            f"{WIKI_BASE_URL}/{wiki}/api.php",
            headers={"User-Agent": USER_AGENT, "Accept-Encoding": "gzip"},
            cookies=cookie_jar,
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


def get_token(wiki: str) -> str:
    login(wiki)

    ckf = f"cookie_{wiki}.ck"
    cookie_jar = http.cookiejar.LWPCookieJar(filename=ckf)
    try:
        cookie_jar.load(ignore_discard=True)
    except:
        pass
    with requests.Session() as session:
        session.cookies = cookie_jar
        token_response = session.post(
            f"{WIKI_BASE_URL}/{wiki}/api.php",
            headers={"User-Agent": USER_AGENT, "Accept-Encoding": "gzip"},
            cookies=cookie_jar,
            params={
                "format": "json",
                "action": "query",
                "meta": "tokens",
            },
        ).json()
        return token_response["query"]["tokens"]["csrftoken"]
