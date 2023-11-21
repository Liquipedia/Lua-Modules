/*******************************************************************************
 * Template(s): Copy to clipboard
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.copytoclipboard = {
	init: function() {
		document.querySelectorAll( '.copy-to-clipboard' ).forEach( function( copy ) {
			const button = copy.querySelector( '.see-this' );
			if ( button !== null ) {
				button.addEventListener( 'click', liquipedia.copytoclipboard.buttonEventListener );
			}
		} );
	},
	buttonEventListener: function( e ) {
		const parent = e.target.closest( '.copy-to-clipboard' );
		const text = parent.querySelector( '.copy-this' );
		if ( text !== null ) {
			const rawText = text.textContent;
			if ( navigator.clipboard && navigator.clipboard.writeText ) {
				navigator.clipboard.writeText( rawText );
			} else {
				liquipedia.copytoclipboard.createInputBox( parent, rawText );
				liquipedia.copytoclipboard.selectAndCopy();
				liquipedia.copytoclipboard.removeInputBox();
			}
			liquipedia.copytoclipboard.showNotification( parent );
		}
	},
	inputBox: null,
	createInputBox: function( parent, text ) {
		const input = document.createElement( 'input' );
		input.value = text;
		liquipedia.copytoclipboard.inputBox = input;
		parent.appendChild( input );
	},
	removeInputBox: function() {
		const input = liquipedia.copytoclipboard.inputBox;
		liquipedia.copytoclipboard.inputBox = null;
		input.parentNode.removeChild( input );
	},
	selectAndCopy: function() {
		const input = liquipedia.copytoclipboard.inputBox;
		input.focus();
		input.select();
		document.execCommand( 'copy' );
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
		window.setTimeout( function() {
			$copy.tooltip( 'hide' );
		}, timeout );
	}
};
liquipedia.core.modules.push( 'copytoclipboard' );
