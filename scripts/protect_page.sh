#!/bin/bash

userAgent="GitHub Autodeploy Bot/1.1.0 (${WIKI_UA_EMAIL})"

. ./scripts/login_and_get_token.sh

declare -a protectErrors=()

# protects a specified page on a specified wiki with the specified protect mode
# $1 -> page (inkl namespace prefix)
# $2 -> wiki
# $3 -> protect mode ('edit' || 'create')
protectPage() {
  page="${1}"
  wiki=$2
  protectMode=$3

  if [[ ${protectMode} == 'edit' ]]; then
    protectOptions="edit=allow-only-sysop|move=allow-only-sysop"
  elif [[ ${protectMode} == 'create' ]]; then
    protectOptions="create=allow-only-sysop"
  else
    echo "::warning:: invalid protect mode: ${protectMode}"
    exit 1
  fi

  echo "...wiki = $wiki"
  echo "...page = ${page}"
  wikiApiUrl="${WIKI_BASE_URL}/${wiki}/api.php"
  ckf="cookie_${wiki}.ck"

  getToken $wiki

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
      --data-urlencode "token=${token}" \
      -H "User-Agent: ${userAgent}" \
      -H 'Accept-Encoding: gzip' \
      -X POST "${wikiApiUrl}?format=json&action=protect" \
      | gunzip
  )
  # Don't get rate limited
  sleep 4

  result=$(echo "$rawProtectResult" | jq ".protect.protections.[].${protectMode}" -r)
  if [[ $result != *"allow-only-sysop"* ]]; then
    echo "::warning::could not (${protectMode}) protect ${page} on ${wiki}"
    protectErrorMsg="${protectMode}:${wiki}:${page}"
    protectErrors+=("${protectErrorMsg}")
  fi
}

# checks if a specified page on a specified wiki exists
# $1 -> page (inkl namespace prefix)
# $2 -> wiki
checkIfPageExists() {
  page="${1}"
  wiki="${2}"
  wikiApiUrl="${WIKI_BASE_URL}/${wiki}/api.php"
  ckf="cookie_${wiki}.ck"

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

  if [[ $rawResult == *'missing":"'* ]]; then
    pageExists=false
  else
    pageExists=true
  fi
}

# protects a specified page on a specified wiki against creation
# if the page already exists it will issue a warning
# $1 -> page (inkl namespace prefix)
# $2 -> wiki
protectNonExistingPage() {
  page="${1}"
  wiki=$2

  checkIfPageExists "${page}" $wiki
  if $pageExists; then
    echo "::warning::$page already exists on $wiki"
    protectErrors+=("create:${WIKI_TO_PROTECT}:${page}")
  else
    protectPage "${page}" "${wiki}" "create"
  fi
}

# protects a specified page on a specified wiki against editing/moving
# $1 -> page (inkl namespace prefix)
# $2 -> wiki
protectExistingPage() {
  protectPage "${1}" "${2}" "edit"
}
