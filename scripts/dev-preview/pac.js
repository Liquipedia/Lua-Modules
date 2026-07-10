// Route only *.liquipedia.net through the local proxy; everything else DIRECT
// so the contributor's normal browsing is untouched.
function buildPac( port ) {
	return [
		'function FindProxyForURL( url, host ) {',
		'\tif ( dnsDomainIs( host, "liquipedia.net" ) || shExpMatch( host, "*.liquipedia.net" ) ) {',
		`\t\treturn "PROXY 127.0.0.1:${ port }";`,
		'\t}',
		'\treturn "DIRECT";',
		'}'
	].join( '\n' );
}

function pacDataUrl( port ) {
	const encoded = encodeURIComponent( buildPac( port ) );
	return `data:application/x-ns-proxy-autoconfig,${ encoded }`;
}

module.exports = { buildPac, pacDataUrl };
