import contextlib
import functools
import http.cookiejar
import os
import pathlib
import time

import requests

from typing import Any, Optional

from deploy_util import (
    HEADER,
    SLEEP_DURATION,
    write_to_github_summary_file,
)

__all__ = [
    "MediaWikiSession",
    "MediaWikiSessionError",
]

ACTIONS_STEP_DEBUG = os.getenv("ACTIONS_STEP_DEBUG") == "true"
DEPLOY_TRIGGER = os.getenv("DEPLOY_TRIGGER")
WIKI_BASE_URL = os.getenv("WIKI_BASE_URL")
WIKI_USER = os.getenv("WIKI_USER")
WIKI_PASSWORD = os.getenv("WIKI_PASSWORD")


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
        ckf = f"cookie_{self.wiki}.ck"
        cookie_jar = http.cookiejar.LWPCookieJar(filename=ckf)
        with contextlib.suppress(OSError):
            cookie_jar.load(ignore_discard=True)
        return cookie_jar

    @functools.cache
    def __get_wiki_api_url(self):
        return f"{WIKI_BASE_URL}/{self.wiki}/api.php"

    def _login(self):
        token_response = self.make_action(
            "query", params={"meta": "tokens", "type": "login"}
        )
        self.make_action(
            "login",
            data={
                "lgname": WIKI_USER,
                "lgpassword": WIKI_PASSWORD,
                "lgtoken": token_response["tokens"]["logintoken"],
            },
        )
        self.__cookie_jar.save(ignore_discard=True)
        self.cooldown()

    @functools.cached_property
    def token(self) -> str:
        self._login()
        token = self.make_action("query", params={"meta": "tokens"})["tokens"][
            "csrftoken"
        ]
        if ACTIONS_STEP_DEBUG:
            print(f"::add-mask::{token}")
        return token

    @property
    def wiki(self) -> str:
        return self.__wiki

    def make_action(
        self, action: str, params: Optional[dict] = None, data: Optional[dict] = None
    ) -> dict[str, Any]:
        merged_params = {"format": "json", "action": action}
        if params is not None:
            merged_params |= params
        response = self.__session.post(
            self.__get_wiki_api_url(), params=merged_params, data=data
        )
        if ACTIONS_STEP_DEBUG:
            print(f"params: {merged_params}")
            print(f"data: {data}")
            print(f"HTTP Status: {response.status_code}")
            print(f'Raw response: "{response}"')
        parsed_response: dict[str, Any] = response.json()
        if "error" in parsed_response.keys():
            raise MediaWikiSessionError(parsed_response["error"]["info"])
        return parsed_response[action]

    def cooldown(self):
        time.sleep(SLEEP_DURATION)

    def deploy_file(
        self,
        file_path: pathlib.Path,
        file_content: str,
        target_page: str,
        deploy_reason: str,
    ) -> tuple[bool, bool]:
        try:
            change_made = False
            deployed = True
            response = self.make_action(
                "edit",
                data={
                    "title": target_page,
                    "text": file_content,
                    "summary": f"Git: {deploy_reason}",
                    "bot": "true",
                    "recreate": "true",
                    "token": self.token,
                },
            )
            result = response.get("result")
            new_rev_id = response.get("newrevid")
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
                write_to_github_summary_file(
                    f":warning: {str(file_path)} failed to deploy"
                )
                deployed = False
            return deployed, change_made
        except MediaWikiSessionError as e:
            print(f"::warning file={str(file_path)}::failed to deploy (API error)")
            write_to_github_summary_file(
                f":warning: {str(file_path)} failed to deploy due to API error: {str(e)}"
            )
            deployed = False
            return deployed, change_made
        finally:
            self.cooldown()

    def close(self):
        self.__cookie_jar.save(ignore_discard=True)
        self.__session.close()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()
