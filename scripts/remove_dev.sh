#!/bin/bash

userAgent="GitHub Autodeploy Bot/1.1.0 (${WIKI_UA_EMAIL})"

. ./scripts/login_and_get_token.sh

ckf="cookie_base.ck"
declare -a removeErrors
declare -a allWikis
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

removePage() {
  page="${1}"
  wiki=$2

  echo "deleting ${wiki}:${page}"

  wikiApiUrl="${WIKI_BASE_URL}/${wiki}/api.php"
  ckf="cookie_${wiki}.ck"

  getToken $wiki

  rawRemoveResult=$(
    curl \
      -s \
      -b "$ckf" \
      -c "$ckf" \
      --data-urlencode "title=${page}" \
      --data-urlencode "reason=Remove ${LUA_DEV_ENV_NAME}" \
      --data-urlencode "token=${token}" \
      -H "User-Agent: ${userAgent}" \
      -H 'Accept-Encoding: gzip' \
      -X POST "${wikiApiUrl}?format=json&action=delete" \
      | gunzip
  )
  # Don't get rate limited
  sleep 8

  if [[ $rawRemoveResult != *"delete"* ]]; then
    echo "::warning::could not delete ${page} on ${wiki}"
    echo "::warning::could not delete ${page} on ${wiki}" >> $GITHUB_STEP_SUMMARY
    removeErrorMsg="${wiki}:${page}"
    removeErrors+=("${removeErrorMsg}")
  fi
}

searchAndRemove(){
  wiki=$1

  wikiApiUrl="${WIKI_BASE_URL}/${wiki}/api.php"

  rawSearchResult=$(
    curl \
      -s \
      -b "$ckf" \
      -c "$ckf" \
      --data-urlencode "list=search" \
      --data-urlencode "srsearch=intitle:${LUA_DEV_ENV_NAME}" \
      --data-urlencode "srnamespace=828" \
      --data-urlencode "srlimit=500" \
      --data-urlencode "srprop=" \
      -H "User-Agent: ${userAgent}" \
      -H 'Accept-Encoding: gzip' \
      -X POST "${wikiApiUrl}?format=json&action=query" \
      | gunzip
  )

  sleep 4

  pages=($(echo "$rawSearchResult" | jq ".query.search[] | .title" -r -c))

  if [[ -n $pages && ${#pages[@]} -ne 0 ]]; then
    for page in ${pages[@]}; do
      if [[ ${INCLUDE_SUB_ENVS} == true || "${page}" == *"${LUA_DEV_ENV_NAME}" ]]; then
        removePage $page $wiki
      fi
    done
  fi
}

for wiki in $allWikis; do
  if [[ $wiki != "commons" || ${INCLUDE_COMMONS} == true ]]; then
    echo "::group::Checking $wiki"
    searchAndRemove $wiki
  fi
done

rm -f cookie_*

if [[ ${#removeErrors[@]} -ne 0 ]]; then
  echo "::warning::Could not delete some pages on some wikis"
  echo "::warning::Could not delete some pages on some wikis" >> $GITHUB_STEP_SUMMARY
  echo "::group::Failed protections"
  for value in "${removeErrors[@]}"; do
      echo "... ${value}"
  done
  echo "::endgroup::"

  exit 1
fi
