#!/bin/bash

userAgent="GitHub Autodeploy Bot/1.1.0 (${WIKI_UA_EMAIL})"

declare -A loggedin

if [[ -n "$1" ]]; then
  files=$1
  gitDeployReason="\"$(git log -1 --pretty='%h %s')\""
else
  files=$(find stylesheets javascript -type f -name '*.less' -o -name '*.css' -o -name '*.js')
  gitDeployReason='Automated Weekly Re-Sync'
fi

wikiApiUrl="${WIKI_BASE_URL}/commons/api.php"
ckf="cookie_commons.ck"
# Login
echo "...logging in on commons"
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
  --data-urlencode "username=${WIKI_USER}" \
  --data-urlencode "password=${WIKI_PASSWORD}" \
  --data-urlencode "logintoken=${loginToken}" \
  --data-urlencode "loginreturnurl=${WIKI_BASE_URL}" \
  -H "User-Agent: ${userAgent}" \
  -H 'Accept-Encoding: gzip' \
  -X POST "${wikiApiUrl}?format=json&action=clientlogin" \
  | gunzip \
  > /dev/null

allDeployed=true
changesMade=false
for file in $files; do
  if [[ -n "$1" ]]; then
    file="./$file"
  fi
  echo "== Checking $file =="
  fileContents=$(cat "$file")
  fileName=$(basename "$file")

  if [[ $file == *.js ]]; then
    page="MediaWiki:Common.js/${fileName}"
  else
    page="MediaWiki:Common.css/${fileName}"
  fi

  echo "...page = $page"

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
      --data-urlencode "summary=Git: ${gitDeployReason}" \
      --data-urlencode "bot=true" \
      --data-urlencode "recreate=true" \
      --data-urlencode "token=${editToken}" \
      -H "User-Agent: ${userAgent}" \
      -H 'Accept-Encoding: gzip' \
      -X POST "${wikiApiUrl}?format=json&action=edit" \
      | gunzip
  )
  result=$(echo "$rawResult" | jq ".edit.result" -r)
  newRevId=$(echo "$rawResult" | jq ".edit.newrevid" -r)
  echo "DEBUG: ...${rawResult}"
  if [[ "${result}" == "Success" ]]; then
    if [[ "${newRevId}" != "null" ]]; then
      changesMade=true
    fi
    echo "...${result}"
    echo '...done'
  else
    echo "...failed to deploy"
    allDeployed=false
  fi

  # Don't get rate limited
  sleep 4
done

if [ "$allDeployed" != true ]; then
  echo "DEBUG: Some files were not deployed; resource cache version not updated!"
  exit 1
elif [ "$changesMade" == true ]; then
  cacheResult=$(
    curl \
      -s \
      -b "$ckf" \
      -c "$ckf" \
      --data-urlencode "messagename=Resourceloaderarticles-cacheversion" \
      --data-urlencode "value=$(git log -1 --pretty='%h')" \
      -H "User-Agent: ${userAgent}" \
      -H 'Accept-Encoding: gzip' \
      -X POST "${wikiApiUrl}?format=json&action=updatelpmwmessageapi" \
      | gunzip \
      | jq ".updatelpmwmessageapi.message" -r
  )
  if [[ "${cacheResult}" == "Successfully changed the message value" ]]; then
  	echo "Resource cache version updated succesfully!"
  else
    echo "DEBUG: Resource cache version unable to be updated!"
    exit 1
  fi
fi

rm -f cookie_*
