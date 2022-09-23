#!/bin/bash

userAgent="GitHub Autodeploy Bot/1.0.0 (${LP_UA_EMAIL})"
wikiBaseUrl='https://liquipedia.net/'
luaFiles=$1
pat='\-\-\-\
\-\- @Liquipedia\
\-\- wiki=([^
]*)\
\-\- page=([^
]*)\
'
gitCommitSubject=$(git log -1 --pretty='%h %s')

declare -A loggedin

for luaFile in $luaFiles
do
  echo "== Checking ./$luaFile =="
  fileContents=$(cat "./$luaFile")

  [[ $fileContents =~ $pat ]]

  if [[ "${BASH_REMATCH[1]}" == "" ]]
  then
    echo '...skipping - no magic comment found'
  else
    echo '...magic comment found - updating wiki...'
    wiki="${BASH_REMATCH[1]}"
    page="${BASH_REMATCH[2]}"
    echo "...wiki = $wiki"
    echo "...page = $page"
    wikiApiUrl="${wikiBaseUrl}${wiki}/api.php"
    ckf="cookie_${wiki}.ck"

    if [[ ${loggedin[${wiki}]} != 1 ]]
    then
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
        --data-urlencode "username=${LP_USER}" \
        --data-urlencode "password=${LP_PASSWORD}" \
        --data-urlencode "logintoken=${loginToken}" \
        --data-urlencode "loginreturnurl=https://liquipedia.net" \
        -H "User-Agent: ${userAgent}" \
        -H 'Accept-Encoding: gzip' \
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
        --data-urlencode "summary=Git: \"${gitCommitSubject}\"" \
        --data-urlencode "bot=true" \
        --data-urlencode "recreate=true" \
        --data-urlencode "token=${editToken}" \
        -H "User-Agent: ${userAgent}" \
        -H 'Accept-Encoding: gzip' \
        -X POST "${wikiApiUrl}?format=json&action=edit" \
        | gunzip
    )
    result=$(echo "$rawResult" | jq ".edit.result" -r)
    echo "DEBUG: ...${rawResult}"
    echo "...${result}"

    echo '...done'
    # Don't get rate limited
    sleep 4
  fi
done

rm cookie_*
