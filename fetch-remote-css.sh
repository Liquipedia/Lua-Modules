#!/usr/bin/env bash
set -euo pipefail

# The styles liquipedia.net serves for the lakesideview skin, fetched once per
# run rather than once per snapshot.
# TODO: We might in the future make the cacheversion dynamic
URL='https://liquipedia.net/commons/load.php?cacheversion=cipipeline&lang=en&modules=fontawesome-pro|ext.TeamLiquidIntegration.liquipedia-custom-icon|skins.lakesideview.mw|skins.lakesideview.theme.commons&only=styles&skin=lakesideview'
ORIGIN='https://liquipedia.net'
OUTPUT='lua/output/css/lakeside.css'

cd "$(dirname "$0")"
mkdir -p "$(dirname "$OUTPUT")"

# Via a temporary file, so a failed transfer cannot clobber the previous copy.
# An empty stylesheet still loads, and would be screenshotted as if it were fine.
curl -fsS --max-time 30 -o "$OUTPUT.tmp" "$URL"

# Fonts, logos and icons are referenced from the site root, which off the local
# filesystem resolves nowhere. The bundle uses both url(/x) and url("/x").
sed -E 's|url\((["'\'']?)/|url(\1'"$ORIGIN"'/|g' "$OUTPUT.tmp" > "$OUTPUT"
rm "$OUTPUT.tmp"
