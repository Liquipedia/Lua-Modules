liquipedia.rankingTable = {
	identifierAttribute: 'data-ranking-table-id',
	ContentSelector: '[data-ranking-table="content"]',
	toggleButtonSelector: '[data-ranking-table="toggle"]',
	graphRowSelector: '[data-ranking-table="graph-row"]',
	selectContainerSelector: '[data-ranking-table="select-container"]',
	patchLabelSelector: '[data-ranking-table="patch-label"]',
	patchLabelElement: null,
	activeSelectOption: null,
	rankingTable: null,
	rankingContent: null,
	cache: {},
	toggleButtonListeners: [],
	// temp test data
	options: [
		{
			value: '2023-10-31',
			text: 'October 31, 2023',
			patch: 'Patch 1.2.3'
		},
		{
			value: '2023-10-24',
			text: 'October 24, 2023',
			patch: 'Patch 1.2.2'
		},
		{
			value: '2023-10-17',
			text: 'October 17, 2023',
			patch: 'Patch 1.2.1'
		}
	],

	init: function () {
		this.rankingContent = document.querySelector( this.ContentSelector );
		if ( !this.rankingContent ) {
			return;
		}

		this.toggleGraphVisibility();
		this.initSelectElement();

		// Set active select option to the first option object on init
		if ( this.activeSelectOption === null && this.options.length > 0 ) {
			this.activeSelectOption = this.options[ 0 ];
		}

		// Set patch label to the active select option patch
		this.patchLabelElement = document.querySelector( this.patchLabelSelector );
		if ( this.patchLabelElement && this.activeSelectOption !== null ) {
			this.updatePatchLabel( this.activeSelectOption.patch );
		}

		// Store initial HTML content in cache
		this.cache[ this.activeSelectOption.value ] = this.rankingContent.outerHTML;
	},

	fetchRatingsData: function( date ) {
		// Check if data is already fetched
		if ( this.cache[ date ] ) {
			this.removeToggleButtonListeners();
			this.rankingContent.outerHTML = this.cache[ date ];
			this.toggleGraphVisibility();
			return;
		}

		// Convert string to date format, don't know if this is needed
		const dateValue = new Date( date ).toISOString().slice( 0, 10 );

		const wikiText =
			`{{#invoke:Lua|invoke|module=Widget/Factory|fn=fromTemplate|widget=Ratings/List|teamLimit=20|
			progressionLimit=12|date=${ dateValue }|storageType=extension}}`;
		const api = new mw.Api();
		api.get( {
			action: 'parse',
			format: 'json',
			contentmodel: 'wikitext',
			maxage: 600,
			smaxage: 600,
			disablelimitreport: true,
			uselang: 'content',
			prop: 'text',
			text: wikiText
		} ).done( ( data ) => {
			if ( data.parse?.text?.[ '*' ] ) {
				this.removeToggleButtonListeners();
				this.rankingContent.outerHTML = data.parse.text[ '*' ];
				// Store fetched HTML content in cache
				this.cache[ date ] = data.parse.text[ '*' ];
				this.toggleGraphVisibility();
			}
		} );
	},

	removeToggleButtonListeners: function () {
		this.toggleButtonListeners.forEach( ( { button, listener } ) => {
			button.removeEventListener( 'click', listener );
		} );
		this.toggleButtonListeners = [];
	},

	updatePatchLabel: function ( patch ) {
		if ( !this.patchLabelElement ) {
			this.patchLabelElement = document.querySelector( this.patchLabelSelector );
		}
		this.patchLabelElement.innerText = patch;
	},

	initSelectElement: function () {
		const selectContainer = document.querySelector( this.selectContainerSelector );

		if ( !selectContainer ) {
			return;
		}

		const selectElement = this.createSelectElement();
		const optionElements = this.createOptions();

		selectElement.append( ...optionElements );
		selectContainer.insertBefore( selectElement, selectContainer.firstChild );

		// Add change event listener to update activeSelectOption and patch label
		selectElement.addEventListener( 'change', this.onSelectChange.bind( this ) );
	},

	onSelectChange: function ( event ) {
		const selectedOption = this.options.find( ( option ) => option.value === event.target.value );
		if ( selectedOption ) {
			this.activeSelectOption = selectedOption;
			this.updatePatchLabel( selectedOption.patch );
			this.fetchRatingsData( selectedOption.value );
		}
	},

	createSelectElement: function () {
		const selectElement = document.createElement( 'select' );
		selectElement.ariaLabel = 'Select a week';
		selectElement.classList.add( 'ranking-table__select' );
		return selectElement;
	},

	createOptions: function () {
		const optionsElements = [];

		this.options.forEach( ( option ) => {
			const optionElement = document.createElement( 'option' );
			optionElement.value = option.value;
			optionElement.innerText = option.text;
			optionsElements.push( optionElement );
		} );

		return optionsElements;
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
			// echarts is a global variable which eslint doesn't understand
			/* eslint-disable-next-line no-undef */
			let chartInstance = echarts.getInstanceByDom( chart );
			if ( chartInstance ) {
				chartInstance.resize();
			} else {
				// Initialize the chart if it is not already initialized
				/* eslint-disable-next-line no-undef */
				chartInstance = echarts.init( chart );
			}
		} );
	}
};

liquipedia.core.modules.push( 'rankingTable' );
