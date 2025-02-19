liquipedia.rankingTable = {
	identifierAttribute: 'data-ranking-table-id',
	contentSelector: '[data-ranking-table="content"]',
	toggleButtonSelector: '[data-ranking-table="toggle"]',
	graphRowSelector: '[data-ranking-table="graph-row"]',
	selectContainerSelector: '[data-ranking-table="select-container"]',
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

			this.populateOptions();
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
			this.cache[ this.activeSelectOption.value ] = this.rankingContent.innerHTML;
		} );
	},

	populateOptions: function () {
		document.querySelectorAll( this.optionDataSelector ).forEach( ( option ) => {
			const date = new Date( option.getAttribute( 'data-date' ) );
			const patch = option.getAttribute( 'data-name' );
			const value = this.standardizeDateFormat( date );
			const text = date.toLocaleDateString( 'en-US', { year: 'numeric', month: 'long', day: 'numeric' } );
			this.options.push( {
				value: value,
				text: text,
				patch: patch
			} );
		} );
	},

	fetchRatingsData: function( date ) {
		const dateValue = this.standardizeDateFormat( new Date( date ) );

		// Check if data is already fetched
		if ( this.cache[ dateValue ] ) {
			this.removeToggleButtonListeners();
			this.rankingContent.innerHTML = this.cache[ dateValue ];
			this.toggleGraphVisibility();
			mw.ext.Charts.recreateCharts();
			return;
		}

		const wikiText =
			`{{#invoke:Lua|invoke|module=Widget/Factory|fn=fromTemplate|widget=Ratings|teamLimit=20|
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
				// Insert fetched HTML content
				this.rankingContent.insertAdjacentHTML( 'beforeend', data.parse.text[ '*' ] );
				// Remove the original list
				this.rankingContent.firstElementChild.remove();
				// Remove non-list elements
				this.rankingContent.innerHTML = this.rankingContent.querySelector( this.contentSelector ).innerHTML;
				// Store fetched HTML content in cache
				this.cache[ dateValue ] = this.rankingContent.outerHTML;
				this.toggleGraphVisibility();
				mw.ext.Charts.recreateCharts();
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
			let chartInstance = echarts.getInstanceByDom( chart );
			if ( chartInstance ) {
				chartInstance.resize();
			} else {
				// Initialize the chart if it is not already initialized
				chartInstance = echarts.init( chart );
			}
		} );
	},

	standardizeDateFormat: function ( date ) {
		return date.toISOString().slice( 0, 10 );
	}
};

liquipedia.core.modules.push( 'rankingTable' );
