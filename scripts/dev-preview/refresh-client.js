// Appended to the JS bundle we serve on only=scripts. No <script> tags — it is
// concatenated into executable JS. Every Liquipedia page loads this bundle via
// load.php, so appending here avoids rewriting HTML response bodies.
const REFRESH_CLIENT = `
;(function () {
	'use strict';
	function check() {
		fetch( '/__lp_dev_rebuild_check__', { cache: 'no-store' } )
			.then( function ( r ) { return r.ok ? r.json() : null; } )
			.then( function ( d ) { if ( d && d.reload ) { location.reload(); } } )
			.catch( function () {} );
	}
	setInterval( check, 2000 );
}());
`;

module.exports = { REFRESH_CLIENT };
