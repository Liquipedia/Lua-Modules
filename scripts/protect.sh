#!/bin/bash

userAgent="GitHub Autodeploy Bot/1.1.0 (${WIKI_UA_EMAIL})"

declare -A loggedin
declare -a allWikis
declare -a regexErrors=()
declare -a protectErrors=()

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

fetchAllWikis() {
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

}

checkForLocalVersion() {
  if [[ $2 == "commons" ]]; then
    hasNoLocalVersion=false
  elif [[ $allLuaFiles == *"lua/wikis/${2}/${1}.lua"* ]] || [[ $filesToProtect == *"lua/wikis/${2}/${1}.lua"* ]]; then
    hasNoLocalVersion=false
  else
    hasNoLocalVersion=true
  fi
}

protectPage() {
  page="Module:${1}"
  wiki=$2
  protectOptions=$3
  protectMode=$4
  echo "...wiki = $wiki"
  echo "...page = $page"
  wikiApiUrl="${WIKI_BASE_URL}/${wiki}/api.php"
  ckf="cookie_${wiki}.ck"

  if [[ ${loggedin[${wiki}]} != 1 ]]; then
    # Login
    echo "...logging in on \"${wiki}\""
    loginToken=$(
      curl \
        -s \
        -b "$ckf" \
        -c "$ckf" \
        -d "format=json&action=query&meta=tokens&type=login" \
        -H "User-Agent: ${userAgent}" \
        -H 'Accept-Encoding: gzip' \
        -X POST "$wikiApiUrl" \
        | gunzip \
        | jq ".query.tokens.logintoken" -r
    )
    curl \
      -s \
      -b "$ckf" \
      -c "$ckf" \
      --data-urlencode "lgname=${WIKI_USER}" \
      --data-urlencode "lgpassword=${WIKI_PASSWORD}" \
      --data-urlencode "lgtoken=${loginToken}" \
      -H "User-Agent: ${userAgent}" \
      -H 'Accept-Encoding: gzip' \
      -X POST "${wikiApiUrl}?format=json&action=login" \
      | gunzip \
      > /dev/null
    loggedin[$wiki]=1
    # Don't get rate limited
    sleep 4
  fi

  # Protect Page
  protectToken=$(
    curl \
      -s \
      -b "$ckf" \
      -c "$ckf" \
      -d "format=json&action=query&meta=tokens" \
      -H "User-Agent: ${userAgent}" \
      -H 'Accept-Encoding: gzip' \
      -X POST "$wikiApiUrl" \
      | gunzip \
      | jq ".query.tokens.csrftoken" -r
  )
  rawProtectResult=$(
    curl \
      -s \
      -b "$ckf" \
      -c "$ckf" \
      --data-urlencode "title=${page}" \
      --data-urlencode "protections=${protectOptions}" \
      --data-urlencode "reason=Git maintained" \
      --data-urlencode "expiry=infinite" \
      --data-urlencode "bot=true" \
      --data-urlencode "token=${protectToken}" \
      -H "User-Agent: ${userAgent}" \
      -H 'Accept-Encoding: gzip' \
      -X POST "${wikiApiUrl}?format=json&action=protect" \
      | gunzip
  )
  # Don't get rate limited
  sleep 4

  result=$(echo "$rawProtectResult" | jq ".protect.protections.[].${protectMode}" -r)
  if [[ $result != *"allow-only-sysop"* ]]; then
    echo "::warning::could not protect $1 on $2"
    protectErrorMsg="${protectMode}:${wiki}:${page}"
    echo "${protectErrorMsg}"
    protectErrors+=("${protectErrorMsg}")
  fi
}

protectExistingPage() {
  protectPage $1 $2 "edit=allow-only-sysop|move=allow-only-sysop" "edit"
}

protectNonExistingPage() {
  protectPage $1 $2 "create=allow-only-sysop" "create"
}

checkIfPageExists() {
  page="Module:${1}"
  wikiApiUrl="${WIKI_BASE_URL}/${2}/api.php"
  rawResult=$(
    curl \
      -s \
      -b "$ckf" \
      -c "$ckf" \
      --data-urlencode "titles=${page}" \
      --data-urlencode "prop=info" \
      -H "User-Agent: ${userAgent}" \
      -H 'Accept-Encoding: gzip' \
      -X POST "${wikiApiUrl}?format=json&action=query" \
      | gunzip
  )

  # Don't get rate limited
  sleep 4

  if [[ $rawResult == *'missing'* ]]; then
    pageExists=false
  else
    pageExists=true
  fi
}

for fileToProtect in $filesToProtect; do
  echo "::group::Trying to protect for $fileToProtect"
  if [[ $fileToProtect =~ $regex ]]; then
    wiki=${BASH_REMATCH[1]}
    module=${BASH_REMATCH[2]}

    if [[ -n ${WIKI_TO_PROTECT} ]]; then
      if [[ $wiki == ${WIKI_TO_PROTECT} ]]; then
        protectExistingPage $module ${WIKI_TO_PROTECT}
      elif [[ $wiki == "commons" ]]; then
        checkForLocalVersion $module ${WIKI_TO_PROTECT}
        if $hasNoLocalVersion; then
          protectNonExistingPage $module ${WIKI_TO_PROTECT}
        fi
      else
        echo "...no protection needed"
      fi
    elif [[ "commons" != $wiki ]]; then
      protectExistingPage $module $wiki
    else # commons case
      protectExistingPage $module $wiki
      if [[ -z "$allWikis" ]] || [[ ${#allWikis[@]} -ne 0 ]]; then
        fetchAllWikis
      fi
      for deployWiki in $allWikis; do
        checkForLocalVersion $module $deployWiki
        if $hasNoLocalVersion; then
          echo "...protecting ${module} against creation on ${deployWiki}"
          checkIfPageExists $module $deployWiki
          if $pageExists; then
            echo "::warning::$fileToProtect already exists on $deployWiki"
            protectErrors+=("$fileToProtect on $deployWiki")
          else
            protectNonExistingPage $module $deployWiki
          fi
        fi
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

