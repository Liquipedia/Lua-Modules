import argparse
import itertools
import os
import pathlib
import re
import subprocess
import sys

from typing import Iterable, Optional

from dotenv import load_dotenv

from deploy_util import (
    get_git_deploy_reason,
    read_file_from_path,
    write_to_github_summary_file,
)
from mediawiki_session import MediaWikiSession

load_dotenv()

INVALID_DEV_ENV_NAMES = {"/dev", "/dev/"}
HEADER_PATTERN = re.compile(
    r"\A---\n" r"-- @Liquipedia\n" r"-- page=(?P<pageName>[^\n]*)\n"
)


def deploy_all_files_for_wiki(
    wiki: str,
    file_paths: Iterable[pathlib.Path],
    deploy_reason: str,
    dev_environment: Optional[str],
) -> bool:
    all_modules_deployed = True
    with MediaWikiSession(wiki) as session:
        for file_path in file_paths:
            print(f"::group::Checking {str(file_path)}")
            file_content = read_file_from_path(file_path)
            header_match = HEADER_PATTERN.match(file_content)
            if not header_match:
                print("...skipping - no magic comment found")
                write_to_github_summary_file(f"{str(file_path)} skipped")
            else:
                page = header_match.groupdict()["pageName"] + (dev_environment or "")
                module_deployed, _ = session.deploy_file(
                    file_path, file_content, page, deploy_reason
                )
                all_modules_deployed &= module_deployed
            print("::endgroup::")
    return all_modules_deployed


def dev_environment(dev_environment: Optional[str]) -> Optional[str]:
    if dev_environment is None:
        return None
    elif dev_environment in INVALID_DEV_ENV_NAMES or not dev_environment.startswith(
        "/dev/"
    ):
        raise ValueError(f"Invalid dev environment name: {dev_environment}")
    return dev_environment


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-A",
        "--deploy-all",
        action="store_true",
        help="Whether to deploy all files to wiki",
    )
    parser.add_argument(
        "lua_files", nargs="*", type=pathlib.Path, help="List of lua files to deploy"
    )
    dev_arg_group = parser.add_argument_group(
        "Dev Deploy", description="Deploy options for dev environments"
    )
    dev_arg_group.add_argument(
        "--base-ref",
        type=str,
        default=os.getenv("LUA_DEV_BASE_REF") or "main",
        help='Base reference to check against for finding changed files (default: LUA_DEV_BASE_REF environment variable if defined, otherwise "main")',
    )
    dev_arg_group.add_argument(
        "--dev-environment",
        type=dev_environment,
        default=os.getenv("LUA_DEV_ENV_NAME"),
        help="Name of the dev environment to deploy to (default: LUA_DEV_ENV_NAME environment variable)",
    )
    return parser


def main():
    all_modules_deployed = True
    lua_files: Iterable[pathlib.Path]
    git_deploy_reason: str

    parser = build_argument_parser()
    parsed_args = parser.parse_args()

    dev_environment: Optional[str] = parsed_args.dev_environment

    if parsed_args.deploy_all:
        if dev_environment is not None:
            parser.error("Target dev environment must not be specified in re-sync mode")
        lua_files = pathlib.Path("./lua/wikis/").rglob("*.lua")
        git_deploy_reason = "Automated Weekly Re-Sync"
    else:
        if len(parsed_args.lua_files) == 0:
            if dev_environment is None:
                parser.error("Target dev environment is not specified")
            lua_files = [
                pathlib.Path(changed_file)
                for changed_file in subprocess.check_output(
                    [
                        "git",
                        "diff",
                        "--name-only",
                        "--diff-filter=d",
                        parsed_args.base_ref,
                        "lua/wikis/*",
                    ]
                )
                .decode()
                .strip()
                .splitlines()
            ]
        else:
            lua_files = parsed_args.lua_files
        git_deploy_reason = get_git_deploy_reason()

    for wiki, files in itertools.groupby(sorted(lua_files), lambda path: path.parts[2]):
        all_modules_deployed &= deploy_all_files_for_wiki(
            wiki, list(files), git_deploy_reason, dev_environment
        )

    if not all_modules_deployed:
        print("::warning::Some modules were not deployed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
