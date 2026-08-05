"""Serve locally-built CSS/JS in place of Liquipedia's production assets.

Two ways to run this:

    mitmproxy -s scripts/proxy_lp.py        # bring your own browser + CA cert
    npm run dev                             # spawns mitmdump with this addon,
                                            # plus a throwaway browser and a
                                            # rebuild watcher

The live-reload half (the rebuild-check endpoint and the injected client) is
inert unless LP_DEV_RELOAD=1, which only `npm run dev` sets, so a standalone run
never injects anything into the page.
"""

import json
import os
import pathlib
from http import HTTPStatus
from urllib.parse import urlparse

from mitmproxy import http

# Resolved from this file rather than the working directory, so a git worktree
# serves its own build instead of the main checkout's.
REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent

CSS_FILE = REPO_ROOT / "lua" / "output" / "css" / "main.css"
JS_FILE = REPO_ROOT / "lua" / "output" / "js" / "main.js"

# Written by scripts/dev-preview/watch.js after a successful rebuild. Content is
# "<buildId> <kinds>", e.g. "1754400000000 css,js".
MARKER_FILE = REPO_ROOT / ".dev-preview" / "rebuild_marker"
CLIENT_FILE = REPO_ROOT / "scripts" / "dev-preview" / "refresh-client.js"

REBUILD_CHECK_PATH = "/__lp_dev_rebuild_check__"
ASSET_PATH_SUFFIX = "/commons/load.php"

VIA_TOKEN = "LiquipediaMapper"

CONTENT_TYPES = {
    "styles": "text/css; charset=utf-8",
    "scripts": "text/javascript; charset=utf-8",
}


def reload_enabled() -> bool:
    return os.environ.get("LP_DEV_RELOAD") == "1"


def is_liquipedia(host: str) -> bool:
    """Match the apex and its subdomains, but not lookalikes.

    endswith(".liquipedia.net") requires the separating dot, so
    "notliquipedia.net" is rejected. Keep this in step with the PAC in
    scripts/dev-preview/pac.js.
    """
    host = host.lower()
    return host == "liquipedia.net" or host.endswith(".liquipedia.net")


def classify(request: http.Request) -> str | None:
    """Return "styles", "scripts", or None to forward the request untouched."""
    if not is_liquipedia(request.pretty_host):
        return None

    if not urlparse(request.path).path.endswith(ASSET_PATH_SUFFIX):
        return None

    # The LakesideView skin needs runtime theme vars we cannot compile locally.
    if request.query.get("skin", "") == "lakesideview":
        return None

    only = request.query.get("only", "")
    return only if only in CONTENT_TYPES else None


def read_marker() -> dict:
    """Read the rebuild marker without consuming it.

    Clients track the build id they last saw, so every open tab observes every
    rebuild. Consuming the marker here would let whichever tab polled first
    starve the others.
    """
    try:
        raw = MARKER_FILE.read_text(encoding="utf-8").strip()
    except OSError:
        return {"buildId": 0, "css": False, "js": False}

    build_id, _, kinds = raw.partition(" ")
    try:
        parsed_id = int(build_id)
    except ValueError:
        return {"buildId": 0, "css": False, "js": False}

    parts = [kind.strip() for kind in kinds.split(",")]
    return {"buildId": parsed_id, "css": "css" in parts, "js": "js" in parts}


class LiquipediaMapper:
    def request(self, flow: http.HTTPFlow) -> None:
        request = flow.request

        if not is_liquipedia(request.pretty_host):
            return

        if reload_enabled() and urlparse(request.path).path == REBUILD_CHECK_PATH:
            self.__serve_rebuild_check(flow)
            return

        kind = classify(request)
        if kind == "styles":
            self.__serve_local(flow, CSS_FILE, kind)
        elif kind == "scripts":
            self.__serve_local(flow, JS_FILE, kind, suffix=self.__reload_client())

    def __serve_rebuild_check(self, flow: http.HTTPFlow) -> None:
        self.__respond(
            flow,
            json.dumps(read_marker()).encode("utf-8"),
            "application/json; charset=utf-8",
        )

    def __reload_client(self) -> bytes:
        """Read the client per request so editing it needs no proxy restart."""
        if not reload_enabled():
            return b""
        try:
            return b"\n;" + CLIENT_FILE.read_bytes()
        except OSError:
            return b""

    def __serve_local(
        self,
        flow: http.HTTPFlow,
        path: pathlib.Path,
        kind: str,
        suffix: bytes = b"",
    ) -> None:
        try:
            body = path.read_bytes()
        except OSError:
            # Nothing built yet — let the real asset through rather than
            # serving an empty stylesheet or bundle. Printed rather than logged
            # so it stays visible whatever mitmproxy's termlog verbosity is set
            # to (turning that down hides addon warnings along with the rest).
            print(f"[proxy] {path} missing, forwarding {kind} upstream", flush=True)
            return

        self.__respond(flow, body + suffix, CONTENT_TYPES[kind])

    def __respond(self, flow: http.HTTPFlow, body: bytes, content_type: str) -> None:
        flow.response = http.Response.make(
            HTTPStatus.OK,
            body,
            {"Content-Type": content_type, "Cache-Control": "no-store"},
        )
        flow.response.headers["Via"] = f"{flow.response.http_version} {VIA_TOKEN}"


addons = [LiquipediaMapper()]
