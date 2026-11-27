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
 * will instead be shown when the group is determined to be hidden instead of hiding the actual group element. Finally,
 * optionally, can set a custom class to use when the group is hidden with `data-filter-hidden-class`; defaults to class
 * `filter-category--hidden-group` otherwise.
 * ```html
 * <div data-filter-hideable-group data-filter-effect="fade" data-filter-hidden-class="filter-category--hidden-group">
 *   <span data-filter-group="group1" data-filter-category="cat1">cat1</span>
 *   <span data-filter-group="group1" data-filter-category="cat2">cat2</span>
 *   <span data-filter-hideable-group-fallback>DEFAULT CONTENT</span>
 * </div>
 * ```
 *
 * #### Filter popover with staged changes
 * Filter groups can be placed in a popover, where they are shown as checkboxes and only applied once confirmed.
 * A group with nothing checked is unrestricted, i.e. all of its filters are applied as active.
 * ```html
 * <div data-filter-popover>
 *   <div data-filter-popover-toggle>Filter <span data-filter-popover-count></span></div>
 *   <div class="filter-popover__panel">
 *     <span data-filter-popover-category-count="group1"></span>
 *     <span data-filter-popover-toggle-all="group1" data-label-clear="Clear" data-label-select-all="Select all"></span>
 *     <div data-filter data-filter-staged data-filter-group="group1">
 *       <div data-filter-on="cat1" data-filter-default="true" role="checkbox">Category 1</div>
 *       <div data-filter-on="cat2" role="checkbox">Category 2</div>
 *     </div>
 *     <div data-filter-popover-action="reset">Reset</div>
 *     <div data-filter-popover-action="cancel">Cancel</div>
 *     <div data-filter-popover-action="apply">Apply</div>
 *   </div>
 * </div>
 * ```
 * - `data-filter-staged` (required): marks a filter group as part of a popover. Its buttons are the direct children
 *     with `data-filter-on`; there are no 'all' or 'curated' buttons. A button is only active by default if it has
 *     `data-filter-default="true"`.
 * - `data-filter-popover-toggle` (required): replaced by a button opening the popover.
 * - `data-filter-popover-count` (optional): shows the number of applied filters.
 * - `data-filter-popover-category-count` / `data-filter-popover-toggle-all` (optional): the number of checked
 *     filters of a group, and a control to clear or check all of them.
 *
 * #### Filterable items counters
 * Filterable items can be counted and the value updated in a separate counter location.
 *
 * Counting can be done using a hideable group where only top-level hidable items will be counted.
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

/**
 * Filter groups shown as checkboxes in a popover.
 * See "Filter popover with staged changes" above.
 */
class FilterButtonsPopover {
	static count = 0;

	static supportsPopover() {
		return Object.prototype.hasOwnProperty.call( HTMLElement.prototype, 'popover' );
	}

	static supportsAnchorPositioning() {
		return CSS.supports( 'position-area: block-end' );
	}

	/**
	 * @param {HTMLElement} element
	 * @param {Object} filterButtons the filter buttons module holding the filter groups
	 * @return {FilterButtonsPopover|null}
	 */
	static create( element, filterButtons ) {
		const panel = element.querySelector( '.filter-popover__panel' );
		const toggleDiv = element.querySelector( '[data-filter-popover-toggle]' );
		const groups = Array.from(
			element.querySelectorAll( '[data-filter][data-filter-staged]' ),
			( groupElement ) => filterButtons.filterGroups[ groupElement.dataset.filterGroup ]
		).filter( ( group ) => group !== undefined );
		if ( !panel || !toggleDiv || groups.length === 0 ) {
			return null;
		}

		const popover = new FilterButtonsPopover( element, panel, toggleDiv, groups, filterButtons );
		popover.initialize();
		return popover;
	}

	/**
	 * A group with every filter active is unrestricted, which the popover shows as nothing checked.
	 *
	 * @param {Object<string, boolean>} filterStates
	 * @return {Object<string, boolean>}
	 */
	static toCheckedStates( filterStates ) {
		const isUnrestricted = Object.values( filterStates ).every( Boolean );
		return Object.fromEntries(
			Object.entries( filterStates ).map( ( [ filter, active ] ) => [ filter, !isUnrestricted && active ] )
		);
	}

	/**
	 * @param {Object<string, boolean>} checkedStates
	 * @return {number}
	 */
	static countChecked( checkedStates ) {
		return Object.values( checkedStates ).filter( Boolean ).length;
	}

	/**
	 * @param {HTMLElement} element
	 * @param {HTMLElement} panel
	 * @param {HTMLElement} toggleDiv
	 * @param {Object[]} groups
	 * @param {Object} filterButtons
	 */
	constructor( element, panel, toggleDiv, groups, filterButtons ) {
		this.element = element;
		this.panel = panel;
		this.toggleDiv = toggleDiv;
		this.groups = groups;
		this.filterButtons = filterButtons;
		/** @type {Object<string, Object<string, boolean>>} */
		this.pendingStates = {};
		this.isOpen = false;
		this.usesPopoverApi = FilterButtonsPopover.supportsPopover();
		this.name = 'filter-popover-' + ( ++FilterButtonsPopover.count );
	}

	initialize() {
		this.toggle = this.createToggle();
		if ( !this.panel.id ) {
			this.panel.id = this.name;
		}
		this.toggle.setAttribute( 'aria-controls', this.panel.id );

		if ( this.usesPopoverApi ) {
			this.setupNativePopover();
		} else {
			this.setupFallbackPopover();
		}
		this.setupControls();

		this.loadPendingStates();
		this.render();
	}

	/**
	 * The parser does not allow <button>, so the toggle is swapped in here.
	 *
	 * @return {HTMLButtonElement}
	 */
	createToggle() {
		const toggle = document.createElement( 'button' );
		toggle.type = 'button';
		toggle.className = this.toggleDiv.className;
		toggle.setAttribute( 'aria-haspopup', 'dialog' );
		toggle.setAttribute( 'aria-expanded', 'false' );
		toggle.append( ...this.toggleDiv.childNodes );
		this.toggleDiv.replaceWith( toggle );
		return toggle;
	}

	setupNativePopover() {
		this.panel.setAttribute( 'popover', 'auto' );
		// Making the toggle the invoker also exempts it from light dismiss
		this.toggle.setAttribute( 'popovertarget', this.panel.id );
		if ( FilterButtonsPopover.supportsAnchorPositioning() ) {
			this.element.classList.add( 'filter-popover--anchored' );
			this.toggle.style.setProperty( 'anchor-name', '--' + this.name );
			this.panel.style.setProperty( 'position-anchor', '--' + this.name );
		}
		// Also fires on light dismiss and Escape
		this.panel.addEventListener( 'beforetoggle', ( event ) => {
			this.onToggle( event.newState === 'open' );
		} );
	}

	setupFallbackPopover() {
		this.element.classList.add( 'filter-popover--fallback' );
		this.toggle.addEventListener( 'click', () => this.setOpen( !this.isOpen ) );
		document.addEventListener( 'click', ( event ) => {
			if ( this.isOpen && !this.element.contains( event.target ) ) {
				this.setOpen( false );
			}
		} );
		document.addEventListener( 'keydown', ( event ) => {
			if ( this.isOpen && event.key === 'Escape' ) {
				this.setOpen( false );
			}
		} );
	}

	setupControls() {
		this.groups.forEach( ( group ) => {
			Object.values( group.buttons ).forEach( ( button ) => {
				this.addActivationListener( button.element, () => {
					const pending = this.pendingStates[ group.name ];
					pending[ button.filter ] = !pending[ button.filter ];
					this.render();
				} );
			} );
		} );

		this.element.querySelectorAll( '[data-filter-popover-toggle-all]' ).forEach( ( toggleAll ) => {
			const group = this.filterButtons.filterGroups[ toggleAll.dataset.filterPopoverToggleAll ];
			if ( !group ) {
				return;
			}
			this.addActivationListener( toggleAll, () => {
				const pending = this.pendingStates[ group.name ];
				const newState = FilterButtonsPopover.countChecked( pending ) === 0;
				Object.keys( pending ).forEach( ( filter ) => {
					pending[ filter ] = newState;
				} );
				this.render();
			} );
		} );

		const actions = {
			reset: () => this.reset(),
			cancel: () => this.setOpen( false ),
			apply: () => this.apply()
		};
		this.element.querySelectorAll( '[data-filter-popover-action]' ).forEach( ( actionElement ) => {
			const action = actions[ actionElement.dataset.filterPopoverAction ];
			if ( action ) {
				this.addActivationListener( actionElement, action );
			}
		} );
	}

	/**
	 * @param {HTMLElement} activatable
	 * @param {function(): void} callback
	 */
	addActivationListener( activatable, callback ) {
		const handler = ( event ) => {
			if ( event.type === 'keydown' && event.key !== 'Enter' && event.key !== ' ' ) {
				return;
			}
			event.preventDefault();
			callback();
		};
		activatable.addEventListener( 'click', handler );
		activatable.addEventListener( 'keydown', handler );
	}

	loadPendingStates() {
		this.groups.forEach( ( group ) => {
			this.pendingStates[ group.name ] = FilterButtonsPopover.toCheckedStates( group.filterStates );
		} );
	}

	reset() {
		this.groups.forEach( ( group ) => {
			this.pendingStates[ group.name ] = FilterButtonsPopover.toCheckedStates( group.defaultStates );
		} );
		this.render();
	}

	apply() {
		this.groups.forEach( ( group ) => {
			const pending = this.pendingStates[ group.name ];
			const isUnrestricted = FilterButtonsPopover.countChecked( pending ) === 0;
			Object.keys( group.filterStates ).forEach( ( filter ) => {
				group.filterStates[ filter ] = isUnrestricted || pending[ filter ];
			} );
			group.curated = false;
		} );
		liquipedia.tracker.track( 'Filter popover applied', true );
		this.filterButtons.performUpdate();
		this.setOpen( false );
	}

	/**
	 * @param {boolean} isOpen
	 */
	setOpen( isOpen ) {
		if ( this.isOpen === isOpen ) {
			return;
		}
		if ( this.usesPopoverApi ) {
			// Triggers onToggle() through the beforetoggle event
			if ( isOpen ) {
				this.panel.showPopover();
			} else {
				this.panel.hidePopover();
			}
			return;
		}
		// The native popover does this on its own
		if ( !isOpen && this.panel.contains( document.activeElement ) ) {
			this.toggle.focus();
		}
		this.onToggle( isOpen );
	}

	/**
	 * Pending changes are dropped whenever the popover opens or closes, so only applied changes stick.
	 *
	 * @param {boolean} isOpen
	 */
	onToggle( isOpen ) {
		this.isOpen = isOpen;
		this.element.classList.toggle( 'filter-popover--open', isOpen );
		this.toggle.setAttribute( 'aria-expanded', String( isOpen ) );
		this.loadPendingStates();
		this.render();
	}

	render() {
		this.groups.forEach( ( group ) => {
			const pending = this.pendingStates[ group.name ];
			Object.values( group.buttons ).forEach( ( button ) => {
				button.element.setAttribute( 'aria-checked', String( pending[ button.filter ] ) );
			} );

			const checkedCount = FilterButtonsPopover.countChecked( pending );
			this.element.querySelectorAll(
				'[data-filter-popover-category-count="' + group.name + '"]'
			).forEach( ( counter ) => {
				counter.textContent = String( checkedCount );
				counter.classList.toggle( 'filter-popover__category-count--empty', checkedCount === 0 );
			} );
			this.element.querySelectorAll(
				'[data-filter-popover-toggle-all="' + group.name + '"]'
			).forEach( ( toggleAll ) => {
				toggleAll.textContent = checkedCount > 0 ?
					toggleAll.dataset.labelClear :
					toggleAll.dataset.labelSelectAll;
			} );
		} );
		this.renderCount();
	}

	/**
	 * Shows the number of applied (not pending) filters on the toggle.
	 */
	renderCount() {
		const count = this.groups.reduce(
			( sum, group ) => sum + FilterButtonsPopover.countChecked(
				FilterButtonsPopover.toCheckedStates( group.filterStates )
			),
			0
		);
		this.element.querySelectorAll( '[data-filter-popover-count]' ).forEach( ( counter ) => {
			counter.textContent = count > 0 ? ' (' + count + ')' : '';
		} );
		this.toggle.classList.toggle( 'filter-popover__toggle--active', count > 0 );
	}
}

liquipedia.filterButtons = {
	fallbackFilterEffect: 'none',
	activeButtonClass: 'filter-button--active',
	hiddenCategoryClass: 'filter-category--hidden',
	hiddenGroupClass: 'filter-category--hidden-group',
	fallbackFilterGroup: 'filter-group-fallback-common',

	filterGroups: {},
	templateExpansions: [],
	hideableGroups: [],
	filterCounters: {},
	/** @type {FilterButtonsPopover[]} */
	popovers: [],

	init: function() {
		const filterButtonGroups = Array.from(
			document.querySelectorAll( '.filter-buttons[data-filter], [data-filter][data-filter-staged]' )
		);
		if ( filterButtonGroups.length === 0 ) {
			return;
		}

		this.localStorageKey = this.buildLocalStorageKey();
		this.generateFilterGroups( filterButtonGroups );
		this.generateFilterableObjects();
		this.initializeButtons();
		this.initializePopovers();
		this.performUpdate();
	},

	/**
	 * @param {HTMLElement[]} filterButtonGroups
	 */
	generateFilterGroups: function( filterButtonGroups ) {
		const localStorage = this.getLocalStorage();

		filterButtonGroups.forEach( ( buttonsDiv ) => {
			const filterGroup = buttonsDiv.dataset.filterGroup ?? this.fallbackFilterGroup;
			const staged = buttonsDiv.dataset.filterStaged !== undefined;
			const filterGroupEntry = {
				name: filterGroup,
				staged: staged,
				buttons: [],
				alwaysActive: buttonsDiv.dataset.filterAlwaysActive?.split( ',' ) ?? [],
				effectClass: 'filter-effect-' + ( buttonsDiv.dataset.filterEffect ?? this.fallbackFilterEffect ),
				filterStates: {},
				curated: localStorage[ filterGroup ]?.curated ?? buttonsDiv.dataset.filterDefaultCurated === 'true',
				filterableItems: [],
				defaultStates: {},
				defaultCurated: buttonsDiv.dataset.filterDefaultCurated === 'true'
			};

			const buttonSelector = staged ? ':scope > [data-filter-on]' : ':scope > .filter-button';
			Array.from( buttonsDiv.querySelectorAll( buttonSelector ) ).forEach(
				/** @param {HTMLElement} buttonElement */
				( buttonElement ) => {
					const filterOn = buttonElement.dataset.filterOn ?? '';
					// Buttons of staged groups are not styled as active, so they declare their default explicitly
					const defaultState = staged ?
						buttonElement.dataset.filterDefault === 'true' :
						!(
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
								localStorage[ filterGroup ]?.filterStates[ filterOn ] ?? defaultState;
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
				hiddenClass: hideableGroup.dataset.filterHiddenClass ?? this.hiddenGroupClass,
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
			// Buttons of staged groups are handled by their popover
			if ( filterGroup.staged ) {
				return;
			}

			this.getGroupButtons( filterGroup ).forEach( ( button ) => {
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
		Object.values( this.filterCounters ).forEach( ( filterCounter ) => {
			filterCounter.count = 0;
		} );

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

			if ( filterGroup.allButton ) {
				filterGroup.allButton.active = allState;
			}
			if ( filterGroup.curatedButton ) {
				filterGroup.curatedButton.active = filterGroup.curated;
			}

			filterGroup.filterableItems.forEach( ( filterableItem ) => {
				if ( filterGroup.curated ) {
					filterableItem.hidden = !filterableItem.curated;
				} else {
					filterableItem.hidden = !filterableItem.categories.every(
						( category ) => filterGroup.filterStates[ category ]
					);
				}
				if ( filterableItem.counter && !filterableItem.hidden ) {
					this.filterCounters[ filterableItem.counter ].count += 1;
				}
			} );
		} );
	},

	updateDOM: function() {
		Object.values( this.filterGroups ).forEach( ( filterGroup ) => {
			// Staged groups show their pending state instead, see FilterButtonsPopover
			if ( !filterGroup.staged ) {
				this.getGroupButtons( filterGroup ).forEach( ( button ) => {
					if ( button.active ) {
						button.element.classList.add( this.activeButtonClass );
					} else {
						button.element.classList.remove( this.activeButtonClass );
					}
				} );
			}

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
			if ( !filterableItems.some( this.isFilterableVisible, this ) ) {
				groupElement.classList.remove( hideableGroup.effectClass );
				groupElement.classList.add( hideableGroup.hiddenClass );
				hideableGroup.fallbackItem?.classList.add( hideableGroup.effectClass );
			} else {
				groupElement.classList.replace( hideableGroup.hiddenClass, hideableGroup.effectClass );
				hideableGroup.fallbackItem?.classList.remove( hideableGroup.effectClass );
			}
			if ( hideableGroup.counter && !groupElement.classList.contains( hideableGroup.hiddenClass ) ) {
				this.filterCounters[ hideableGroup.counter ].count += 1;
			}
		} );

		Object.values( this.filterCounters ).forEach( ( filterCounter ) => {
			filterCounter.element.innerHTML = filterCounter.count;
		} );

		this.popovers.forEach( ( popover ) => popover.renderCount() );

		Promise.all( this.templateExpansions.map( async ( templateExpansion ) => {
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

			await mw.loader.using( [ 'mediawiki.api' ] );

			const api = new mw.Api();
			const data = await api.get( {
				action: 'parse',
				format: 'json',
				contentmodel: 'wikitext',
				maxage: 600,
				smaxage: 600,
				disablelimitreport: true,
				uselang: 'content',
				prop: 'text',
				text: wikitext
			} );
			if ( data.parse?.text?.[ '*' ] ) {
				templateExpansion.element.innerHTML = data.parse.text[ '*' ];
				templateExpansion.cache[ wikitext ] = data.parse.text[ '*' ];
				this.refreshScriptsAfterContentUpdate();
			}
		} ) );
	},

	/**
	 * @param {Object} filterGroup
	 * @return {Object[]}
	 */
	getGroupButtons: function( filterGroup ) {
		return [ ...Object.values( filterGroup.buttons ), filterGroup.allButton, filterGroup.curatedButton ]
			.filter( ( button ) => button !== undefined );
	},

	initializePopovers: function() {
		this.popovers = Array.from(
			document.querySelectorAll( '[data-filter-popover]' ),
			( element ) => FilterButtonsPopover.create( element, this )
		).filter( ( popover ) => popover !== null );
	},

	refreshScriptsAfterContentUpdate: function() {
		liquipedia.countdown.init();
		liquipedia.collapse.init();
		liquipedia.switchButtons.init();
		liquipedia.carousel.init();
		liquipedia.matchticker.init();
	},

	buildLocalStorageKey: function() {
		const base = 'LiquipediaFilterButtonsV2';
		const scriptPath = mw.config.get( 'wgScriptPath' ).replace( /[\W]/g, '' );
		const pageName = mw.config.get( 'wgPageName' );

		return base + '-' + scriptPath + '-' + pageName;
	},

	getLocalStorage: function() {
		return liquipedia.storage.getJson( this.localStorageKey, {} );
	},

	setLocalStorage: function() {
		const filterGroups = {};
		Object.values( this.filterGroups ).forEach( ( filterGroup ) => {
			filterGroups[ filterGroup.name ] = { filterStates: filterGroup.filterStates, curated: filterGroup.curated };
		} );
		liquipedia.storage.setJson( this.localStorageKey, filterGroups );
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

liquipedia.filterButtonsPopover = FilterButtonsPopover;
liquipedia.core.modules.push( 'filterButtons' );
