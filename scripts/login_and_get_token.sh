#!/bin/bash

userAgent="GitHub Autodeploy Bot/1.1.0 (${WIKI_UA_EMAIL})"

declare -A loggedin

# logs into a specified wiki
# $1 -> the wiki to log into
login() {
  wiki=$1

  if [[ ${loggedin[${wiki}]} != 1 ]]; then
    ckf="cookie_${wiki}.ck"
    wikiApiUrl="${WIKI_BASE_URL}/${wiki}/api.php"
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
}

# gets an edit/protect token for a specified wiki
# if not already logged in on the wiki also logs in on the wiki
# $1 -> the wiki to get the token for
getToken(){
  wiki=$1
  wikiApiUrl="${WIKI_BASE_URL}/${wiki}/api.php"
  ckf="cookie_${wiki}.ck"

  login $wiki

  token=$(
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
}
