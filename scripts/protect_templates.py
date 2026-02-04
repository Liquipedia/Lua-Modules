import os

from protect_page import *

WIKI_TO_PROTECT = os.getenv("WIKI_TO_PROTECT")


def main():
    with open("./templates/templatesToProtect", "r") as templates_to_protect:
        for template_name in templates_to_protect.readlines():
            template = "Template:" + template_name
            print(f"::group::Checking {WIKI_TO_PROTECT}:{template}")
            if WIKI_TO_PROTECT == "commons":
                protect_existing_page(template, WIKI_TO_PROTECT)
            else:
                protect_non_existing_page(template, WIKI_TO_PROTECT)
            print("::endgroup::")
    handle_protect_errors()


if __name__ == "__main__":
    main()
