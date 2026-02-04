import asyncio
import os

import aiohttp

__all__ = ["USER_AGENT", "WIKI_BASE_URL", "get_token"]

USER_AGENT = f"GitHub Autodeploy Bot/1.1.0 ({ os.getenv("WIKI_UA_EMAIL") })"
WIKI_BASE_URL = os.getenv("WIKI_BASE_URL")
WIKI_USER = os.getenv("WIKI_USER")
WIKI_PASSWORD = os.getenv("WIKI_PASSWORD")

loggedin: set[str] = set()
loggedin_lock = asyncio.Lock()


async def login(wiki: str):
    await loggedin_lock.acquire()
    try:
        if wiki in loggedin:
            return
        ckf = f"cookie_{wiki}.ck"
        cookie_jar = aiohttp.CookieJar()
        if os.path.exists(ckf):
            cookie_jar.load(ckf)
        print(f"...logging in on { wiki }")
        async with aiohttp.ClientSession(
            f"{WIKI_BASE_URL}/{wiki}/",
            headers={"User-Agent": USER_AGENT, "Accept-Encoding": "gzip"},
            cookie_jar=cookie_jar,
        ) as session:
            token_response = await session.post(
                "api.php",
                params={
                    "format": "json",
                    "action": "query",
                    "meta": "tokens",
                    "type": "login",
                },
            )
            response = await token_response.json()
            await session.post(
                "api.php",
                data={
                    "lgname": WIKI_USER,
                    "lgpassword": WIKI_PASSWORD,
                    "lgtoken": response["query"]["tokens"]["logintoken"],
                },
                params={"format": "json", "action": "login"},
            )
            loggedin.add(wiki)
            cookie_jar.save(ckf)
            await asyncio.sleep(4)

    finally:
        loggedin_lock.release()


async def get_token(wiki: str) -> str:
    await login(wiki)

    ckf = f"cookie_{wiki}.ck"
    cookie_jar = aiohttp.CookieJar()
    if os.path.exists(ckf):
        cookie_jar.load(ckf)
    async with aiohttp.ClientSession(
        f"{WIKI_BASE_URL}/{wiki}/",
        headers={"User-Agent": USER_AGENT, "Accept-Encoding": "gzip"},
        cookie_jar=cookie_jar,
    ) as session:
        token_response = await session.post(
            "api.php",
            params={
                "format": "json",
                "action": "query",
                "meta": "tokens",
            },
        )
        response = await token_response.json()
        return response["query"]["tokens"]["csrftoken"]
