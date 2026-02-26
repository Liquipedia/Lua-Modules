liquipedia.rankingTable = {
	identifierAttribute: 'data-ranking-table-id',
	contentSelector: '[data-ranking-table="content"]',
	toggleButtonSelector: '[data-ranking-table="toggle"]',
	graphRowSelector: '[data-ranking-table="graph-row"]',
	patchLabelSelector: '[data-ranking-table="patch-label"]',
	optionDataSelector: '[data-ranking-table="select-data"]',
	patchLabelElement: null,
	activeSelectOption: null,
	rankingTable: null,
	rankingContent: null,
	cache: {},
	toggleButtonListeners: [],
	options: [],

	init: function () {
		mw.loader.using( 'ext.Charts.scripts', () => {
			this.rankingContent = document.querySelector( this.contentSelector );
			if ( !this.rankingContent ) {
				return;
			}

			this.toggleGraphVisibility();
		} );
	},

	removeToggleButtonListeners: function () {
		this.toggleButtonListeners.forEach( ( { button, listener } ) => {
			button.removeEventListener( 'click', listener );
		} );
		this.toggleButtonListeners = [];
	},

	toggleGraphVisibility: function () {
		const toggleButtons = document.querySelectorAll( this.toggleButtonSelector );
		toggleButtons.forEach( ( button ) => {
			const listener = () => this.onToggleButtonClick( button );
			button.addEventListener( 'click', listener );
			this.toggleButtonListeners.push( { button, listener } );
		} );
	},

	onToggleButtonClick: function ( button ) {
		const graphRowId = button.getAttribute( this.identifierAttribute );
		const graphRow = document.querySelector(
			`${ this.graphRowSelector }[${ this.identifierAttribute }="${ graphRowId }"]`
		);

		if ( graphRow ) {
			graphRow.classList.toggle( 'd-none' );
			const isExpanded = button.getAttribute( 'aria-expanded' ) === 'true';
			button.setAttribute( 'aria-expanded', String( !isExpanded ) );

			if ( !graphRow.classList.contains( 'd-none' ) ) {
				// Initialize or resize charts when the div is visible
				this.resizeCharts( graphRow );
			}
		}
	},

	resizeCharts: function ( graphRow ) {
		const instances = graphRow.querySelectorAll( '[_echarts_instance_]' );
		instances.forEach( ( chart ) => {
			let chartInstance = echarts.getInstanceByDom( chart );
			if ( chartInstance ) {
				chartInstance.resize();
			} else {
				// Initialize the chart if it is not already initialized
				chartInstance = echarts.init( chart );
			}
		} );
	}
};

liquipedia.core.modules.push( 'rankingTable' );
