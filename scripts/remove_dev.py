import os

from deploy_util import (
    get_wikis,
    write_to_github_summary_file,
)
from mediawiki_session import MediaWikiSession, MediaWikiSessionError

LUA_DEV_ENV_NAME = os.getenv("LUA_DEV_ENV_NAME")

remove_errors: list[str] = list()


def remove_page(session: MediaWikiSession, page: str):
    print(f"deleting {session.wiki}:{page}")

    try:
        session.post(
            "delete",
            data={
                "title": page,
                "reason": f"Remove {LUA_DEV_ENV_NAME}",
                "token": session.token,
            },
        )
    except MediaWikiSessionError as e:
        print(f"::warning::could not delete {page} on {session.wiki}")
        write_to_github_summary_file(
            f":warning: could not delete {page} on {session.wiki}"
        )
        remove_errors.append(f"{session.wiki}:{page}")
    finally:
        session.cooldown()


def search_and_remove(wiki: str):
    with MediaWikiSession(wiki) as session:
        search_result: dict
        try:
            search_result = session.make_action(
                "query",
                data={
                    "list": "search",
                    "srsearch": f"intitle:{LUA_DEV_ENV_NAME}",
                    "srnamespace": 828,
                    "srlimit": 5000,
                    "srprop": "",
                },
            )
        except MediaWikiSessionError as e:
            print(f"::warning::search API error on {wiki}: {str(e)}")
            write_to_github_summary_file(
                f":warning: search API error on {wiki}: {str(e)}"
            )
            return
        finally:
            session.cooldown()

        pages = search_result.get("search") or []
        if len(pages) == 0:
            return

        for page in pages:
            if os.getenv("INCLUDE_SUB_ENVS") == "true" or page["title"].endswith(
                LUA_DEV_ENV_NAME
            ):
                remove_page(session, page["title"])


def main():
    for wiki in get_wikis():
        if wiki == "commons" and os.getenv("INCLUDE_COMMONS") != "true":
            continue
        search_and_remove(wiki)
    if len(remove_errors) == 0:
        exit(0)
    print("::warning::Could not delete some pages on some wikis")
    write_to_github_summary_file("::warning::Could not delete some pages on some wikis")
    print("::group::Failed protections")
    for remove_error in remove_errors:
        print(remove_error)
    print("endgroup")
    exit(1)


if __name__ == "__main__":
    main()
