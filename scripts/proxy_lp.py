import logging
import subprocess

from http import HTTPStatus
from mitmproxy import http


class LiquipediaMapper:
    def request(self, flow: http.HTTPFlow) -> None:
        if "://liquipedia.net/" not in flow.request.pretty_url:
            return

        if (
            "only=styles" in flow.request.pretty_url
            and "skin=lakesideview" not in flow.request.pretty_url
        ):
            self.__build_css_resource(flow)
        elif "only=scripts" in flow.request.pretty_url:
            self.__build_js_resource(flow)

    def __build_css_resource(self, flow: http.HTTPFlow):
        try:
            logging.info(
                subprocess.check_output(
                    ["npm", "run", "build:css"], stderr=subprocess.STDOUT
                ).decode()
            )
            logging.info("Successfully compiled stylesheet")
        except subprocess.SubprocessError as e:
            logging.exception(e)
            return
        with open("lua/output/css/main.css", "rb") as f:
            flow.response = http.Response.make(
                HTTPStatus.OK,
                f.read(),
                {"Content-Type": "text/css; charset=utf-8", "Via": "LiquipediaMapper"},
            )

    def __build_js_resource(self, flow: http.HTTPFlow):
        try:
            logging.info(
                subprocess.check_output(
                    ["node", "build-js.js"], stderr=subprocess.STDOUT
                ).decode()
            )
            logging.info("Successfully compiled javascript")
        except subprocess.SubprocessError as e:
            logging.exception(e)
            return
        with open("lua/output/js/main.js", "rb") as f:
            flow.response = http.Response.make(
                HTTPStatus.OK,
                f.read(),
                {
                    "Content-Type": "text/javascript; charset=utf-8",
                    "Via": "LiquipediaMapper",
                },
            )


addons = [LiquipediaMapper()]
