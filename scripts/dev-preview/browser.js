const { spawn } = require( 'child_process' );
const fs = require( 'fs' );
const { BROWSER_CANDIDATES } = require( './constants.js' );

// Pure: pick the browser binary. LP_DEV_BROWSER wins; otherwise first existing
// candidate for the platform. Returns null if none found.
function detectBrowser( { env, platform, existsSync } ) {
	const override = env.LP_DEV_BROWSER;
	if ( override ) {
		return existsSync( override ) ? override : null;
	}
	const candidates = BROWSER_CANDIDATES[ platform ] || [];
	for ( const candidate of candidates ) {
		if ( existsSync( candidate ) ) {
			return candidate;
		}
	}
	return null;
}

// Thin shell: spawn the browser detached-but-tracked so we can kill it on teardown.
// --disable-quic is required: HTTP/3 bypasses the HTTP proxy entirely.
function launchBrowser( { browserPath, profileDir, pacUrl, url } ) {
	const args = [
		`--user-data-dir=${ profileDir }`,
		`--proxy-pac-url=${ pacUrl }`,
		'--ignore-certificate-errors',
		'--test-type',
		'--disable-quic',
		'--no-first-run',
		'--no-default-browser-check',
		'--new-window',
		url
	];
	return spawn( browserPath, args, { stdio: 'ignore' } );
}

module.exports = { detectBrowser, launchBrowser, defaultExistsSync: fs.existsSync };
