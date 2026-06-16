/*******************************************************************************
 * Template(s): Prize pool tables
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.prizepooltable = {
	init: function() {
		document.querySelectorAll( '.prizepooltable' ).forEach( ( prizepooltable ) => {
			if ( prizepooltable.querySelector( '.prizepooltabletoggle' ) !== null ) {
				return;
			}
			// Class-based collapse (prize pool): Lua marks the cut rows with
			// `ppt-hide-on-collapse`; the toggle goes directly before the first one.
			const firstHiddenRow = prizepooltable.querySelector( '.ppt-hide-on-collapse' );
			if ( firstHiddenRow !== null ) {
				let openLabel = 'show more';
				if ( typeof prizepooltable.dataset.opentext !== 'undefined' ) {
					openLabel = prizepooltable.dataset.opentext;
				}
				openLabel += ' <i class="fa fa-chevron-down"></i>';
				let closeLabel = 'show less';
				if ( typeof prizepooltable.dataset.closetext !== 'undefined' ) {
					closeLabel = prizepooltable.dataset.closetext;
				}
				closeLabel += ' <i class="fa fa-chevron-up"></i>';
				const colspan = prizepooltable.querySelectorAll( 'tr:nth-child(1) th, tr:nth-child(1) td' ).length;
				const rowNode = document.createElement( 'tr' );
				rowNode.innerHTML = '<td colspan="' + colspan + '" class="prizepooltabletoggle"><small class="prizepooltableshow">' + openLabel + '</small><small class="prizepooltablehide">' + closeLabel + '</small></td>';
				firstHiddenRow.parentNode.insertBefore( rowNode, firstHiddenRow );
				return;
			}
			// Legacy data-cutafter collapse (mvp / medal / winnings tables).
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
		document.querySelectorAll( '.prizepooltabletoggle' ).forEach( ( prizepooltabletogglebutton ) => {
			prizepooltabletogglebutton.onclick = function() {
				this.closest( '.prizepooltable' ).classList.toggle( 'collapsed' );
			};
		} );
	}
};
liquipedia.core.modules.push( 'prizepooltable' );
