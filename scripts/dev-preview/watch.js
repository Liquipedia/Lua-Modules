const { execFile } = require( 'child_process' );
const chokidar = require( 'chokidar' );
const { WATCH_GLOBS, REPO_ROOT } = require( './constants.js' );

const npmCmd = process.platform === 'win32' ? 'npm.cmd' : 'npm';

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

function startWatcher( { state } ) {
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
			let built = false;
			if ( todo.css && await runBuild( 'build:css' ) ) {
				built = true;
			}
			if ( todo.js && await runBuild( 'build:js' ) ) {
				built = true;
			}
			if ( built ) {
				state.needsReload = true;
				console.log( '[watch] rebuilt — browser will reload' );
			}
		}, 300 );
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
