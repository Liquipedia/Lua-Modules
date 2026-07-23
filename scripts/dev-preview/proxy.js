const fs = require( 'fs' );
const { Proxy } = require( 'http-mitm-proxy' );
const { classifyRequest, contentTypeFor } = require( './classify.js' );
const { REFRESH_CLIENT } = require( './refresh-client.js' );
const { OUTPUT_CSS, OUTPUT_JS, CA_DIR } = require( './constants.js' );

const REBUILD_PATH = '/__lp_dev_rebuild_check__';

function readOrNull( file ) {
	try {
		return fs.readFileSync( file, 'utf8' );
	} catch ( e ) {
		return null;
	}
}

function serve( res, body, contentType ) {
	res.writeHead( 200, {
		'Content-Type': contentType,
		'Cache-Control': 'no-store'
	} );
	res.end( body );
}

function startProxy( { port, state } ) {
	const proxy = new Proxy();

	proxy.onError( ( ctx, err ) => {
		console.error( `[proxy] ${ err && err.message ? err.message : err }` );
	} );

	proxy.onRequest( ( ctx, callback ) => {
		const req = ctx.clientToProxyRequest;
		const host = req.headers.host || '';
		const res = ctx.proxyToClientResponse;

		// Rebuild-check endpoint (fetched relative to liquipedia.net origin).
		if ( req.url.startsWith( REBUILD_PATH ) ) {
			const reload = state.needsReload === true;
			state.needsReload = false;
			serve( res, JSON.stringify( { reload } ), 'application/json; charset=utf-8' );
			return;
		}

		const kind = classifyRequest( `https://${ host }${ req.url }` );
		if ( kind === 'styles' ) {
			const css = readOrNull( OUTPUT_CSS );
			if ( css !== null ) {
				serve( res, css, contentTypeFor( 'styles' ) );
				return;
			}
		} else if ( kind === 'scripts' ) {
			const js = readOrNull( OUTPUT_JS );
			if ( js !== null ) {
				serve( res, js + '\n' + REFRESH_CLIENT, contentTypeFor( 'scripts' ) );
				return;
			}
		}

		// passthrough, or local file missing → forward untouched.
		callback();
	} );

	return new Promise( ( resolve, reject ) => {
		// Force IPv4 loopback: http-mitm-proxy's internal per-hostname HTTPS
		// tunnel dials out via a hardcoded 0.0.0.0 (which the OS resolves as
		// 127.0.0.1). If host defaults to 'localhost' and that resolves to
		// ::1 first (common on modern Linux), the internal server binds
		// IPv6-only and the tunnel connect fails with ECONNREFUSED.
		proxy.listen( { host: '127.0.0.1', port, sslCaDir: CA_DIR }, ( err ) => {
			if ( err ) {
				reject( err );
				return;
			}
			console.log( `[proxy] listening on 127.0.0.1:${ port }` );
			resolve( { stop: () => proxy.close() } );
		} );
	} );
}

module.exports = { startProxy, REBUILD_PATH };
