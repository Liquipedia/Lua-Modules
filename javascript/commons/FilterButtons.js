/*******************************************************************************
 Template(s): Filter buttons
 Author(s): Elysienna (original), iMarbot (refactor)
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
		const filterButtonGroups = document.querySelectorAll( '.filter-buttons[data-filter]' );
		if ( filterButtonGroups.length === 0 ) {
			return;
		}

		this.localStorageKey = this.buildLocalStorageKey();
		this.generateFilterGroups( filterButtonGroups );
		this.generateFilterableItems();
		this.initializeButtons();
		this.performUpdate();
	},

	/**
	 * @param {NodeListOf<HTMLElement>} filterButtonGroups
	 */
	generateFilterGroups: function( filterButtonGroups ) {
		const localStorage = this.getLocalStorage();

		filterButtonGroups.forEach( ( buttonsDiv ) => {
			const filterGroup = buttonsDiv.dataset.filterGroup ?? this.fallbackFilterGroup;
			const filterGroupEntry = {
				name: filterGroup,
				buttons: [],
				alwaysActive: buttonsDiv.dataset.filterAlwaysActive?.split( ',' ) ?? [],
				effectClass: 'filter-effect-' + ( buttonsDiv.dataset.filterEffect ?? this.fallbackFilterEffect ),
				filterStates: localStorage[ filterGroup ]?.filterStates ?? {},
				curated: localStorage[ filterGroup ]?.curated ?? buttonsDiv.dataset.filterDefaultCurated === 'true',
				filterableItems: []
			};

			buttonsDiv.querySelectorAll( ':scope > .filter-button' ).forEach(
				( /** @type HTMLElement */ buttonElement ) => {
					const filterOn = buttonElement.dataset.filterOn ?? '';
					const defaultState = !(
						buttonElement.dataset.filterDefault === 'false' ||
							!buttonElement.classList.contains( 'filter-button--active' )
					);
					const button = {
						element: buttonElement,
						filter: filterOn,
						active: true
					};
					switch ( filterOn ) {
						case 'curated':
						case 'all':
							filterGroupEntry[ filterOn + 'Button' ] = button;
							break;
						default:
							filterGroupEntry.buttons[ filterOn ] = button;
							filterGroupEntry.filterStates[ filterOn ] =
								filterGroupEntry.filterStates[ filterOn ] ?? defaultState;
					}
					buttonElement.setAttribute( 'tabindex', '0' );
				}
			);

			this.filterGroups[ filterGroup ] = filterGroupEntry;
		} );
	},

	generateFilterableItems: function() {
		document.querySelectorAll( '[data-filter-category]' ).forEach( ( /** @type HTMLElement */ filterableItem ) => {
			const filterGroup = this.filterGroups[ filterableItem.dataset.filterGroup ?? this.fallbackFilterGroup ];
			filterGroup.filterableItems.push( {
				element: filterableItem,
				value: filterableItem.dataset.filterCategory,
				curated: filterableItem.dataset.curated !== undefined,
				hidden: false
			} );
		} );
	},

	initializeButtons: function() {
		const handleClick = function( button, filterGroup, event ) {
			if ( ( event.type === 'click' ) || ( event.type === 'keypress' && event.key === 'Enter' ) ) {
				liquipedia.tracker.track( 'Filter button clicked: ' + button.element.textContent, true );
				switch ( button.filter ) {
					case 'all':
						Object.entries( filterGroup.filterStates ).forEach( ( [ filterState ] ) => {
							if ( !filterGroup.alwaysActive.includes( filterState ) ) {
								filterGroup.filterStates[ filterState ] = !button.active;
							}
						} );
						filterGroup.curated = false;
						break;
					case 'curated':
						filterGroup.curated = !button.active;
						break;
					default:
						filterGroup.filterStates[ button.filter ] = !button.active;
						filterGroup.curated = false;
				}
				this.performUpdate();
			}
		};

		Object.values( this.filterGroups ).forEach( ( filterGroup ) => {
			const buttons = Object.values( filterGroup.buttons );
			buttons.push( filterGroup.allButton );
			if ( filterGroup.curatedButton ) {
				buttons.push( filterGroup.curatedButton );
			}

			buttons.forEach( ( button ) => {
				const buttonEventHandler = handleClick.bind( this, button, filterGroup );
				button.element.addEventListener( 'click', buttonEventHandler );
				button.element.addEventListener( 'keypress', buttonEventHandler );
			} );
		} );
	},

	performUpdate: function() {
		this.updateFromFilterStates();
		this.setLocalStorage();
		this.updateDOM();
	},

	updateFromFilterStates: function() {
		Object.values( this.filterGroups ).forEach( ( filterGroup ) => {
			let allState = true;

			Object.values( filterGroup.buttons ).forEach( ( button ) => {
				if ( filterGroup.curated ) {
					button.active = false;
					allState = false;
				} else {
					button.active = filterGroup.filterStates[ button.filter ];
					allState = allState && button.active;
				}
			} );

			filterGroup.allButton.active = allState;
			if ( filterGroup.curatedButton ) {
				filterGroup.curatedButton.active = filterGroup.curated;
			}

			filterGroup.filterableItems.forEach( ( filterableItem ) => {
				if ( filterGroup.curated ) {
					filterableItem.hidden = !filterableItem.curated;
				} else {
					filterableItem.hidden = !filterGroup.filterStates[ filterableItem.value ];
				}
			} );
		} );
	},

	updateDOM: function() {
		Object.values( this.filterGroups ).forEach( ( filterGroup ) => {
			const buttons = Object.values( filterGroup.buttons );
			buttons.push( filterGroup.allButton );
			if ( filterGroup.curatedButton ) {
				buttons.push( filterGroup.curatedButton );
			}

			buttons.forEach( ( button ) => {
				if ( button.active ) {
					button.element.classList.add( this.activeButtonClass );
				} else {
					button.element.classList.remove( this.activeButtonClass );
				}
			} );

			filterGroup.filterableItems.forEach( ( filterableItem ) => {
				if ( filterableItem.hidden ) {
					filterableItem.element.classList.remove( filterGroup.effectClass );
					filterableItem.element.classList.add( this.hiddenCategoryClass );
				} else {
					filterableItem.element.classList.replace( this.hiddenCategoryClass, filterGroup.effectClass );
				}
			} );
		} );
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
		Object.values( this.filterGroups ).forEach( ( filterGroup ) => {
			filterGroups[ filterGroup.name ] = { filterStates: filterGroup.filterStates, curated: filterGroup.curated };
		} );
		window.localStorage.setItem( this.localStorageKey, JSON.stringify( filterGroups ) );
	}
};

liquipedia.core.modules.push( 'filterButtons' );
