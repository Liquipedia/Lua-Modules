const fs = require( 'fs' ).promises;
const path = require( 'path' );

/*
 * The styles liquipedia.net serves for the lakesideview skin, fetched once per
 * run rather than once per snapshot.
 * TODO: We might in the future make the cacheversion dynamic
 */
const url = new URL( 'https://liquipedia.net/commons/load.php' );
url.search = new URLSearchParams( {
	cacheversion: 'cipipeline',
	lang: 'en',
	modules: [
		'fontawesome-pro',
		'ext.TeamLiquidIntegration.liquipedia-custom-icon',
		'skins.lakesideview.mw',
		'skins.lakesideview.theme.commons'
	].join( '|' ),
	only: 'styles',
	skin: 'lakesideview'
} ).toString();
const origin = 'https://liquipedia.net';
const outFile = path.join( __dirname, '..', 'lua', 'output', 'css', 'lakeside.css' );

/*
 *Fonts, logos and icons are referenced from the site root, as url(/x),
 * url("/x") or url('/x'). Off the local filesystem those resolve nowhere, so the
 * origin is put back on. Protocol-relative url(//host/x) is left alone.
 */
const rootRelativeUrl = /url\(\s*(["']?)\/(?!\/)/g;

function absolutizeUrls( css ) {
	return css.replace( rootRelativeUrl, ( match, quote ) => `url(${ quote }${ origin }/` );
}

async function main() {
	const response = await fetch( url, {
		headers: { Accept: 'text/css' },
		signal: AbortSignal.timeout( 30000 )
	} );
	if ( !response.ok ) {
		throw new Error( `Failed to fetch ${ url }: ${ response.status } ${ response.statusText }` );
	}
	const css = await response.text();

	await fs.mkdir( path.dirname( outFile ), { recursive: true } );
	await fs.writeFile( outFile, absolutizeUrls( css ), 'utf8' );
}

main().catch( ( error ) => {
	console.error( error );
	process.exitCode = 1;
} );
