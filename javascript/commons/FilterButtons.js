/*******************************************************************************
 Template(s): Filter buttons
 Author(s): Elysienna
 *******************************************************************************/
/**
 * Usage of module:
 *
 * Filter buttons:
 * <span data-filter data-filter-effect="fade" data-filter-group="group1">
 *   <span data-filter-on="all">All</span>
 *   <span data-filter-on="cat1" class="filter-button--active">Category 1</span>
 *   <span data-filter-on="cat2">Category 2</span>
 * </span>
 *
 * - data-filter (required): property on the container to group the buttons within into the given group
 * - data-filter-group (encouraged): a unique identifier given to this group, to be used later on the items so the controls know which items to filter.
 *     Note: this attribute is technically not required as long as one instance of the module is being used.
 *           When using multiple on a single page, ALWAYS use this attribute to distinguish between button/item groups
 * - data-filter-effect (optional): options are [fade,bounce,none]. When omitted, no effect is used.
 * - data-filter-on (required): clicking this element will toggle the items with the passed category
 *     (matching on data-filter-category on the items). Can also be 'all' to toggle all items.
 * Note: the class 'filter-button--active' may be given to pre-filter items on load.
 *
 * Filterable items:
 * <span data-filter-group="group1" data-filter-category="cat1">cat1</span>
 * <span data-filter-group="group1" data-filter-category="cat2">cat2</span>
 *
 * - data-filter-group (encouraged): group identifier for which the button group can interact with the item.
 *     Note: See data-filter-group in Filter buttons above as to why it is encouraged to always provide.
 * - data-filter-category (required): identifier for 'data-filter-on'
 *
 */

liquipedia.filterButtons = {
	fallbackFilterEffect: 'none',
	activeButtonClass: 'filter-button--active',
	hiddenCategoryClass: 'filter-category--hidden',
	fallbackFilterGroup: 'filter-group-fallback-common',

	filterGroups: {},

	init: function() {
		this.localStorageKey = this.buildLocalStorageKey();

		const localStorage = this.getLocalStorage();

		const filterGroups = {};

		document.querySelectorAll( '.filter-buttons[data-filter]' ).forEach( ( /** @type HTMLElement */ buttonsDiv ) => {
			const filterGroup = buttonsDiv.dataset.filterGroup || this.fallbackFilterGroup;
			const filterStates = ( localStorage[ filterGroup ] || {} ).filterStates || {};
			const alwaysActiveFilters = buttonsDiv.dataset.filterAlwaysActive;
			const buttons = [];
			let allButton;
			buttonsDiv.querySelectorAll( ':scope > .filter-button' ).forEach( ( /** @type HTMLElement */ buttonElement ) => {
				const filterOn = buttonElement.dataset.filterOn || '';
				const button = {
					element: buttonElement,
					filter: filterOn,
					active: true,
				};
				if ( filterOn === 'all' ) {
					allButton = button;
				} else {
					buttons[ filterOn ] = button;
					filterStates[ filterOn ] = filterStates[ filterOn ] || true;
				}
				buttonElement.setAttribute( 'tabindex', '0' );
			} );

			filterGroups[ filterGroup ] = {
				name: filterGroup,
				effect: buttonsDiv.dataset.filterEffect || this.fallbackFilterEffect,
				buttons: buttons,
				allButton: allButton,
				alwaysActive: ( typeof alwaysActiveFilters === 'string' ) ? alwaysActiveFilters.split( ',' ) : [],
				filterStates: filterStates,
				filterableItems: [],
			};
		}, this );

		document.querySelectorAll( '[data-filter-category]' ).forEach( ( /** @type HTMLElement */ filterableItem ) => {
			const filterGroup = filterGroups[ filterableItem.dataset.filterGroup || this.fallbackFilterGroup ];
			filterableItem.classList.add( 'filter-effect-' + filterGroup.effect );
			filterGroup.filterableItems.push( {
				element: filterableItem,
				value: filterableItem.dataset.filterCategory,
				hidden: false,
			} );
		}, this );

		this.filterGroups = filterGroups;
		this.initalizeButtons();
		this.performUpdate();
	},

	performUpdate: function() {
		this.updateFromFilterStates();
		this.setLocalStorage();
		this.updateDOM();
	},

	initalizeButtons: function() {
		const handleClick = function( button, filterGroup, event ) {
			if ( ( event.type === 'click' ) || ( event.type === 'keypress' && event.key === 'Enter' ) ) {
				liquipedia.tracker.track( 'Filter button clicked: ' + button.element.textContent, true );
				if ( button.filter === 'all' ) {
					Object.entries( filterGroup.filterStates ).forEach( ( [ filterState ] ) => {
						if ( !filterGroup.alwaysActive.includes( filterState ) ) {
							filterGroup.filterStates[ filterState ] = !button.active;
						}
					} );
				} else {
					filterGroup.filterStates[ button.filter ] = !button.active;
				}
				this.performUpdate();
			}
		};

		Object.values( this.filterGroups ).forEach( filterGroup => {

			Object.values( filterGroup.buttons ).forEach( button => {
				button.element.addEventListener( 'click', handleClick.bind( this, button, filterGroup ) );
				button.element.addEventListener( 'keypress', handleClick.bind( this, button, filterGroup ) );
			} );

			filterGroup.allButton.element.addEventListener( 'click', handleClick.bind( this, filterGroup.allButton, filterGroup ) );
			filterGroup.allButton.element.addEventListener( 'keypress', handleClick.bind( this, filterGroup.allButton, filterGroup ) );

		} );
	},

	updateFromFilterStates: function() {
		Object.values( this.filterGroups ).forEach( filterGroup => {

			let allState = true;
			Object.values( filterGroup.buttons ).forEach( button => {
				button.active = filterGroup.filterStates[ button.filter ];
				allState = allState && button.active;
			} );

			filterGroup.allButton.active = allState;

			filterGroup.filterableItems.forEach( filterableItem => {
				filterableItem.hidden = !filterGroup.filterStates[ filterableItem.value ];
			} );

		} );
	},

	updateDOM: function() {
		Object.values( this.filterGroups ).forEach( filterGroup => {

			filterGroup.allButton.active ? filterGroup.allButton.element.classList.add( this.activeButtonClass ) : filterGroup.allButton.element.classList.remove( this.activeButtonClass );

			Object.values( filterGroup.buttons ).forEach( button => {
				if ( button.active ) {
					button.element.classList.add( this.activeButtonClass );
				} else {
					button.element.classList.remove( this.activeButtonClass );
				}
			}, this );

			filterGroup.filterableItems.forEach( filterableItem => {
				if ( filterableItem.hidden ) {
					filterableItem.element.classList.add( this.hiddenCategoryClass );
				} else {
					filterableItem.element.classList.remove( this.hiddenCategoryClass );
				}
			}, this );

		}, this );
	},

	buildLocalStorageKey: function() {
		const base = 'LiquipediaFilterButtonsV2';
		const scriptPath = mw.config.get( 'wgScriptPath' ).replace( /[\W]/g, '' );
		const pageName = mw.config.get( 'wgPageName' );

		return base + '-' + scriptPath + '-' + pageName;
	},

	getLocalStorage: function() {
		const check = window.localStorage.getItem( this.localStorageKey );
		return check ? JSON.parse( check ) : {};
	},

	setLocalStorage: function() {
		const filterGroups = {};
		Object.values( this.filterGroups ).forEach( filterGroup => {
			filterGroups[ filterGroup.name ] = { filterStates: filterGroup.filterStates };
		} );
		window.localStorage.setItem( this.localStorageKey, JSON.stringify( filterGroups ) );
	},
};

liquipedia.core.modules.push( 'filterButtons' );
