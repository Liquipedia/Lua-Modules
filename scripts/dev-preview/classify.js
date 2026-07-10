// Classify a proxied request URL into the local asset we should serve, or
// 'passthrough' to forward it to the real server untouched.
function classifyRequest( rawUrl ) {
	let parsed;
	try {
		parsed = new URL( rawUrl );
	} catch ( e ) {
		return 'passthrough';
	}

	const host = parsed.hostname.toLowerCase();
	const isLiquipedia = host === 'liquipedia.net' || host.endsWith( '.liquipedia.net' );
	if ( !isLiquipedia || !parsed.pathname.endsWith( '/commons/load.php' ) ) {
		return 'passthrough';
	}

	// The LakesideView skin needs runtime theme vars we cannot compile locally.
	if ( ( parsed.searchParams.get( 'skin' ) || '' ) === 'lakesideview' ) {
		return 'passthrough';
	}

	const only = parsed.searchParams.get( 'only' );
	if ( only === 'styles' ) {
		return 'styles';
	}
	if ( only === 'scripts' ) {
		return 'scripts';
	}
	return 'passthrough';
}

function contentTypeFor( kind ) {
	if ( kind === 'styles' ) {
		return 'text/css; charset=utf-8';
	}
	if ( kind === 'scripts' ) {
		return 'text/javascript; charset=utf-8';
	}
	throw new Error( `No content type for kind: ${ kind }` );
}

module.exports = { classifyRequest, contentTypeFor };
