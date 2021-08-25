#!/bin/bash

wikiBaseUrl='https://liquipedia.net/'
luaFiles=$(find . -type f -name '*.lua')
pat='\-\-\-\
\-\- @Liquipedia\
\-\- wiki=([^
]*)\
\-\- page=([^
]*)\
'

declare -A loggedin

for luaFile in $luaFiles
do
  echo "== Checking $luaFile =="
  fileContents=$(cat $luaFile)

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

    if [[ ${loggedin[${wiki}]} != 1 ]]
    then
      # Login
      echo "...logging in on \"${wiki}\""
      loginToken=$(curl -s -b "cookie_${wiki}.ck" -c "cookie_${wiki}.ck" -d "format=json&action=query&meta=tokens&type=login" -H 'User-Agent: GitHub Autodeploy Bot/1.0.0 (fonttax@liquipedia.net)' -H 'Accept-Encoding: gzip' -X POST $wikiApiUrl | gunzip | jq .query.tokens.logintoken -r)
      curl -s -b "cookie_${wiki}.ck" -c "cookie_${wiki}.ck" --data-urlencode "username=${LP_USER}" --data-urlencode "password=${LP_PASSWORD}" --data-urlencode "logintoken=${loginToken}" --data-urlencode "loginreturnurl=https://liquipedia.net" -H 'User-Agent: GitHub Autodeploy Bot/1.0.0 (fonttax@liquipedia.net)' -H 'Accept-Encoding: gzip' -X POST "${wikiApiUrl}?format=json&action=clientlogin" | gunzip > /dev/null
      loggedin[$wiki]=1
    fi

    # Edit page
    editToken=$(curl -s -b "cookie_${wiki}.ck" -c "cookie_${wiki}.ck" -d "format=json&action=query&meta=tokens" -H 'User-Agent: GitHub Autodeploy Bot/1.0.0 (fonttax@liquipedia.net)' -H 'Accept-Encoding: gzip' -X POST $wikiApiUrl | gunzip | jq .query.tokens.csrftoken -r)
    result=$(curl -s -b "cookie_${wiki}.ck" -c "cookie_${wiki}.ck" --data-urlencode "title=${page}" --data-urlencode "text=${fileContents}" --data-urlencode "summary=Auto update from git - file \"${luaFile}\"" --data-urlencode "bot=true" --data-urlencode "recreate=true" --data-urlencode "token=${editToken}" -H 'User-Agent: GitHub Autodeploy Bot/1.0.0 (fonttax@liquipedia.net)' -H 'Accept-Encoding: gzip' -X POST "${wikiApiUrl}?format=json&action=edit" | gunzip | jq .edit.result -r)
    echo "...${result}"

    echo '...done'
    # Don't get rate limited
    sleep 5
  fi
done

rm cookie_*
