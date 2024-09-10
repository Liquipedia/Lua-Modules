#!/bin/bash

userAgent="GitHub Autodeploy Bot/1.1.0 (${WIKI_UA_EMAIL})"
devWikis=('rocketleague' 'commons')
pat='\-\-\-\
\-\- @Liquipedia\
\-\- wiki=([^
]*)\
\-\- page=([^
]*)\
'

declare -A loggedin

if [[ -n "$1" ]]; then
  luaFiles=$1
  gitDeployReason="\"$(git log -1 --pretty='%h %s')\""
else
  luaFiles=$(find . -type f -name '*.lua')
  gitDeployReason='Automated Weekly Re-Sync'
fi

allModulesDeployed=true
for luaFile in $luaFiles; do
  if [[ -n "$1" ]]; then
    luaFile="./$luaFile"
  fi
  echo "== Checking $luaFile =="
  fileContents=$(cat "$luaFile")

  [[ $fileContents =~ $pat ]]

  if [[ "${BASH_REMATCH[1]}" == "" ]]; then
    echo '...skipping - no magic comment found'
  else
    wiki="${BASH_REMATCH[1]}"
    page="${BASH_REMATCH[2]}${LUA_DEV_ENV_NAME}"

    if [[ ! ( ("${DEV_WIKI_BASIC_AUTH}" == "") || ("${devWikis[*]}" =~ ${wiki}) ) ]]; then
        echo '...skipping - dev wiki not applicable...'
        continue
    fi

    echo '...magic comment found - updating wiki...'

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
          -H "Authorization: Basic ${DEV_WIKI_BASIC_AUTH}" \
          -X POST "$wikiApiUrl" \
          | gunzip \
          | jq ".query.tokens.logintoken" -r
      )
      curl \
        -s \
        -b "$ckf" \
        -c "$ckf" \
        --data-urlencode "username=${WIKI_USER}" \
        --data-urlencode "password=${WIKI_PASSWORD}" \
        --data-urlencode "logintoken=${loginToken}" \
        --data-urlencode "loginreturnurl=${WIKI_BASE_URL}" \
        -H "User-Agent: ${userAgent}" \
        -H 'Accept-Encoding: gzip' \
        -H "Authorization: Basic ${DEV_WIKI_BASIC_AUTH}" \
        -X POST "${wikiApiUrl}?format=json&action=clientlogin" \
        | gunzip \
        > /dev/null
      loggedin[$wiki]=1
      # Don't get rate limited
      sleep 4
    fi

    # Edit page
    editToken=$(
      curl \
        -s \
        -b "$ckf" \
        -c "$ckf" \
        -d "format=json&action=query&meta=tokens" \
        -H "User-Agent: ${userAgent}" \
        -H 'Accept-Encoding: gzip' \
        -H "Authorization: Basic ${DEV_WIKI_BASIC_AUTH}" \
        -X POST "$wikiApiUrl" \
        | gunzip \
        | jq ".query.tokens.csrftoken" -r
    )
    rawResult=$(
      curl \
        -s \
        -b "$ckf" \
        -c "$ckf" \
        --data-urlencode "title=${page}" \
        --data-urlencode "text=${fileContents}" \
        --data-urlencode "summary=Git: ${gitDeployReason}" \
        --data-urlencode "bot=true" \
        --data-urlencode "recreate=true" \
        --data-urlencode "token=${editToken}" \
        -H "User-Agent: ${userAgent}" \
        -H 'Accept-Encoding: gzip' \
        -H "Authorization: Basic ${DEV_WIKI_BASIC_AUTH}" \
        -X POST "${wikiApiUrl}?format=json&action=edit" \
        | gunzip
    )
    result=$(echo "$rawResult" | jq ".edit.result" -r)
    echo "DEBUG: ...${rawResult}"
    if [[ "${result}" == "Success" ]]; then
      echo "...${result}"
      echo '...done'
    else
      echo "...failed to deploy"
      allModulesDeployed=false
    fi

    # Don't get rate limited
    sleep 4
  fi

  if [ "$allModulesDeployed" != true ]; then
    echo "DEBUG: Some modules were not deployed!"
    exit 1
  fi
done

rm -f cookie_*
