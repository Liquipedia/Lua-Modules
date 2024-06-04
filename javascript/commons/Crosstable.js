/*******************************************************************************
 * Template(s): All Crosstables
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.crosstable = {
	init: function() {
		document.querySelectorAll( '.crosstable' ).forEach( ( crosstable ) => {
			crosstable.querySelectorAll( 'td, th' ).forEach( ( cell ) => {
				cell.onmouseover = function() {
					const row = this.closest( 'tr' );
					crosstable.classList.add( 'crosstable-row-' + ( row.rowIndex + 1 ) );
					crosstable.classList.add( 'crosstable-col-' + ( this.cellIndex + 1 ) );
					let element;
					element = crosstable.querySelector( 'tr:nth-child(' + row.rowIndex + ') td:nth-child(' + this.cellIndex + ')' );
					if ( element !== null ) {
						element.classList.add( 'crosstable-top-left' );
					}
					element = crosstable.querySelector( 'tr:nth-child(' + row.rowIndex + ') td:nth-child(' + ( this.cellIndex + 2 ) + ')' );
					if ( element !== null ) {
						element.classList.add( 'crosstable-top-right' );
					}
					element = crosstable.querySelector( 'tr:nth-child(' + ( row.rowIndex + 2 ) + ') td:nth-child(' + this.cellIndex + ')' );
					if ( element !== null ) {
						element.classList.add( 'crosstable-bottom-left' );
					}
					element = crosstable.querySelector( 'tr:nth-child(' + ( row.rowIndex + 2 ) + ') td:nth-child(' + ( this.cellIndex + 2 ) + ')' );
					if ( element !== null ) {
						element.classList.add( 'crosstable-bottom-right' );
					}

				};
				cell.onmouseleave = function() {
					const row = this.closest( 'tr' );
					crosstable.classList.remove( 'crosstable-row-' + ( row.rowIndex + 1 ) );
					crosstable.classList.remove( 'crosstable-col-' + ( this.cellIndex + 1 ) );
					let element;
					element = crosstable.querySelector( 'tr:nth-child(' + row.rowIndex + ') td:nth-child(' + this.cellIndex + ')' );
					if ( element !== null ) {
						element.classList.remove( 'crosstable-top-left' );
					}
					element = crosstable.querySelector( 'tr:nth-child(' + row.rowIndex + ') td:nth-child(' + ( this.cellIndex + 2 ) + ')' );
					if ( element !== null ) {
						element.classList.remove( 'crosstable-top-right' );
					}
					element = crosstable.querySelector( 'tr:nth-child(' + ( row.rowIndex + 2 ) + ') td:nth-child(' + this.cellIndex + ')' );
					if ( element !== null ) {
						element.classList.remove( 'crosstable-bottom-left' );
					}
					element = crosstable.querySelector( 'tr:nth-child(' + ( row.rowIndex + 2 ) + ') td:nth-child(' + ( this.cellIndex + 2 ) + ')' );
					if ( element !== null ) {
						element.classList.remove( 'crosstable-bottom-right' );
					}
				};
			} );
		} );
	}
};
liquipedia.core.modules.push( 'crosstable' );
