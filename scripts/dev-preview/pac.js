function buildPac( port ) {
	// Apex + subdomains only. shExpMatch( '*.liquipedia.net' ) needs a dot
	// before the suffix, so it rejects lookalikes like notliquipedia.net;
	// the explicit apex check covers the bare domain. (Do NOT use
	// dnsDomainIs( host, 'liquipedia.net' ) — it is a plain suffix match and
	// would route notliquipedia.net through the proxy.)
	return [
		'function FindProxyForURL( url, host ) {',
		'\tif ( host === "liquipedia.net" || shExpMatch( host, "*.liquipedia.net" ) ) {',
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
