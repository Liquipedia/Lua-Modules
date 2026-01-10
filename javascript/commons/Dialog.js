/*******************************************************************************
 * Template(s): General dialog
 ******************************************************************************/
liquipedia.dialog = {
	init: function() {
		mw.loader.using( 'jquery.ui', () => {
			const $dialog = $( '<div>' ).dialog( {
				autoOpen: false,
				dialogClass: 'general-dialog-container',
				resizable: false
			} );
			document.querySelectorAll( '#mw-content-text .general-dialog' ).forEach( ( dialog ) => {
				const dialogTrigger = dialog.querySelector( '.general-dialog-trigger' );
				const dialogTitle = dialog.querySelector( '.general-dialog-title' );
				const dialogContent = dialog.querySelector( '.general-dialog-wrapper' );

				if ( dialogTrigger && dialogTitle && dialogContent ) {
					const $trigger = $( dialogTrigger );

					const $dialogChildren = $( '<div>' ).addClass( dialog.getAttribute( 'dialog-classes' ) );
					dialogContent.childNodes.forEach( ( child ) => {
						$dialogChildren.append( child );
					} );
					$trigger.on( 'click', ( e ) => {
						$dialog.dialog(
							'close'
						).html( $dialogChildren ).dialog(
							'option', {
								'position': [ e.clientX + 5, e.clientY + 5 ],
								'title': dialogTitle.innerHTML.toString()
							}
						).dialog( 'open' );
					} );
				}
			} );
		} );
	}
};
liquipedia.core.modules.push( 'dialog' );
