import itertools
import pathlib
import sys
import subprocess
import time

from typing import Iterable

import requests

from deploy_util import *
from login_and_get_token import *


all_deployed: bool = True
changes_made: bool = False


def deploy_resources(
    res_type: str, file_paths: Iterable[pathlib.Path], deploy_reason: str
):
    token = get_token("commons")
    with requests.Session() as session:
        session.cookies = read_cookie_jar("commons")
        for file_path in file_paths:
            print(f"::group::Checking {str(file_path)}")
            file_content = read_file_from_path(file_path)
            page = (
                f"MediaWiki:Common.{ "js" if res_type == ".js" else "css" }/"
                + file_path.name
            )
            print(f"...page = { page }")
            response = session.post(
                get_wiki_api_url("commons"),
                headers=HEADER,
                params={"format": "json", "action": "edit"},
                data={
                    "title": page,
                    "text": file_content,
                    "summary": f"Git: {deploy_reason}",
                    "bot": "true",
                    "recreate": "true",
                    "token": token,
                },
            ).json()
            print(response)
            result = response["edit"]["result"]
            new_rev_id = response["edit"].get("newrevid")
            if result == "Success":
                if new_rev_id is not None:
                    changes_made = True
                    if DEPLOY_TRIGGER != "push":
                        print(f"::warning file={str(file_path)}::File changed")
                print(f"...{result}")
                print("...done")
                write_to_github_summary_file(
                    f":information_source: {str(file_path)} successfully deployed"
                )

            else:
                print(f"::warning file={str(file_path)}::failed to deploy")
                write_to_github_summary_file(
                    f":warning: {str(file_path)} failed to deploy"
                )
                all_deployed = False
            print("::endgroup::")
            time.sleep(4)


def update_cache():
    with requests.Session() as session:
        session.cookies = read_cookie_jar("commons")
        cache_result = session.post(
            get_wiki_api_url("commons"),
            headers=HEADER,
            params={"format": "json", "action": "updatelpmwmessageapi"},
            data={
                "messagename": "Resourceloaderarticles-cacheversion",
                "value": subprocess.check_output(
                    ["git", "log", "-1", "--pretty='%h'"]
                ).decode(),
            },
        ).json()
        if (
            cache_result["updatelpmwmessageapi"].get("message")
            == "Successfully changed the message value"
        ):
            print("Resource cache version updated succesfully!")
        else:
            print("::error::Resource cache version unable to be updated!")
            exit(1)


def main():
    resource_files: Iterable[pathlib.Path]
    git_deploy_reason: str
    if len(sys.argv[1:]) == 0:
        resource_files = itertools.chain(
            pathlib.Path("./").glob("javascript/**/*.js"),
            pathlib.Path("./").glob("stylesheets/**/*.scss"),
        )
        git_deploy_reason = "Automated Weekly Re-Sync"
    else:
        resource_files = [pathlib.Path(arg) for arg in sys.argv[1:]]
        git_deploy_reason = get_git_deploy_reason()

    for res_type, files in itertools.groupby(resource_files, lambda path: path.suffix):
        deploy_resources(res_type, list(files), git_deploy_reason)

    if not all_deployed:
        print(
            "::error::Some files were not deployed; resource cache version not updated!"
        )
        exit(1)
    elif changes_made:
        update_cache()


main()
