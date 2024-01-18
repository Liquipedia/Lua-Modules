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

	buttonContainerElements: {},
	buttonFilterAll: {},
	filterEffect: {},
	activeButtonClass: 'filter-button--active',
	hiddenCategoryClass: 'filter-category--hidden',
	bcFilterGroup: 'filter-group-fallback-common',
	buttons: {},
	items: {},
	activeFilters: {},
	activeAlwaysFilters: {},
	localStorageKey: null,
	localStorageValue: {},

	init: function() {

		this.localStorageKey = this.buildLocalStorageKey();

		/**
		 * Get all elements with data-filter attribute
		 */
		const elements = document.querySelectorAll( '[data-filter]' );
		if ( elements.length === 0 ) {
			return;
		}

		elements.forEach( function( element ) {
			const filterGroup = element.dataset.filterGroup || this.bcFilterGroup;
			this.buttonContainerElements[ filterGroup ] = element;
			// Start with empty activeFilters
			this.activeFilters[ filterGroup ] = [];

			// Get buttons except for 'all' (direct childs only, this avoids catching the dropdown button
			this.buttons[ filterGroup ] = this.buttonContainerElements[ filterGroup ].querySelectorAll( ':scope > [data-filter-on]:not([data-filter-on=all])' );
			// Get only 'all' button
			this.buttonFilterAll[ filterGroup ] = this.buttonContainerElements[ filterGroup ].querySelector( '[data-filter-on=all]' );
			// Get always active filters
			this.activeAlwaysFilters[ filterGroup ] = [];
			const activeAlwaysFilters = this.buttonContainerElements[ filterGroup ].getAttribute( 'data-filter-always-active' );
			if ( typeof activeAlwaysFilters === 'string' ) {
				activeAlwaysFilters.split( ',' ).forEach( function( alwaysActiveFilter ) {
					this.activeAlwaysFilters[ filterGroup ].push( alwaysActiveFilter );
				}, this );
			}

			let itemQS = '[data-filter-group=' + filterGroup + '][data-filter-category]';
			if ( filterGroup === this.bcFilterGroup ) {
				itemQS = '[data-filter-category]:not([data-filter-group])';
			}
			this.items[ filterGroup ] = document.querySelectorAll( itemQS );
			this.filterEffect[ filterGroup ] = this.buttonContainerElements[ filterGroup ].dataset.filterEffect || 'none';

			// Handler for 'all' button and standard buttons
			this.filterButtonAllInit( this.buttonFilterAll[ filterGroup ], filterGroup );
			this.filterButtonsInit( this.buttons[ filterGroup ], filterGroup );
		}.bind( this ) );
	},

	/**
	 * Handles the 'all' button.
	 *
	 * If button contains activeClass from start, toggle items.
	 * When a button is clicked for the first time it will be added to the local storage to remember selection.
	 *
	 * @param {HTMLSpanElement} button
	 * @param {string} filterGroup
	 */
	filterButtonAllInit: function( button, filterGroup ) {
		if ( button ) {
			this.setTabIndex( button );

			if ( button.classList.contains( this.activeButtonClass ) ) {
				this.toggleAllItems( filterGroup );
			}
			button.addEventListener( 'click', function() {
				this.toggleAllItems( filterGroup );
				this.setLocalStorage();
				liquipedia.tracker.track( 'Filter button clicked: ' + button.textContent, true );
			}.bind( this ) );
			button.addEventListener( 'keypress', function( event ) {
				if ( event.key === 'Enter' ) {
					this.toggleAllItems( filterGroup );
					this.setLocalStorage();
					liquipedia.tracker.track( 'Filter button clicked: ' + button.textContent, true );
				}
			}.bind( this ) );
		}
	},

	/**
	 * Handles buttons except for the 'all' button.
	 * Filter items on click and Enter key and write to localStorage.
	 *
	 * @param {HTMLSpanElement[]} buttons
	 * @param {string} filterGroup
	 */
	filterButtonsInit: function( buttons, filterGroup ) {
		buttons.forEach( function( button ) {
			this.setTabIndex( button );
			this.initButtonState( filterGroup, button );

			button.addEventListener( 'click', function ( event ) {
				this.filterItems( event.target );
				this.setLocalStorage();
				liquipedia.tracker.track( 'Filter button clicked: ' + button.textContent, true );
			}.bind( this ) );

			button.addEventListener( 'keypress', function ( event ) {
				if ( event.key === 'Enter' ) {
					this.filterItems( event.target );
					this.setLocalStorage();
					liquipedia.tracker.track( 'Filter button clicked: ' + button.textContent, true );
				}
			}.bind( this ) );
		}.bind( this ) );
	},

	/**
	 * Initial check if button states need to be changed
	 *
	 * @param {string} filterGroup
	 * @param {HTMLSpanElement} button
	 */
	initButtonState: function( filterGroup, button ) {
		// Check for data in local storage
		const localStorageValue = this.getLocalStorage();
		if ( filterGroup in localStorageValue ) {
			// console.log('filterGroup', filterGroup, this.activeFilters[filterGroup]);
			// User has filter preferences. Remove all pre-set active classes and build from localstorage instead.
			button.classList.remove( this.activeButtonClass );
			if ( Array.isArray( localStorageValue[ filterGroup ] ) && localStorageValue[ filterGroup ].length === 0 ) {
				// this.hideAllItems(filterGroup);
				// console.log('if array empty', filterGroup, localStorageValue[filterGroup]);
			}
			if ( localStorageValue[ filterGroup ].includes( button.getAttribute( 'data-filter-on' ) ) ) {
				// User has this filterGroup in localstorage, meaning they have marked a preference, so this takes priority.
				// If the button is in the localstorage array, filter on it.
				this.filterItems( button, true );
			}
		} else if ( !( filterGroup in localStorageValue ) && button.classList.contains( this.activeButtonClass ) ) {
			// If the user does not have a localstorage array for this filterGroup it means they have
			// not interacted with the filters, so we fall back to the defaults set by html 'active' classes
			this.filterItems( button, true );
		}
	},

	toggleItems: function( filterGroup ) {
		this.items[ filterGroup ].forEach( function( item ) {
			const filterCategory = item.getAttribute( 'data-filter-category' );

			const index = this.activeFilters[ filterGroup ].indexOf( filterCategory );
			if ( index > -1 ) {
				item.classList.add( 'filter-effect-' + this.filterEffect[ filterGroup ] );
				item.classList.remove( this.hiddenCategoryClass );
			} else {
				item.classList.remove( 'filter-effect-' + this.filterEffect[ filterGroup ] );
				item.classList.add( this.hiddenCategoryClass );
			}
		}.bind( this ) );
	},

	showAllItems: function( filterGroup ) {
		this.activeFilters[ filterGroup ] = [];

		this.buttons[ filterGroup ].forEach( function( button ) {
			button.classList.add( this.activeButtonClass );
			this.activeFilters[ filterGroup ].push( button.getAttribute( 'data-filter-on' ) );
		}.bind( this ) );

		this.items[ filterGroup ].forEach( function( item ) {
			if ( this.activeFilters[ filterGroup ].includes( item.getAttribute( 'data-filter-category' ) ) ) {
				item.classList.add( 'filter-effect-' + this.filterEffect[ filterGroup ] );
				item.classList.remove( this.hiddenCategoryClass );
			}
		}.bind( this ) );

		this.buttonFilterAll[ filterGroup ].classList.add( this.activeButtonClass );
	},

	hideAllItems: function( filterGroup ) {
		this.activeFilters[ filterGroup ] = this.activeAlwaysFilters[ filterGroup ].slice( 0 );

		this.buttons[ filterGroup ].forEach( function( button ) {
			if ( !this.activeAlwaysFilters[ filterGroup ].includes( button.getAttribute( 'data-filter-on' ) ) ) {
				button.classList.remove( this.activeButtonClass );
			}
		}.bind( this ) );

		this.items[ filterGroup ].forEach( function( item ) {
			if ( !this.activeAlwaysFilters[ filterGroup ].includes( item.getAttribute( 'data-filter-category' ) ) ) {
				item.classList.remove( 'filter-effect-' + this.filterEffect[ filterGroup ] );
				item.classList.add( this.hiddenCategoryClass );
			}
		}.bind( this ) );

		this.buttonFilterAll[ filterGroup ].classList.remove( this.activeButtonClass );
	},

	toggleAllItems: function( filterGroup ) {
		if ( this.activeFilters[ filterGroup ].length === this.buttons[ filterGroup ].length ) {
			this.hideAllItems( filterGroup );
		} else {
			this.showAllItems( filterGroup );
		}
	},

	filterItems: function( button, isInit ) {
		const filterCategory = button.getAttribute( 'data-filter-on' );
		const filterGroup = button.closest( '[data-filter]' ).getAttribute( 'data-filter-group' ) || this.bcFilterGroup;
		if ( !( filterGroup in this.activeFilters ) ) {
			return;
		}

		const index = this.activeFilters[ filterGroup ].indexOf( filterCategory );
		if ( index > -1 ) {
			if ( isInit === true ) {
				return;
			}
			this.activeFilters[ filterGroup ].splice( index, 1 );
			button.classList.remove( this.activeButtonClass );
			if ( this.buttonFilterAll[ filterGroup ] ) {
				this.buttonFilterAll[ filterGroup ].classList.remove( this.activeButtonClass );
			}
			this.toggleItems( filterGroup );
		} else {
			this.activeFilters[ filterGroup ].push( filterCategory );
			button.classList.add( this.activeButtonClass );
			if ( this.buttonFilterAll[ filterGroup ] && this.activeFilters[ filterGroup ].length === this.buttons[ filterGroup ].length ) {
				this.buttonFilterAll[ filterGroup ].classList.add( this.activeButtonClass );
			}
			this.toggleItems( filterGroup );
		}
	},

	getLocalStorage: function() {
		const check = window.localStorage.getItem( this.localStorageKey );
		return check ? JSON.parse( window.localStorage.getItem( this.localStorageKey ) ) : {};
	},

	/**
	 * Set local storage value with activeFilters
	 */
	setLocalStorage: function() {
		window.localStorage.setItem( this.localStorageKey, JSON.stringify( this.activeFilters ) );
	},

	/**
	 * Add tabindex attribute to element
	 *
	 * @param {HTMLElement} element
	 */
	setTabIndex: function( element ) {
		element.setAttribute( 'tabindex', '0' );
	},

	buildLocalStorageKey: function() {
		const base = 'LiquipediaFilterButtons';
		const scriptPath = mw.config.get( 'wgScriptPath' ).replace( /[\W]/g, '' );
		const pageName = mw.config.get( 'wgPageName' );

		return base + '-' + scriptPath + '-' + pageName;
	}
};
liquipedia.core.modules.push( 'filterButtons' );
