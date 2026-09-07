import { mkdirSync, writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// The styles liquipedia.net loads for the lakesideview skin. The snapshot
// template renders against these, so we fetch them once per run instead of
// once per snapshot.
// TODO: We might in the future make the cacheversion dynamic
const REMOTE_CSS_URL = 'https://liquipedia.net/commons/load.php?cacheversion=cipipeline&lang=en&modules=fontawesome-pro|ext.TeamLiquidIntegration.liquipedia-custom-icon|skins.lakesideview.mw|skins.lakesideview.theme.commons&only=styles&skin=lakesideview';
const REMOTE_CSS_ORIGIN = 'https://liquipedia.net';
const OUTPUT_PATH = resolve(__dirname, 'lua', 'output', 'css', 'lakeside.css');

let response;
try {
	response = await fetch(REMOTE_CSS_URL);
} catch (error) {
	console.error(`Error: could not reach ${REMOTE_CSS_ORIGIN} (${error.message})`);
	process.exit(1);
}

if (!response.ok) {
	console.error(`Error: could not fetch the remote stylesheet (HTTP ${response.status})`);
	process.exit(1);
}

// Fonts, logos and icons are referenced from the site root. Served from disk
// those would resolve against the local filesystem, so point them back at the
// wiki.
const css = (await response.text()).replace(/url\((["']?)\/(?!\/)/g, `url($1${REMOTE_CSS_ORIGIN}/`);

mkdirSync(dirname(OUTPUT_PATH), { recursive: true });
writeFileSync(OUTPUT_PATH, css);
