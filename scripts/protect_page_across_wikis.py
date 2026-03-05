import os

from deploy_util import get_wikis
from protect_page import (
    protect_non_existing_page,
    protect_existing_page,
    handle_protect_errors,
)

PAGE_TO_PROTECT = os.getenv("PAGE_TO_PROTECT")


def main():
    for wiki in get_wikis():
        print(f"::group::Checking {wiki}:{PAGE_TO_PROTECT}")
        if wiki == "commons":
            protect_existing_page(PAGE_TO_PROTECT, wiki)
        else:
            protect_non_existing_page(PAGE_TO_PROTECT, wiki)
        print("::endgroup::")
    handle_protect_errors()


if __name__ == "__main__":
    main()
