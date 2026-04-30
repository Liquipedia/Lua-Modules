/*******************************************************************************
 * Description: Handles dynamic striping for Table2 widgets,
 *              applying odd/even classes with rowspan grouping support.
 ******************************************************************************/

const TABLE2_CONFIG = {
	SELECTORS: {
		TABLE: '.table2 .table2__table',
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
		this.groupCounter = 0;
	}

	init() {
		if ( this.shouldStripe ) {
			this.restripe();

			if ( this.isSortable ) {
				this.setupSortListener();
			}
		}
		this.setupHoverListeners();
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
		this.groupCounter = 0;

		rows.forEach( ( row ) => {
			const isBodyRow = row.classList.contains( 'table2__row--body' );
			const isSubheader = row.classList.contains( TABLE2_CONFIG.CLASSES.HEAD );

			if ( isSubheader ) {
				isEven = true;
				groupRemaining = 0;
				row.removeAttribute( 'data-group-id' );
				return;
			}

			if ( !isBodyRow || row.style.display === 'none' ) {
				return;
			}

			if ( groupRemaining === 0 ) {
				isEven = !isEven;
				this.groupCounter++;
			}

			const rowspanCount = parseInt( row.dataset.rowspanCount, 10 ) || 1;
			groupRemaining = Math.max( groupRemaining, rowspanCount );

			row.classList.toggle( TABLE2_CONFIG.CLASSES.EVEN, isEven );
			row.setAttribute( 'data-group-id', this.groupCounter );

			groupRemaining--;
		} );
	}

	setupHoverListeners() {
		const bodyRows = this.table.querySelectorAll( TABLE2_CONFIG.SELECTORS.BODY_ROW );

		bodyRows.forEach( ( row ) => {
			row.addEventListener( 'mouseenter', ( e ) => this.onRowHoverEnter( e ) );
			row.addEventListener( 'mouseleave', ( e ) => this.onRowHoverLeave( e ) );
		} );
	}

	onRowHoverEnter( event ) {
		const row = event.target.closest( TABLE2_CONFIG.SELECTORS.BODY_ROW );
		if ( !row ) {
			return;
		}

		const groupId = row.getAttribute( 'data-group-id' );
		if ( !groupId ) {
			return;
		}

		const groupRows = this.table.querySelectorAll(
			`${ TABLE2_CONFIG.SELECTORS.BODY_ROW }[data-group-id="${ groupId }"]`
		);
		groupRows.forEach( ( r ) => r.classList.add( 'table2__row--group-hover' ) );
	}

	onRowHoverLeave( event ) {
		const row = event.target.closest( TABLE2_CONFIG.SELECTORS.BODY_ROW );
		if ( !row ) {
			return;
		}

		const groupId = row.getAttribute( 'data-group-id' );
		if ( !groupId ) {
			return;
		}

		const groupRows = this.table.querySelectorAll(
			`${ TABLE2_CONFIG.SELECTORS.BODY_ROW }[data-group-id="${ groupId }"]`
		);
		groupRows.forEach( ( r ) => r.classList.remove( 'table2__row--group-hover' ) );
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
