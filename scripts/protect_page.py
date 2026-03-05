from typing import Iterable, Literal


from deploy_util import write_to_github_summary_file
from mediawiki_session import MediaWikiSession, MediaWikiSessionError

__all__ = [
    "protect_non_existing_pages",
    "protect_existing_pages",
    "handle_protect_errors",
]

protect_errors = list()


def protect_pages(
    session: MediaWikiSession,
    pages: Iterable[str],
    protect_mode: Literal["edit", "create"],
):
    protect_options: str
    if protect_mode == "edit":
        protect_options = "edit=allow-only-sysop|move=allow-only-sysop"
    elif protect_mode == "create":
        protect_options = "create=allow-only-sysop"
    else:
        raise ValueError(f"invalid protect mode: {protect_mode}")
    print(f"...wiki = {session.wiki}")
    for page in pages:
        print(f"...page = {page}")
        try:
            protections = session.make_action(
                "protect",
                data={
                    "title": page,
                    "protections": protect_options,
                    "reason": "Git maintained",
                    "expiry": "infinite",
                    "bot": "true",
                    "token": session.token,
                },
            )["protections"]

            for protection in protections:
                if protection[protect_mode] == "allow-only-sysop":
                    break
            else:
                print(
                    f"::warning::could not ({protect_mode}) protect {page} on {session.wiki}"
                )
                protect_errors.append(f"{protect_mode}:{session.wiki}:{page}")
        except MediaWikiSessionError as e:
            print(
                f"::warning::could not ({protect_mode}) protect {page} on {session.wiki}: {str(e)}"
            )
            protect_errors.append(f"{protect_mode}:{session.wiki}:{page}")
        finally:
            session.cooldown()


def protect_non_existing_pages(session: MediaWikiSession, pages: Iterable[str]):
    def filter_non_existing_pages(page: str) -> bool:
        try:
            result = session.make_action(
                "query",
                data={"titles": page, "prop": "info"},
            )
            if "-1" in result["pages"]:
                return True
            print(f"::warning::{page} already exists on {session.wiki}")
            protect_errors.append(f"create:{session.wiki}:{page}")
            return False
        finally:
            session.cooldown()

    protect_pages(session, filter(filter_non_existing_pages, pages), "create")


def protect_existing_pages(session: MediaWikiSession, pages: Iterable[str]):
    protect_pages(session, pages, "edit")


def handle_protect_errors():
    if len(protect_errors) == 0:
        return
    print("::warning::Some pages could not be protected")
    write_to_github_summary_file(":warning: Some pages could not be protected")
    print("::group::Failed protections")
    for protect_error in protect_errors:
        print(f"... {protect_error}")
    print("::endgroup::")
    exit(1)
