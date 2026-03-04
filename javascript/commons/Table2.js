/*******************************************************************************
 * Description: Handles dynamic striping for Table2 widgets,
 *              applying odd/even classes with rowspan grouping support.
 ******************************************************************************/

const TABLE2_CONFIG = {
	SELECTORS: {
		TABLE: '.table2__table',
		BODY_ROW: 'tbody tr.table2__row--body',
		ALL_ROWS: 'tbody tr'
	},
	CLASSES: {
		EVEN: 'table2__row--even',
		HEAD: 'table2__row--head'
	}
};

class Table2Striper {
	constructor( table ) {
		this.table = table;
		this.isSortable = table.classList.contains( 'sortable' );
		this.shouldStripe = table.getAttribute( 'data-striped' ) !== 'false';
	}

	init() {
		if ( this.shouldStripe ) {
			this.restripe();

			if ( this.isSortable ) {
				this.setupSortListener();
			}
		}
	}

	setupSortListener() {
		mw.loader.using( 'jquery.tablesorter' ).then( () => {
			$( this.table ).on( 'sortEnd.tablesorter', () => this.restripe() );
		} );
	}

	restripe() {
		const rows = this.table.querySelectorAll( TABLE2_CONFIG.SELECTORS.ALL_ROWS );
		let isEven = true;
		let groupRemaining = 0;

		rows.forEach( ( row ) => {
			const isBodyRow = row.classList.contains( 'table2__row--body' );
			const isSubheader = row.classList.contains( TABLE2_CONFIG.CLASSES.HEAD );

			if ( isSubheader ) {
				isEven = true;
				groupRemaining = 0;
				return;
			}

			if ( !isBodyRow || row.style.display === 'none' ) {
				return;
			}

			if ( groupRemaining === 0 ) {
				isEven = !isEven;
			}

			const rowspanCount = parseInt( row.dataset.rowspanCount, 10 ) || 1;
			groupRemaining = Math.max( groupRemaining, rowspanCount );

			row.classList.toggle( TABLE2_CONFIG.CLASSES.EVEN, isEven );

			groupRemaining--;
		} );
	}
}

class Table2Module {
	init() {
		const tables = document.querySelectorAll( TABLE2_CONFIG.SELECTORS.TABLE );

		tables.forEach( ( table ) => {
			new Table2Striper( table ).init();
		} );
	}
}

liquipedia.table2 = new Table2Module();
liquipedia.core.modules.push( 'table2' );
