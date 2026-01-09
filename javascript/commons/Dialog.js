/*******************************************************************************
 * Template(s): Dialog (popup)
 ******************************************************************************/
liquipedia.dialog = {
	init: function() {
		const $dialog = $( '<div>' ).dialog( {
			autoOpen: false
		} );
		document.querySelectorAll( '#mw-content-text .general-dialog' ).forEach( ( dialog ) => {
			const $dialogTrigger = dialog.querySelector( '.general-dialog-trigger' );
			const $dialogContent = dialog.querySelector( '.general-dialog-wrapper' );

			if ( $dialogTrigger ) {
				if ( $dialogContent ) {
					const $dialogChildren = $( '<div>' ).addClass( dialog.getAttribute( 'dialog-classes' ) );
					$dialogContent.childNodes.forEach( ( child ) => {
						$dialogChildren.append( child );
					} );
					$dialogTrigger.on( 'click', ( e ) => {
						$dialog.dialog(
							'close'
						).html( $dialogChildren ).dialog(
							'option', 'position', [ e.clientX + 5, e.clientY + 5 ]
						).dialog( 'open' );
					} );
				}
			}
		} );
	}
};
liquipedia.core.modules.push( 'dialog' );
