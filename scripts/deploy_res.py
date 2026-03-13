import itertools
import pathlib
import sys
import subprocess

from typing import Iterable

from deploy_util import (
    get_git_deploy_reason,
    read_file_from_path,
)
from mediawiki_session import MediaWikiSession


def deploy_resources(
    session: MediaWikiSession,
    res_type: str,
    file_paths: Iterable[pathlib.Path],
    deploy_reason: str,
) -> tuple[bool, bool]:
    all_deployed = True
    changes_made = False
    for file_path in file_paths:
        print(f"::group::Checking {str(file_path)}")
        file_content = read_file_from_path(file_path)
        page = (
            f"MediaWiki:Common.{'js' if res_type == '.js' else 'css'}/" + file_path.name
        )
        print(f"...page = {page}")
        deploy_result = session.deploy_file(
            file_path, file_content, page, deploy_reason
        )
        all_deployed = all_deployed and deploy_result[0]
        changes_made = changes_made or deploy_result[1]
        print("::endgroup::")
    return (all_deployed, changes_made)


def update_cache(session: MediaWikiSession):
    cache_result = session.make_action(
        "updatelpmwmessageapi",
        data={
            "messagename": "Resourceloaderarticles-cacheversion",
            "value": subprocess.check_output(["git", "log", "-1", "--pretty=%h"])
            .decode()
            .strip(),
        },
    )
    if (
        cache_result["updatelpmwmessageapi"].get("message")
        == "Successfully changed the message value"
    ):
        print("Resource cache version updated succesfully!")
    else:
        print("::error::Resource cache version unable to be updated!")
        exit(1)


def main():
    all_deployed: bool = True
    changes_made: bool = False
    resource_files: Iterable[pathlib.Path]
    git_deploy_reason: str
    if len(sys.argv[1:]) == 0:
        resource_files = itertools.chain(
            pathlib.Path("./javascript/").rglob("*.js"),
            pathlib.Path("./stylesheets/").rglob("*.scss"),
        )
        git_deploy_reason = "Automated Weekly Re-Sync"
    else:
        resource_files = [pathlib.Path(arg) for arg in sys.argv[1:]]
        git_deploy_reason = get_git_deploy_reason()

    with MediaWikiSession("commons") as commons_session:
        for res_type, files in itertools.groupby(
            sorted(resource_files), lambda path: path.suffix
        ):
            group_all_deployed, group_changes_made = deploy_resources(
                commons_session, res_type, list(files), git_deploy_reason
            )
            all_deployed = all_deployed and group_all_deployed
            changes_made = changes_made or group_changes_made

        if not all_deployed:
            print(
                "::error::Some files were not deployed; resource cache version not updated!"
            )
            exit(1)
        elif changes_made:
            update_cache(commons_session)


if __name__ == "__main__":
    main()
