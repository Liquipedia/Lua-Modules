const { spawn, spawnSync } = require( 'child_process' );
const { MITM_CONFDIR, PROXY_SCRIPT, REPO_ROOT } = require( './constants.js' );

const MITMDUMP = process.env.LP_DEV_MITMDUMP || 'mitmdump';

// How long to wait for mitmdump to prove it stayed up. It exits within
// milliseconds on the common failures (port taken, bad addon, missing dep), so
// this only has to outlast process spawn.
const STARTUP_GRACE_MS = 1500;

const INSTALL_HINT = `Could not run "${ MITMDUMP }". Install it with:\n` +
	'  pip install mitmproxy\n' +
	'Or point LP_DEV_MITMDUMP at the binary.';

// Cheap pre-flight so a missing mitmproxy fails with an install hint rather
// than an ENOENT stack trace after we have already run a build.
function checkAvailable() {
	const probe = spawnSync( MITMDUMP, [ '--version' ], { stdio: 'ignore' } );
	return !probe.error;
}

/**
 * Spawn mitmdump with scripts/proxy_lp.py as its addon. The addon owns all
 * request handling (interception, the rebuild-check endpoint, reload-client
 * injection); this module only owns the process lifecycle.
 *
 * @param {Object} options
 * @param {number} options.port Port to listen on, loopback only.
 * @param {boolean} options.reload Whether the addon should inject the reload client.
 * @return {Promise<{stop: Function}>}
 */
function startProxy( { port, reload } ) {
	if ( !checkAvailable() ) {
		return Promise.reject( new Error( INSTALL_HINT ) );
	}

	const args = [
		'--listen-host', '127.0.0.1',
		'--listen-port', String( port ),
		'--set', `confdir=${ MITM_CONFDIR }`,
		// Drop the per-request flow log; startup errors and the addon's own
		// output still come through. Do not turn termlog_verbosity down to do
		// this — that hides addon warnings too.
		'--flow-detail', '0',
		'-s', PROXY_SCRIPT
	];

	const child = spawn( MITMDUMP, args, {
		cwd: REPO_ROOT,
		stdio: [ 'ignore', 'inherit', 'inherit' ],
		env: Object.assign( {}, process.env, { LP_DEV_RELOAD: reload ? '1' : '0' } )
	} );

	return new Promise( ( resolve, reject ) => {
		let settled = false;

		child.on( 'error', ( err ) => {
			if ( settled ) {
				return;
			}
			settled = true;
			reject( new Error( `${ INSTALL_HINT }\n(${ err.message })` ) );
		} );

		// Exiting during the grace period means it never got listening — surface
		// that as a startup failure instead of a silently dead proxy.
		child.on( 'exit', ( code ) => {
			if ( settled ) {
				console.error( `[proxy] mitmdump exited (code ${ code })` );
				return;
			}
			settled = true;
			reject( new Error(
				`mitmdump exited immediately (code ${ code }); see output above. ` +
				`If port ${ port } is taken, set LP_DEV_PORT to another one.`
			) );
		} );

		setTimeout( () => {
			if ( settled ) {
				return;
			}
			settled = true;
			console.log( `[proxy] mitmdump listening on 127.0.0.1:${ port }` );
			resolve( {
				stop: () => child.kill( 'SIGTERM' )
			} );
		}, STARTUP_GRACE_MS );
	} );
}

module.exports = { startProxy };
