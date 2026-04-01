import os

from deploy_util import get_wikis
from mediawiki_session import MediaWikiSession
from protect_page import (
    protect_non_existing_pages,
    protect_existing_pages,
    handle_protect_errors,
)

PAGE_TO_PROTECT = os.getenv("PAGE_TO_PROTECT")


def main():
    for wiki in sorted(get_wikis()):
        with MediaWikiSession(wiki) as session:
            if wiki == "commons":
                protect_existing_pages(session, [PAGE_TO_PROTECT])
            else:
                protect_non_existing_pages(session, [PAGE_TO_PROTECT])
    handle_protect_errors()


if __name__ == "__main__":
    main()
