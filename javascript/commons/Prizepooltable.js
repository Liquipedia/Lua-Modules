/*******************************************************************************
 * Template(s): Prize pool tables
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.prizepooltable = {
	init: function() {
		document.querySelectorAll( '.prizepooltable' ).forEach( ( prizepooltable ) => {
			// The redesigned (Table2) prize pool wraps its table in
			// `.prizepool-table-wrapper` and collapses via general-collapsible, so it
			// supplies its own toggle. Skip it here to avoid a duplicate legacy toggle.
			if ( prizepooltable.closest( '.prizepool-table-wrapper' ) !== null ) {
				return;
			}
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
					const cellNode = document.createElement( 'td' );
					cellNode.setAttribute( 'colspan', Math.max(
						prizepooltable.querySelectorAll( 'tr:nth-child(1) th, tr:nth-child(1) td' ).length,
						prizepooltable.querySelectorAll( 'tr:nth-child(2) th, tr:nth-child(2) td' ).length )
					);
					cellNode.classList.add( 'prizepooltabletoggle' );

					const showNode = document.createElement( 'small' );
					showNode.classList.add( 'prizepooltableshow' );
					showNode.innerHTML = openText;

					const closeNode = document.createElement( 'small' );
					closeNode.classList.add( 'prizepooltablehide' );
					closeNode.innerHTML = closeText;

					cellNode.append( showNode, closeNode );
					rowNode.appendChild( cellNode );
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
