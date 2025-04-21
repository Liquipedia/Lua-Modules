/*******************************************************************************
 Template(s): Filter buttons
 Author(s): Elysienna (original), iMarbot (refactor), SyntacticSalt (template expansion)
 *******************************************************************************/
/**
 * ### Liquipedia Filter Buttons
 * #### Filter buttons/groups
 * ```html
 * <span data-filter data-filter-effect="fade" data-filter-group="group1">
 *   <span data-filter-on="all">All</span>
 *   <span data-filter-on="cat1" class="filter-button--active">Category 1</span>
 *   <span data-filter-on="cat2">Category 2</span>
 * </span>
 * ```
 *
 * - `data-filter` (required): property on the container to group the buttons within into the given group
 * - `data-filter-group` (encouraged): unique identifier for group, used to determine which items to filter on the page.
 *     Note: this attribute is technically not required as long as one instance of the module is being used.
 *           When using multiple on a single page, ALWAYS use this attribute to distinguish between button/item groups
 * - `data-filter-effect` (optional): options are [fade,bounce,none]. When omitted, no effect is used.
 * - `data-filter-on` (required): clicking this element will toggle the items with the passed category
 *     (matching on `data-filter-category` on the items). Can also be 'all' to toggle all items.
 * Note: the class 'filter-button--active' may be given to pre-filter items on load.
 *
 * #### Filterable items
 * ```html
 * <span data-filter-group="group1" data-filter-category="cat1">cat1</span>
 * <span data-filter-group="group1" data-filter-category="cat2">cat2</span>
 * <span data-filter-group="group1" data-filter-categories="cat1,cat2">cat1 and cat2</span>
 * ```
 *
 * - `data-filter-group` (encouraged): group identifier for which the button group can interact with the item.
 *     Note: See data-filter-group in Filter buttons above as to why it is encouraged to always provide.
 * - `data-filter-category` (required†): single identifier for 'data-filter-on'
 * - `data-filter-categories` (required†): comma-separated list of identifiers for 'data-filter-on'
 *
 * † either one of these are required, but not both, though both can be used and will be appended together.
 *
 * #### Replacement by template with filter options
 * ```html
 * <div data-filter-expansion-template="TemplateName" data-filter-groups="group1,group2">Default content</div>
 * ```
 * - `data-filter-expansion-template` (required): The template to expand with the current filter options.
 *   Expanded template will replace default content.
 * - `data-filter-groups` (required): Identify which filter groups the template will receive current parameters from.
 *   Should correspond to appropriate filter button groups used on the page.
 *   For each group, the template will receive a parameter groupName holding the currently active group settings.
 *
 * #### Self-hiding filterable item groups
 * Just adding this data attribute (no actual value needed) will create a group of filterable items. This group will
 * then hide itself entierly if all the items contained within it are also hidden. Useful to hide categorizing heading
 * items. Optionally can also add an effect type as with items which will be used on the whole group as well. The groups
 * can also be nested, but, this will still check filterable items and not whether child groups themselves are hidden.
 * Can also add a fallback item as a direct child of the group using `data-filter-hideable-group-fallback`; this item
 * will instead be shown when the group is determined to be hidden instead of hiding the actual group element.
 * ```html
 * <div data-filter-hideable-group data-filter-effect="fade">
 *   <span data-filter-group="group1" data-filter-category="cat1">cat1</span>
 *   <span data-filter-group="group1" data-filter-category="cat2">cat2</span>
 *   <span data-filter-hideable-group-fallback>DEFAULT CONTENT</span>
 * </div>
 * ```
 *
 * #### Filterable items counters
 * Filterable items can be counted and the value updated in a seprate counter location.
 *
 * Counting can be done using a hidable group where only top-level hidable items will be counted.
 * ```html
 * <span data-filter-counter="counter1">0</span>
 * <div data-filter-hideable-group data-filter-effect="fade" data-filter-count="counter1">
 *   <span data-filter-group="group1" data-filter-category="cat1">cat1</span>
 *   <span data-filter-group="group1" data-filter-category="cat2">cat2</span>
 * </div>
 * ```
 * Counting can also be done on a per-item level where any item is tied to a counter.
 * ```html
 * <span data-filter-counter="counter2">0</span>
 * <div>
 *   <span data-filter-group="group1" data-filter-category="cat1" data-filter-count="counter2">cat1</span>
 *   <span data-filter-group="group1" data-filter-category="cat2" data-filter-count="counter2">cat2</span>
 * </div>
 * ```
 */

liquipedia.filterButtons = {
	fallbackFilterEffect: 'none',
	activeButtonClass: 'filter-button--active',
	hiddenCategoryClass: 'filter-category--hidden',
	fallbackFilterGroup: 'filter-group-fallback-common',

	filterGroups: {},
	templateExpansions: [],
	hideableGroups: [],
	filterCounters: {},

	init: function() {
		const filterButtonGroups = Array.from( document.querySelectorAll( '.filter-buttons[data-filter]' ) );
		if ( filterButtonGroups.length === 0 ) {
			return;
		}

		this.localStorageKey = this.buildLocalStorageKey();
		this.generateFilterGroups( filterButtonGroups );
		this.generateFilterableObjects();
		this.initializeButtons();
		this.performUpdate();
	},

	/**
	 * @param {HTMLElement[]} filterButtonGroups
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
				filterableItems: [],
				defaultStates: {},
				defaultCurated: buttonsDiv.dataset.filterDefaultCurated === 'true'
			};

			Array.from( buttonsDiv.querySelectorAll( ':scope > .filter-button' ) ).forEach(
				/** @param {HTMLElement} buttonElement */
				( buttonElement ) => {
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
							filterGroupEntry.defaultStates[ filterOn ] = defaultState;
					}
					buttonElement.setAttribute( 'tabindex', '0' );
				}
			);

			this.filterGroups[ filterGroup ] = filterGroupEntry;
		} );
	},

	generateFilterableObjects: function() {
		Array.from( document.querySelectorAll( '[data-filter-counter]' ) ).forEach(
			/** @param {HTMLElement} filterCounter */
			( filterCounter ) => {
				const counterName = filterCounter.dataset.filterCounter;
				const countableElements = document.querySelectorAll( '[data-filter-count="' + counterName + '"]' );
				this.filterCounters[ counterName ] = {
					element: filterCounter,
					name: counterName,
					count: countableElements.length
				};
			}
		);

		Array.from( document.querySelectorAll( '[data-filter-category], [data-filter-categories]' ) ).forEach(
			/** @param {HTMLElement} filterableItem */
			( filterableItem ) => {
				const filterGroup = this.filterGroups[ filterableItem.dataset.filterGroup ?? this.fallbackFilterGroup ];
				const filterCategories = filterableItem.dataset.filterCategories?.split( ',' ) ?? [];
				if ( filterableItem.dataset.filterCategory ) {
					filterCategories.push( filterableItem.dataset.filterCategory );
				}
				filterGroup.filterableItems.push( {
					element: filterableItem,
					categories: filterCategories,
					curated: filterableItem.dataset.curated !== undefined,
					counter: filterableItem.dataset.filterCount,
					hidden: false
				} );
			}
		);

		this.templateExpansions = Array.from(
			document.querySelectorAll( '[data-filter-expansion-template]' ),
			/** @param {HTMLElement} templateExpansion */
			( templateExpansion ) => ( {
				element: templateExpansion,
				groups: templateExpansion.dataset.filterGroups.split( ',' ),
				template: templateExpansion.dataset.filterExpansionTemplate,
				cache: {
					default: templateExpansion.innerHTML
				}
			} )
		);

		this.hideableGroups = Array.from(
			document.querySelectorAll( '[data-filter-hideable-group]' ),
			/** @param {HTMLElement} hideableGroup */
			( hideableGroup ) => ( {
				element: hideableGroup,
				hiddenClass: hideableGroup.dataset.filterHiddenClass ?? 'filter-category--hidden-group',
				effectClass: 'filter-effect-' + ( hideableGroup.dataset.filterEffect ?? this.fallbackFilterEffect ),
				fallbackItem: hideableGroup.querySelector( ':scope > [data-filter-hideable-group-fallback]' ),
				counter: hideableGroup.dataset.filterCount
			} )
		);
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
				const initialHidden = filterableItem.hidden;
				if ( filterGroup.curated ) {
					filterableItem.hidden = !filterableItem.curated;
				} else {
					filterableItem.hidden = !filterableItem.categories.every( ( category ) => {
						return filterGroup.filterStates[ category ];
					} );
				}
				if ( initialHidden !== filterableItem.hidden && filterableItem.counter ) {
					const existingCount = this.filterCounters[ filterableItem.counter ].count;
					let newCount = existingCount + ( filterableItem.hidden ? -1 : 1 );
					newCount = newCount < 0 ? 0 : newCount;
					this.filterCounters[ filterableItem.counter ].count = newCount;
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

		this.hideableGroups.forEach( ( hideableGroup ) => {
			const groupElement = hideableGroup.element;
			const filterableItems = this.getTopLevelFilterableItems( groupElement );
			const initialHidden = groupElement.classList.contains( hideableGroup.hiddenClass );
			if ( !filterableItems.some( this.isFilterableVisible, this ) ) {
				groupElement.classList.remove( hideableGroup.effectClass );
				groupElement.classList.add( hideableGroup.hiddenClass );
				hideableGroup.fallbackItem?.classList.add( hideableGroup.effectClass );
			} else {
				groupElement.classList.replace( hideableGroup.hiddenClass, hideableGroup.effectClass );
				hideableGroup.fallbackItem?.classList.remove( hideableGroup.effectClass );
			}
			const newHidden = groupElement.classList.contains( hideableGroup.hiddenClass );
			if ( initialHidden !== newHidden && hideableGroup.counter ) {
				const existingCount = this.filterCounters[ hideableGroup.counter ].count;
				let newCount = existingCount + ( newHidden ? -1 : 1 );
				newCount = newCount < 0 ? 0 : newCount;
				this.filterCounters[ hideableGroup.counter ].count = newCount;
			}
		} );

		Object.values( this.filterCounters ).forEach( ( filterCounter ) => {
			filterCounter.element.innerHTML = filterCounter.count;
		} );

		this.templateExpansions.forEach( ( templateExpansion ) => {
			const isDefault = templateExpansion.groups.every( ( group ) => {
				const filterGroup = this.filterGroups[ group ];
				if ( filterGroup.curated || filterGroup.defaultCurated ) {
					return filterGroup.curated === filterGroup.defaultCurated;
				}
				return Object.keys( filterGroup.filterStates ).every(
					( filter ) => filterGroup.filterStates[ filter ] === filterGroup.defaultStates[ filter ]
				);
			} );
			if ( isDefault ) {
				templateExpansion.element.innerHTML = templateExpansion.cache.default;
				this.refreshScriptsAfterContentUpdate();
				return;
			}
			const parameters = templateExpansion.groups.map( ( group ) => {
				if ( this.filterGroups[ group ].curated ) {
					return group + '=curated';
				}

				const filterStates = this.filterGroups[ group ].filterStates;
				const activeFilters = Object.keys( filterStates ).filter( ( k ) => filterStates[ k ] );

				return group + '=' + activeFilters.toString();
			} );
			const wikitext = '{{' + templateExpansion.template + '|' + parameters.join( '|' ) + '}}';

			if ( wikitext in templateExpansion.cache ) {
				templateExpansion.element.innerHTML = templateExpansion.cache[ wikitext ];
				this.refreshScriptsAfterContentUpdate();
				return;
			}

			mw.loader.using( [ 'mediawiki.api' ] ).then( () => {
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
					text: wikitext
				} ).then( ( data ) => {
					if ( data.parse?.text?.[ '*' ] ) {
						templateExpansion.element.innerHTML = data.parse.text[ '*' ];
						templateExpansion.cache[ wikitext ] = data.parse.text[ '*' ];
						this.refreshScriptsAfterContentUpdate();
					}
				} );
			} );
		} );
	},

	refreshScriptsAfterContentUpdate: function() {
		liquipedia.countdown.init();
		liquipedia.switchButtons.init();
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
	},

	/**
	 * @param {HTMLElement} element
	 * @return {HTMLElement[]}
	 */
	getTopLevelFilterableItems: function ( element ) {
		return Array.from(
			element.querySelectorAll(
				':scope [data-filter-category]:not(:scope [data-filter-category] [data-filter-category])' +
					':not(:scope [data-filter-categories] [data-filter-categories]),' +
				':scope [data-filter-categories]:not(:scope [data-filter-category] [data-filter-category])' +
					':not(:scope [data-filter-categories] [data-filter-categories])'
			)
		);
	},

	/**
	 * @param {HTMLElement} filterableItem
	 * @return {boolean}
	 */
	isFilterableVisible: function ( filterableItem ) {
		if ( filterableItem.classList.contains( this.hiddenCategoryClass ) ) {
			return false;
		} else {
			const filterableChildren = this.getTopLevelFilterableItems( filterableItem );
			return filterableChildren.length === 0 ? true : filterableChildren.some( this.isFilterableVisible, this );
		}
	}
};

liquipedia.core.modules.push( 'filterButtons' );
