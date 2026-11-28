import asyncio
import logging
import re

from http import HTTPStatus

from mitmproxy import http, master
from mitmproxy.addons import (
    default_addons,
    dumper,
    errorcheck,
    keepserving,
    readfile,
    termlog,
)

logger = logging.getLogger(__name__)

CSS_PATH = "lua/output/css/main.css"
JS_PATH = "lua/output/js/main.js"
CSS_CONTENT_TYPE = "text/css; charset=utf-8"
JS_CONTENT_TYPE = "text/javascript; charset=utf-8"

# Lighthouse pages load one bundle per wiki instead of MediaWiki's load.php
LIGHTHOUSE_BUNDLE = re.compile(
    r"^https://liquipedia\.net/static/wikis/[^/?]+/bundle\.min\.(css|js)(?:\?|$)"
)
# The JS bundle is Lighthouse's own prelude (mw shim, jQuery, ...) followed by
# the commons modules, which start where Core.js declares liquipedia
LIGHTHOUSE_MODULES_START = re.compile(r"\bconst\s+liquipedia\s*=")


class LiquipediaMapper:
    def request(self, flow: http.HTTPFlow) -> None:
        url = flow.request.pretty_url
        if "://liquipedia.net/" not in url:
            return

        bundle = LIGHTHOUSE_BUNDLE.match(url)
        if bundle:
            if bundle.group(1) == "css":
                self.__serve_local_file(flow, CSS_PATH, CSS_CONTENT_TYPE)
            # The JS bundle is spliced in response(), it needs the upstream prelude
            return

        if "only=styles" in url and "skin=lakesideview" not in url:
            self.__serve_local_file(flow, CSS_PATH, CSS_CONTENT_TYPE)
        elif "only=scripts" in url and "skin=lakesideview" not in url:
            self.__serve_local_file(flow, JS_PATH, JS_CONTENT_TYPE)

    def response(self, flow: http.HTTPFlow) -> None:
        bundle = LIGHTHOUSE_BUNDLE.match(flow.request.pretty_url)
        if not bundle or bundle.group(1) != "js":
            return
        if flow.response is None or flow.response.status_code != HTTPStatus.OK:
            return

        local = self.__read_local_file(JS_PATH)
        if local is None:
            return

        upstream = flow.response.get_text()
        modules_start = LIGHTHOUSE_MODULES_START.search(upstream or "")
        if modules_start is None:
            logger.error(
                "no liquipedia modules found in %s, serving it untouched",
                flow.request.pretty_url,
            )
            return

        flow.response.set_text(
            upstream[: modules_start.start()] + "\n" + local.decode("utf-8")
        )
        flow.response.headers["Content-Type"] = JS_CONTENT_TYPE
        self.__mark(flow)

    def __serve_local_file(self, flow: http.HTTPFlow, path: str, content_type: str):
        body = self.__read_local_file(path)
        if body is None:
            return

        flow.response = http.Response.make(
            HTTPStatus.OK,
            body,
            {"Content-Type": content_type},
        )
        self.__mark(flow)

    @staticmethod
    def __read_local_file(path: str) -> bytes | None:
        try:
            with open(path, "rb") as f:
                return f.read()
        except FileNotFoundError:
            # Leaving this unsaid means the request goes upstream, the page looks
            # untouched and nothing explains why
            logger.error("%s is missing, run npm run build first", path)
        except OSError:
            logger.exception("could not read %s", path)
        return None

    @staticmethod
    def __mark(flow: http.HTTPFlow):
        flow.response.headers["Via"] = f"{flow.response.http_version} LiquipediaMapper"


async def main():
    m = master.Master(None)
    m.addons.add(
        *default_addons(),
        LiquipediaMapper(),
        dumper.Dumper(),
        termlog.TermLog(),
        keepserving.KeepServing(),
        readfile.ReadFileStdin(),
        errorcheck.ErrorCheck(),
    )
    try:
        await m.run()
    except asyncio.CancelledError:
        pass
    finally:
        m.shutdown()


if __name__ == "__main__":
    asyncio.run(main())
else:
    addons = [LiquipediaMapper()]
