#!/usr/bin/env bash
set -euo pipefail

# The styles liquipedia.net serves for the lakesideview skin, fetched once per
# run rather than once per snapshot.
# TODO: We might in the future make the cacheversion dynamic
URL='https://liquipedia.net/commons/load.php?cacheversion=cipipeline&lang=en&modules=fontawesome-pro|ext.TeamLiquidIntegration.liquipedia-custom-icon|skins.lakesideview.mw|skins.lakesideview.theme.commons&only=styles&skin=lakesideview'
ORIGIN='https://liquipedia.net'
OUTPUT='lua/output/css/lakeside.css'

cd "$(dirname "$0")/.."
mkdir -p "$(dirname "$OUTPUT")"
trap 'rm -f "$OUTPUT.tmp"' EXIT

# load.php occasionally answers 429 to CI's shared address, so back off and
# retry rather than failing the run. --compressed asks for the gzipped copy,
# which is a sixth of the traffic.
#
# The sed puts back the origin on fonts, logos and icons, which the bundle
# references from the site root, as both url(/x) and url("/x"). Off the local
# filesystem those resolve nowhere.
curl -fsS --compressed --retry 3 --retry-max-time 60 --max-time 30 "$URL" \
	| sed -E 's|url\((["'\'']?)/|url(\1'"$ORIGIN"'/|g' > "$OUTPUT.tmp"

# Replace a previous copy only once the whole pipeline has succeeded
mv "$OUTPUT.tmp" "$OUTPUT"
