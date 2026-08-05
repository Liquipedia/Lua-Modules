// Appended to the JS bundle that scripts/proxy_lp.py serves for only=scripts,
// and only when reload is enabled. No <script> tags — it is concatenated into
// executable JS. Every Liquipedia page loads that bundle via load.php, so
// appending here avoids rewriting HTML response bodies.
//
// Runs standalone: it must not assume `liquipedia`, `mw` or jQuery exist, since
// it may execute before (or without) them.
( function () {
	'use strict';

	if ( window.__lpDevRefresh ) {
		return;
	}
	window.__lpDevRefresh = true;

	var CHECK_PATH = '/__lp_dev_rebuild_check__';
	var POLL_MS = 2000;
	var BUST_PARAM = '__lpdev';

	// Build id last seen by this page. Seeded on the first poll so a marker left
	// by a build that predates this page load does not trigger anything.
	var lastBuildId = null;
	// Set when a JS rebuild landed but reloading was unsafe; retried each poll.
	var reloadPending = false;
	var warnedSuppressed = false;

	function log( message ) {
		console.info( '[lp-dev] ' + message );
	}

	// A reload here would drop unsaved wikitext or re-POST a preview, so any live
	// editing surface vetoes it. CSS hot-swapping stays safe and continues.
	function editingInProgress() {
		if ( document.getElementById( 'wpTextbox1' ) ) {
			return true;
		}

		var params = new URLSearchParams( window.location.search );
		var action = params.get( 'action' );
		if ( action === 'edit' || action === 'submit' || params.get( 'veaction' ) ) {
			return true;
		}

		// Catch-all for editing surfaces that are neither (Special:ExpandTemplates,
		// reply boxes, gadget editors). Erring toward "do not reload" is cheap:
		// stylesheet changes still land, and a manual refresh is always available.
		var textareas = document.getElementsByTagName( 'textarea' );
		for ( var i = 0; i < textareas.length; i++ ) {
			if ( textareas[ i ].value !== '' ) {
				return true;
			}
		}

		return false;
	}

	function bust( href ) {
		var url = new URL( href, window.location.href );
		url.searchParams.set( BUST_PARAM, String( lastBuildId ) );
		return url.href;
	}

	// Swap every load.php stylesheet for a freshly-fetched copy instead of
	// reloading: keeps scroll position, open dialogs and edit-form state intact.
	function swapStyles() {
		var links = document.querySelectorAll( 'link[rel="stylesheet"]' );
		var swapped = 0;

		Array.prototype.forEach.call( links, function ( link ) {
			if ( link.href.indexOf( 'only=styles' ) === -1 ) {
				return;
			}
			swapped++;

			var fresh = link.cloneNode( false );
			fresh.href = bust( link.href );
			// Drop the stale sheet only once the new one is live, so the page is
			// never briefly unstyled. On failure drop the new one instead.
			fresh.addEventListener( 'load', function () {
				link.parentNode.removeChild( link );
			} );
			fresh.addEventListener( 'error', function () {
				fresh.parentNode.removeChild( fresh );
			} );
			link.parentNode.insertBefore( fresh, link.nextSibling );
		} );

		log( swapped > 0 ? 'css updated' : 'css rebuilt, but no load.php stylesheet found' );
	}

	function applyReload() {
		if ( editingInProgress() ) {
			reloadPending = true;
			if ( !warnedSuppressed ) {
				warnedSuppressed = true;
				log( 'js rebuilt — reload held back while editing; refresh manually to pick it up' );
			}
			return;
		}
		reloadPending = false;
		window.location.reload();
	}

	function onResult( data ) {
		if ( !data || typeof data.buildId !== 'number' ) {
			return;
		}

		if ( lastBuildId === null ) {
			lastBuildId = data.buildId;
			return;
		}

		if ( data.buildId !== lastBuildId ) {
			lastBuildId = data.buildId;
			if ( data.css ) {
				swapStyles();
			}
			if ( data.js ) {
				applyReload();
				return;
			}
		}

		// The editor may have closed since a suppressed reload — retry.
		if ( reloadPending ) {
			applyReload();
		}
	}

	function check() {
		fetch( CHECK_PATH, { cache: 'no-store' } )
			.then( function ( response ) {
				return response.ok ? response.json() : null;
			} )
			.then( onResult )
			.catch( function () {
				// Proxy stopped or offline — keep polling, it may come back.
			} );
	}

	setInterval( check, POLL_MS );
	check();
}() );
