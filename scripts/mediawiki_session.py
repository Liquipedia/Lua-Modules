import contextlib
import functools
import http.cookiejar
import os
import time

import requests

from typing import Any, Optional

from deploy_util import HEADER, SLEEP_DURATION

__all__ = [
    "MediaWikiSession",
    "MediaWikiSessionError",
]

USER_AGENT = f"GitHub Autodeploy Bot/2.0.0 ({os.getenv('WIKI_UA_EMAIL')})"
WIKI_BASE_URL = os.getenv("WIKI_BASE_URL")
WIKI_USER = os.getenv("WIKI_USER")
WIKI_PASSWORD = os.getenv("WIKI_PASSWORD")
HEADER = {
    "User-Agent": USER_AGENT,
    "accept": "application/json",
    "Accept-Encoding": "gzip",
}


class MediaWikiSessionError(IOError):
    pass


class MediaWikiSession(contextlib.AbstractContextManager):
    __cookie_jar: http.cookiejar.FileCookieJar
    __session: requests.Session
    __wiki: str

    def __init__(self, wiki: str):
        self.__wiki = wiki
        self.__cookie_jar = self.__read_cookie_jar()
        self.__session = requests.session()
        self.__session.cookies = self.__cookie_jar
        self.__session.headers.update(HEADER)

    def __read_cookie_jar(self) -> http.cookiejar.FileCookieJar:
        ckf = f"cookie_{self.__wiki}.ck"
        cookie_jar = http.cookiejar.LWPCookieJar(filename=ckf)
        with contextlib.suppress(OSError):
            cookie_jar.load(ignore_discard=True)
        return cookie_jar

    @functools.cache
    def __get_wiki_api_url(self):
        return f"{WIKI_BASE_URL}/{self.__wiki}/api.php"

    def _login(self):
        token_response = self.make_action(
            "query", params={"meta": "tokens", "type": "login"}
        )
        self.make_action(
            "login",
            data={
                "lgname": WIKI_USER,
                "lgpassword": WIKI_PASSWORD,
                "lgtoken": token_response["query"]["tokens"]["logintoken"],
            },
        )
        self.__cookie_jar.save(ignore_discard=True)
        self.cooldown()

    @functools.cached_property
    def token(self) -> str:
        self._login()
        return self.make_action("query", params={"meta": "tokens"})["tokens"][
            "csrftoken"
        ]

    def make_action(
        self, action: str, params: Optional[dict] = None, data: Optional[dict] = None
    ) -> dict[str, Any]:
        merged_params = {"format": "json", "action": action}
        if params is not None:
            merged_params = merged_params | params
        response: dict = self.__session.post(
            self.__get_wiki_api_url(), params=merged_params, data=data
        ).json()
        if "error" in response.keys():
            raise MediaWikiSessionError(response["error"]["info"])
        return response[action]

    def cooldown(self):
        time.sleep(SLEEP_DURATION)

    def close(self):
        self.__cookie_jar.save(ignore_discard=True)
        self.__session.close()

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()
