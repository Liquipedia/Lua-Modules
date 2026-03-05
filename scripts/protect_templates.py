import os

from mediawiki_session import MediaWikiSession
from protect_page import (
    protect_non_existing_pages,
    protect_existing_pages,
    handle_protect_errors,
)

WIKI_TO_PROTECT = os.getenv("WIKI_TO_PROTECT")


def main():
    with open("./templates/templatesToProtect", "r") as templates_to_protect:
        templates = [
            "Template:" + template_name
            for template_name in filter(
                lambda template: len(template.strip()) > 0,
                templates_to_protect.read().splitlines(),
            )
        ]
        with MediaWikiSession(WIKI_TO_PROTECT) as session:
            print(f"::group::Protecting {WIKI_TO_PROTECT}")
            if WIKI_TO_PROTECT == "commons":
                protect_existing_pages(session, templates)
            else:
                protect_non_existing_pages(session, templates)
            print("::endgroup::")
    handle_protect_errors()


if __name__ == "__main__":
    main()
