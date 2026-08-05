const fs = require( 'fs' );
const { execFile } = require( 'child_process' );
const chokidar = require( 'chokidar' );
const { WATCH_GLOBS, REPO_ROOT, MARKER_FILE } = require( './constants.js' );

const npmCmd = process.platform === 'win32' ? 'npm.cmd' : 'npm';

const DEBOUNCE_MS = 300;

// Hand the rebuild off to scripts/proxy_lp.py, which the browser polls. Written
// via a temp file + rename so the proxy can never read a half-written marker.
function writeMarker( kinds ) {
	const body = `${ Date.now() } ${ kinds.join( ',' ) }`;
	const temp = `${ MARKER_FILE }.tmp`;
	try {
		fs.writeFileSync( temp, body );
		fs.renameSync( temp, MARKER_FILE );
	} catch ( e ) {
		console.error( `[watch] could not write rebuild marker: ${ e.message }` );
	}
}

// chokidar v4 dropped glob-string support (watches literal paths only), so
// WATCH_GLOBS entries like 'stylesheets/**/*.scss' must be reduced to their
// base directory ('stylesheets') before being handed to chokidar.watch().
function globBaseDir( pattern ) {
	const base = [];
	for ( const segment of pattern.split( '/' ) ) {
		if ( segment.includes( '*' ) ) {
			break;
		}
		base.push( segment );
	}
	return base.join( '/' ) || '.';
}

function runBuild( script ) {
	return new Promise( ( resolve ) => {
		execFile( npmCmd, [ 'run', script ], { cwd: REPO_ROOT }, ( err, stdout, stderr ) => {
			if ( err ) {
				console.error( `[watch] ${ script } failed:\n${ stderr || stdout }` );
				resolve( false );
				return;
			}
			resolve( true );
		} );
	} );
}

function startWatcher() {
	let timer = null;
	let pending = { css: false, js: false };

	function schedule( kind ) {
		pending[ kind ] = true;
		if ( timer ) {
			clearTimeout( timer );
		}
		timer = setTimeout( async () => {
			timer = null;
			const todo = pending;
			pending = { css: false, js: false };
			const built = [];
			if ( todo.css && await runBuild( 'build:css' ) ) {
				built.push( 'css' );
			}
			if ( todo.js && await runBuild( 'build:js' ) ) {
				built.push( 'js' );
			}
			if ( built.length > 0 ) {
				writeMarker( built );
				// A css-only rebuild is hot-swapped in place; js needs a reload.
				const effect = built.includes( 'js' ) ? 'reload' : 'css swap';
				console.log( `[watch] rebuilt ${ built.join( '+' ) } — ${ effect }` );
			}
		}, DEBOUNCE_MS );
	}

	const watchDirs = [ ...new Set( WATCH_GLOBS.map( globBaseDir ) ) ];
	const watcher = chokidar.watch( watchDirs, {
		cwd: REPO_ROOT,
		ignoreInitial: true
	} );
	function onFileEvent( file ) {
		if ( file.endsWith( '.scss' ) ) {
			schedule( 'css' );
		} else if ( file.endsWith( '.js' ) ) {
			schedule( 'js' );
		}
	}
	watcher.on( 'change', onFileEvent );
	watcher.on( 'add', onFileEvent );
	watcher.on( 'unlink', onFileEvent );

	return { stop: () => watcher.close() };
}

module.exports = { startWatcher };
