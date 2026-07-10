const fs = require( 'fs' );
const { execFileSync } = require( 'child_process' );
const { startProxy } = require( './proxy.js' );
const { startWatcher } = require( './watch.js' );
const { detectBrowser, launchBrowser, defaultExistsSync } = require( './browser.js' );
const { pacDataUrl } = require( './pac.js' );
const {
	REPO_ROOT, DEV_DIR, PROFILE_DIR, DEFAULT_PORT
} = require( './constants.js' );

const npmCmd = process.platform === 'win32' ? 'npm.cmd' : 'npm';

function fail( message ) {
	console.error( `[dev] ${ message }` );
	process.exit( 1 );
}

async function main() {
	const args = process.argv.slice( 2 );
	const port = Number( process.env.LP_DEV_PORT ) || DEFAULT_PORT;

	if ( args.includes( '--clean' ) ) {
		fs.rmSync( PROFILE_DIR, { recursive: true, force: true } );
		console.log( '[dev] wiped browser profile' );
	}
	fs.mkdirSync( DEV_DIR, { recursive: true } );

	// Fail fast: find a browser before doing anything expensive.
	const browserPath = detectBrowser( {
		env: process.env,
		platform: process.platform,
		existsSync: defaultExistsSync
	} );
	if ( !browserPath ) {
		fail( 'No Chromium-family browser found. Set LP_DEV_BROWSER to a chrome/chromium/brave/edge binary.' );
	}

	// Initial build so assets exist on first page load.
	try {
		console.log( '[dev] initial build...' );
		execFileSync( npmCmd, [ 'run', 'build' ], { cwd: REPO_ROOT, stdio: 'inherit' } );
	} catch ( e ) {
		fail( 'Initial build failed (see output above).' );
	}

	const state = { needsReload: false };

	let proxy;
	try {
		proxy = await startProxy( { port, state } );
	} catch ( e ) {
		fail( `Could not start proxy on port ${ port } (${ e.message }). Set LP_DEV_PORT to another port.` );
	}

	const watcher = startWatcher( { state } );

	const browser = launchBrowser( {
		browserPath,
		profileDir: PROFILE_DIR,
		pacUrl: pacDataUrl( port ),
		url: 'https://liquipedia.net'
	} );
	console.log( `[dev] launched ${ browserPath }` );
	console.log( '[dev] edit .scss/.js and the browser reloads. Ctrl-C to stop.' );

	let closing = false;
	function teardown() {
		if ( closing ) {
			return;
		}
		closing = true;
		console.log( '\n[dev] shutting down...' );
		try {
			watcher.stop();
		} catch ( e ) { /* ignore */ }
		try {
			proxy.stop();
		} catch ( e ) { /* ignore */ }
		try {
			browser.kill();
		} catch ( e ) { /* ignore */ }
		process.exit( 0 );
	}

	process.on( 'SIGINT', teardown );
	process.on( 'SIGTERM', teardown );
	browser.on( 'exit', teardown );
}

main();
