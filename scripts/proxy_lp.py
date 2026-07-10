import asyncio

from http import HTTPStatus

from mitmproxy import addons, http, master
from mitmproxy.addons import dumper, errorcheck, keepserving, readfile


class LiquipediaMapper:
    def request(self, flow: http.HTTPFlow) -> None:
        if "://liquipedia.net/" not in flow.request.pretty_url:
            return

        if (
            "only=styles" in flow.request.pretty_url
            and "skin=lakesideview" not in flow.request.pretty_url
        ):
            self.__serve_local_css_resource(flow)
        elif (
            "only=scripts" in flow.request.pretty_url
            and "skin=lakesideview" not in flow.request.pretty_url
        ):
            self.__serve_local_js_resource(flow)

    def __serve_local_css_resource(self, flow: http.HTTPFlow):
        with open("lua/output/css/main.css", "rb") as f:
            flow.response = http.Response.make(
                HTTPStatus.OK,
                f.read(),
                {"Content-Type": "text/css; charset=utf-8"},
            )
            flow.response.headers["Via"] = (
                f"{flow.response.http_version} LiquipediaMapper"
            )

    def __serve_local_js_resource(self, flow: http.HTTPFlow):
        with open("lua/output/js/main.js", "rb") as f:
            flow.response = http.Response.make(
                HTTPStatus.OK,
                f.read(),
                {"Content-Type": "text/javascript; charset=utf-8"},
            )
            flow.response.headers["Via"] = (
                f"{flow.response.http_version} LiquipediaMapper"
            )


async def main():
    m = master.Master(None)
    m.addons.add(
        *addons.default_addons(),
        LiquipediaMapper(),
        dumper.Dumper(),
        keepserving.KeepServing(),
        readfile.ReadFileStdin(),
        errorcheck.ErrorCheck(),
    )
    try:
        await m.run()
    except asyncio.CancelledError:
        await m.done()


if __name__ == "__main__":
    asyncio.run(main())
