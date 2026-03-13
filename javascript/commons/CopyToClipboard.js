/*******************************************************************************
 * Template(s): Copy to clipboard
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.copytoclipboard = {
	init: function() {
		document.querySelectorAll( '.copy-to-clipboard' ).forEach( ( copy ) => {
			const button = copy.querySelector( '.see-this' );
			if ( button !== null ) {
				button.addEventListener( 'click', liquipedia.copytoclipboard.buttonEventListener );
			}
		} );
	},
	buttonEventListener: async function( e ) {
		const parent = e.target.closest( '.copy-to-clipboard' );
		const text = parent.querySelector( '.copy-this' );
		if ( text !== null ) {
			if ( !navigator.clipboard || !navigator.clipboard.writeText ) {
				mw.notify( 'This browser does not support copying text to the clipboard.', { type: 'error' } );
				return;
			}
			const rawText = text.textContent;
			await navigator.clipboard.writeText( rawText );
			liquipedia.copytoclipboard.showNotification( parent );
		}
	},
	showNotification: function( copy ) {
		const timeout = 2000;
		let text = 'Copied...';
		if ( typeof copy.dataset.copiedText !== 'undefined' && copy.dataset.copiedText.trim() !== '' ) {
			text = copy.dataset.copiedText.trim();
		}
		const $copy = $( copy );
		$copy.tooltip( {
			title: text,
			trigger: 'manual'
		} );
		$copy.tooltip( 'show' );
		window.setTimeout( () => {
			$copy.tooltip( 'hide' );
		}, timeout );
	}
};
liquipedia.core.modules.push( 'copytoclipboard' );
