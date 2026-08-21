import asyncio

from http import HTTPStatus

from mitmproxy import http, master
from mitmproxy.addons import default_addons, dumper, errorcheck, keepserving, readfile


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
        self.__serve_local_file(
            flow, "lua/output/css/main.css", "text/css; charset=utf-8"
        )

    def __serve_local_js_resource(self, flow: http.HTTPFlow):
        self.__serve_local_file(
            flow, "lua/output/js/main.js", "text/javascript; charset=utf-8"
        )

    def __serve_local_file(self, flow: http.HTTPFlow, path: str, content_type: str):
        try:
            with open(path, "rb") as f:
                body = f.read()
        except OSError as error:
            # Leaving this unsaid means the request goes upstream, the page looks
            # untouched and nothing explains why
            print(f"LiquipediaMapper: {error}. Run npm run build first.")
            return

        flow.response = http.Response.make(
            HTTPStatus.OK,
            body,
            {"Content-Type": content_type},
        )
        flow.response.headers["Via"] = f"{flow.response.http_version} LiquipediaMapper"


async def main():
    m = master.Master(None)
    m.addons.add(
        *default_addons(),
        LiquipediaMapper(),
        dumper.Dumper(),
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
