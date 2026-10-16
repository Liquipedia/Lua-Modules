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

# The sed puts back the origin on fonts, logos and icons, which the bundle
# references from the site root, as both url(/x) and url("/x"). Off the local
# filesystem those resolve nowhere.
curl -fsS --compressed --max-time 30 "$URL" \
	| sed -E 's|url\((["'\'']?)/|url(\1'"$ORIGIN"'/|g' > "$OUTPUT"
