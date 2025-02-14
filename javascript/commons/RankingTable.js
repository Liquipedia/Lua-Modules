liquipedia.rankingTable = {
	identifierAttribute: 'data-ranking-table-id',
	toggleButtonSelector: '[data-ranking-table="toggle"]',
	graphRowSelector: '[data-ranking-table="graph-row"]',
	selectContainerSelector: '[data-ranking-table="select-container"]',
	patchLabelSelector: '[data-ranking-table="patch-label"]',
	patchLabelElement: null,
	activeSelectOption: null,
	// temp test data
	options: [
		{
			value: 'option1',
			text: 'April 22, 2024',
			patch: 'Patch 1.2.3'
		},
		{
			value: 'option2',
			text: 'April 15, 2024',
			patch: 'Patch 1.2.2'
		},
		{
			value: 'option3',
			text: 'April 08, 2024',
			patch: 'Patch 1.2.1'
		}
	],

	init: function () {
		this.toggleGraphVisibility();
		this.initSelectElement();

		// set active select option to the first option object on init
		if ( this.activeSelectOption === null && this.options.length > 0 ) {
			this.activeSelectOption = this.options[ 0 ];
		}

		// set patch label to the active select option patch
		this.patchLabelElement = document.querySelector( this.patchLabelSelector );
		if ( this.patchLabelElement && this.activeSelectOption !== null ) {
			this.updatePatchLabel( this.activeSelectOption.patch );
		}
	},

	fetchRatingsData: function( week ) {
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
			text: `{{RatingsList|week=${ week }}}`
		} ).done( ( data ) => {
			if ( data.parse?.text?.[ '*' ] ) {
				this.updateRatingListTable( data.parse.text[ '*' ] );
			}
		} );
	},

	updateRatingListTable: function ( htmlContent ) {
		const ratingsListTable = document.getElementById( 'ratingsListTable' );
		if ( ratingsListTable ) {
			ratingsListTable.outerHTML = htmlContent;
		}
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
			button.addEventListener( 'click', () => this.onToggleButtonClick( button ) );
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
		graphRow.querySelectorAll( '[_echarts_instance_]' ).forEach( ( chart ) => {
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
