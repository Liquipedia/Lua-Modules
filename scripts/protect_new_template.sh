#!/bin/bash

userAgent="GitHub Autodeploy Bot/1.1.0 (${WIKI_UA_EMAIL})"

. ./scripts/protect_page.sh

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

echo "protecting ${TEMPLATE_TO_PROTECT}"

for wiki in $allWikis; do
  echo "::group::Checking $wiki"
  if [[ $wiki != "commons" ]]; then
    protectNonExistingPage ${TEMPLATE_TO_PROTECT} $wiki
  else
    protectExistingPage ${TEMPLATE_TO_PROTECT} $wiki
  fi
  protectNonExistingPage ${TEMPLATE_TO_PROTECT} $wiki
  echo '::endgroup::'
done

if [[ ${#protectErrors[@]} -ne 0 ]]; then
  echo "::warning::Specified template could not be protected on some wikis"
  echo ":warning: Specified template could not be protected on some wikis" >> $GITHUB_STEP_SUMMARY
  echo "::group::Failed protections"
  for value in "${protectErrors[@]}"; do
      echo "... ${value}"
  done
  echo "::endgroup::"
fi

rm -f cookie_*

if [[ ${#protectErrors[@]} -ne 0 ]]; then
  exit 1
fi
