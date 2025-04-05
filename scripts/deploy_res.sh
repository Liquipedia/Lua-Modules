#!/bin/bash

userAgent="GitHub Autodeploy Bot/1.1.0 (${WIKI_UA_EMAIL})"

. ./scripts/login_and_get_token.sh

if [[ -n "$1" ]]; then
  files=$1
  gitDeployReason="\"$(git log -1 --pretty='%h %s')\""
else
  files=$(find stylesheets javascript -type f -name '*.less' -o -name '*.css' -o -name '*.js')
  gitDeployReason='Automated Weekly Re-Sync'
fi

wikiApiUrl="${WIKI_BASE_URL}/commons/api.php"
ckf="cookie_commons.ck"

allDeployed=true
changesMade=false
for file in $files; do
  if [[ -n "$1" ]]; then
    file="./$file"
  fi
  echo "::group::Checking $file"
  fileContents=$(cat "$file")
  fileName=$(basename "$file")

  if [[ $file == *.js ]]; then
    page="MediaWiki:Common.js/${fileName}"
  else
    page="MediaWiki:Common.css/${fileName}"
  fi

  echo "...page = $page"

  # Edit page
  getToken "commons"
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
  newRevId=$(echo "$rawResult" | jq ".edit.newrevid" -r)
  if [[ "${result}" == "Success" ]]; then
    if [[ "${newRevId}" != "null" ]]; then
      changesMade=true
      if [[ "${DEPLOY_TRIGGER}" != "push" ]]; then
        echo "::warning file=${file}::File changed"
      fi
    fi
    echo "...${result}"
    echo '...done'
    echo ":information_source: ${file} successfully deployed" >> $GITHUB_STEP_SUMMARY
  else
    echo "::warning file=${file}::failed to deploy"
    echo ":warning: ${file} failed to deploy" >> $GITHUB_STEP_SUMMARY
    allDeployed=false
  fi
  echo '::endgroup::'

  # Don't get rate limited
  sleep 4
done

if [ "$allDeployed" != true ]; then
  echo "::error::Some files were not deployed; resource cache version not updated!"
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
    echo "::error::Resource cache version unable to be updated!"
    exit 1
  fi
fi

rm -f cookie_*
