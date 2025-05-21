#!/bin/bash

userAgent="GitHub Autodeploy Bot/1.1.0 (${WIKI_UA_EMAIL})"
pat='\-\-\-\
\-\- @Liquipedia\
\-\- wiki=([^
]*)\
\-\- page=([^
]*)\
'

. ./scripts/login_and_get_token.sh

if [[ -n "$1" ]]; then
  luaFiles=$1
  gitDeployReason="\"$(git log -1 --pretty='%h %s')\""
else
  luaFiles=$(find lua -type f -name '*.lua')
  gitDeployReason='Automated Weekly Re-Sync'
fi

allModulesDeployed=true
for luaFile in $luaFiles; do
  if [[ -n "$1" ]]; then
    luaFile="./$luaFile"
  fi
  echo "::group::Checking $luaFile"
  fileContents=$(cat "$luaFile")

  [[ $fileContents =~ $pat ]]

  if [[ "${BASH_REMATCH[1]}" == "" ]]; then
    echo '...skipping - no magic comment found'
    echo "${luaFile} skipped" >> $GITHUB_STEP_SUMMARY
  else
    wiki="${BASH_REMATCH[1]}"
    page="${BASH_REMATCH[2]}${LUA_DEV_ENV_NAME}"

    echo '...magic comment found - updating wiki...'

    echo "...wiki = $wiki"
    echo "...page = $page"
    wikiApiUrl="${WIKI_BASE_URL}/${wiki}/api.php"
    ckf="cookie_${wiki}.ck"

    getToken ${wiki}

    # Edit page
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
        --data-urlencode "token=${token}" \
        -H "User-Agent: ${userAgent}" \
        -H 'Accept-Encoding: gzip' \
        -X POST "${wikiApiUrl}?format=json&action=edit" \
        | gunzip
    )
    result=$(echo "$rawResult" | jq ".edit.result" -r)
    if [[ "${result}" == "Success" ]]; then
      nochange=$(echo "$rawResult" | jq ".edit.nochange" -r)
      echo "...${result}"
      if [[ "${nochange}" == "" ]] && [[ "${DEPLOY_TRIGGER}" == "push" ]]; then
        echo "::notice file=${luaFile}::No change made"
      elif [[ "${nochange}" != "" ]] && [[ "${DEPLOY_TRIGGER}" != "push" ]]; then
        echo "::warning file=${luaFile}::File changed"
      fi
      echo '...done'
      echo ":information_source: ${luaFile} successfully deployed" >> $GITHUB_STEP_SUMMARY
    else
      echo "::warning file=${luaFile}::failed to deploy"
      echo ":warning: ${luaFile} failed to deploy" >> $GITHUB_STEP_SUMMARY
      allModulesDeployed=false
    fi

    # Don't get rate limited
    sleep 4
  fi
  echo '::endgroup::'

  if [ "$allModulesDeployed" != true ]; then
    echo "::warning::Some modules were not deployed!"
    exit 1
  fi
done

rm -f cookie_*
