#!/bin/bash

userAgent="GitHub Autodeploy Bot/1.1.0 (${WIKI_UA_EMAIL})"

. ./scripts/protect_page.sh

declare -a allWikis
declare -a regexErrors=()

regex="^\.?/?lua/wikis/([a-z0-9]+)/(.*)\.lua$"

if [[ -n "$1" ]] then
  filesToProtect=$1
elif [[ -n ${WIKI_TO_PROTECT} ]]; then
  filesToProtect=$(find lua/wikis -type f -name '*.lua')
else
  echo "Nothing to protect"
  exit 0
fi

allLuaFiles=$(find lua -type f -name '*.lua')

allWikis=$(
  curl \
    -s \
    -b "$ckf" \
    -c "$ckf" \
    -H "User-Agent: ${userAgent}" \
    -H 'Accept-Encoding: gzip' \
    -X GET "https://liquipedia.net/api.php?action=listwikis" \
    | gunzip \
    | jq '.allwikis | keys[]' -r
)
# Don't get rate limited
sleep 4

# checks if for a specified (commons) module there exists a local version of said module on the specified wiki in the git repo
# $1 -> module (without namespace prefix)
# $2 -> wiki
checkForLocalVersion() {
  if [[ $2 == "commons" ]]; then
    hasNoLocalVersion=false
  elif [[ $allLuaFiles == *"lua/wikis/${2}/${1}.lua"* ]] || [[ $filesToProtect == *"lua/wikis/${2}/${1}.lua"* ]]; then
    hasNoLocalVersion=false
  else
    hasNoLocalVersion=true
  fi
}

# protects a module against creation if it has no local version according to git
# $1 -> module (without namespace prefix)
# $2 -> wiki
protectIfHasNoLocalVersion() {
  module="${1}"
  page="Module:${module}"
  wiki="${2}"
  checkForLocalVersion $module $wiki
  if $hasNoLocalVersion; then
    protectNonExistingPage $page $wiki
  fi
}

for fileToProtect in $filesToProtect; do
  echo "::group::Checking $fileToProtect"
  if [[ $fileToProtect =~ $regex ]]; then
    wiki=${BASH_REMATCH[1]}
    module=${BASH_REMATCH[2]}
    page="Module:${module}"

    if [[ -n ${WIKI_TO_PROTECT} ]]; then
      if [[ $wiki == ${WIKI_TO_PROTECT} ]]; then
        protectExistingPage $page ${WIKI_TO_PROTECT}
      elif [[ $wiki == "commons" ]]; then
        protectIfHasNoLocalVersion $module ${WIKI_TO_PROTECT}
      fi
    elif [[ "commons" != $wiki ]]; then
      protectExistingPage $page $wiki
    else # commons case
      protectExistingPage $page $wiki

      for deployWiki in $allWikis; do
        protectIfHasNoLocalVersion $module $deployWiki
      done
    fi
  else
    echo '::warning::skipping - regex failed'
    regexErrors+=($fileToProtect)
  fi
  echo '::endgroup::'
done

if [[ ${#regexErrors[@]} -ne 0 ]]; then
  echo "::warning::Some regexes failed"
  echo ":warning: Some regexes failed" >> $GITHUB_STEP_SUMMARY
  echo "::group::Files the regex failed on"
  for value in "${regexErrors[@]}"; do
     echo "... ${failedRegex}"
  done
  echo "::endgroup::"
fi

if [[ ${#protectErrors[@]} -ne 0 ]]; then
  echo "::warning::Some modules could not be protected"
  echo ":warning: Some modules could not be protected" >> $GITHUB_STEP_SUMMARY
  echo "::group::Failed protections"
  for value in "${protectErrors[@]}"; do
     echo "... ${value}"
  done
  echo "::endgroup::"
fi

rm -f cookie_*

if [[ ${#protectErrors[@]} -ne 0 ]] || [[ ${#regexErrors[@]} -ne 0 ]]; then
  exit 1
fi
