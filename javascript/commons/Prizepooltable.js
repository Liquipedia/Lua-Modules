/*******************************************************************************
 * Template(s): Prize pool tables
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.prizepooltable = {
	init: function() {
		document.querySelectorAll( '.prizepooltable' ).forEach( function( prizepooltable ) {
			let cutAfter;
			if ( typeof prizepooltable.dataset.cutafter !== 'undefined' ) {
				cutAfter = parseInt( prizepooltable.dataset.cutafter );
			} else {
				cutAfter = 5;
			}
			prizepooltable.dataset.definedcutafter = cutAfter + 2;
			const numRows = prizepooltable.querySelectorAll( 'tr' ).length;
			let openText = 'place ' + ( cutAfter + 1 ) + ' to ' + ( numRows - 1 );
			if ( typeof prizepooltable.dataset.opentext !== 'undefined' ) {
				openText = prizepooltable.dataset.opentext;
			}
			openText += ' <i class="fa fa-chevron-down"></i>';
			let closeText = 'place ' + ( cutAfter + 1 ) + ' to ' + ( numRows - 1 );
			if ( typeof prizepooltable.dataset.closetext !== 'undefined' ) {
				closeText = prizepooltable.dataset.closetext;
			}
			closeText += ' <i class="fa fa-chevron-up"></i>';
			if ( numRows > cutAfter ) {
				const row = prizepooltable.querySelector( 'tr:nth-child(' + ( cutAfter + 2 ) + ')' );
				if ( row !== null ) {
					const rowNode = document.createElement( 'tr' );
					rowNode.innerHTML = '<td colspan="' + Math.max( prizepooltable.querySelectorAll( 'tr:nth-child(1) th, tr:nth-child(1) td' ).length, prizepooltable.querySelectorAll( 'tr:nth-child(2) th, tr:nth-child(2) td' ).length ) + '" class="prizepooltabletoggle"><small class="prizepooltableshow">' + openText + '</small><small class="prizepooltablehide">' + closeText + '</small></td>';
					row.parentNode.insertBefore( rowNode, row );
				}
			}
		} );
		document.querySelectorAll( '.prizepooltabletoggle' ).forEach( function( prizepooltabletogglebutton ) {
			prizepooltabletogglebutton.onclick = function() {
				this.closest( '.prizepooltable' ).classList.toggle( 'collapsed' );
			};
		} );
	}
};
liquipedia.core.modules.push( 'prizepooltable' );
