#!/usr/bin/env bash
set -euo pipefail

# The styles liquipedia.net loads for the lakesideview skin. The snapshot
# template renders against these, so we fetch them once per run instead of
# once per snapshot.
# TODO: We might in the future make the cacheversion dynamic
URL='https://liquipedia.net/commons/load.php?cacheversion=cipipeline&lang=en&modules=fontawesome-pro|ext.TeamLiquidIntegration.liquipedia-custom-icon|skins.lakesideview.mw|skins.lakesideview.theme.commons&only=styles&skin=lakesideview'
ORIGIN='https://liquipedia.net'
OUTPUT='lua/output/css/lakeside.css'

cd "$(dirname "$0")"
mkdir -p "$(dirname "$OUTPUT")"

# Download to a temporary file rather than piping into sed. A failed transfer
# would otherwise leave a truncated stylesheet behind, and an empty one still
# loads, so we would screenshot an unstyled page rather than fail.
curl -fsS --max-time 30 -o "$OUTPUT.tmp" "$URL"

# Fonts, logos and icons are referenced from the site root. Served from disk
# those would resolve against the local filesystem, so point them back at the
# wiki. Mind the quotes, the bundle uses both url(/x) and url("/x").
sed -E 's|url\((["'\'']?)/|url(\1'"$ORIGIN"'/|g' "$OUTPUT.tmp" > "$OUTPUT"
rm "$OUTPUT.tmp"
