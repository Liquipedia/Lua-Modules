/*******************************************************************************
 * Template(s): Dismissable Network Notice
 * Author(s): FO-nTTaX
 * TODO: Use mw.storage interface instead of directly polling
 * window.localStorage, browser-support is there now.
 ******************************************************************************/
liquipedia.sitenotice = {
	init: function() {
		if ( 'localStorage' in window ) {
			document.querySelectorAll( '.networknotice' ).forEach( function( notice ) {
				const key = notice.dataset.id;
				if ( liquipedia.sitenotice.isInStorage( key ) ) {
					notice.style.display = 'none';
				} else {
					const closeButton = document.createElement( 'div' );
					closeButton.setAttribute( 'style', 'cursor:pointer;font-size:12px;border:1px solid #333333;line-height:12px;padding:4px 5px;position:absolute;top:4px;right:4px;' );
					closeButton.setAttribute( 'title', 'Close Notice' );
					closeButton.innerHTML = '<i class="fa fa-times" aria-hidden="true"></i>';
					closeButton.onclick = function() {
						notice.style.display = 'none';
						liquipedia.sitenotice.putIntoStorage( key );
					};
					notice.insertBefore( closeButton, notice.firstChild );
				}
			} );
		}
	},
	putIntoStorage: function( key ) {
		let items = localStorage.getItem( liquipedia.sitenotice.getLocalStorageKey() );
		if ( items === null || items === '' ) {
			items = [ ];
		} else {
			items = JSON.parse( items );
		}
		if ( !items.includes( key ) ) {
			items.push( key );
			localStorage.setItem( liquipedia.sitenotice.getLocalStorageKey(), JSON.stringify( items ) );
		}
	},
	isInStorage: function( key ) {
		let items = localStorage.getItem( liquipedia.sitenotice.getLocalStorageKey() );
		if ( items === null || items === '' ) {
			items = [ ];
		} else {
			items = JSON.parse( items );
		}
		return items.includes( key );
	},
	getLocalStorageKey: function() {
		return 'networknotice';
	}
};
liquipedia.core.modules.push( 'sitenotice' );
