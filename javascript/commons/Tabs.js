/*******************************************************************************
 * Description: Manages dynamic tab interfaces on Liquipedia pages, enabling
 *              tab switching, drag-to-scroll navigation, hash-based routing,
 *              responsive mobile/show-all views, and keyboard accessibility.
 ******************************************************************************/

const TABS_CONFIG = {
	SELECTORS: {
		DYNAMIC_CONTAINER: '.tabs-dynamic',
		STATIC_CONTAINER: '.tabs-static',
		NAV_WRAPPER: '.tabs-nav-wrapper',
		NAV_TABS: '.nav-tabs',
		CONTENT_CONTAINER: '.tabs-content',
		ARROW_LEFT: '.tabs-scroll-arrow-wrapper--left',
		ARROW_RIGHT: '.tabs-scroll-arrow-wrapper--right',
		ACTIVE_TAB: 'li.active',
		TAB_ITEMS: 'li',
		STATIC_DROPDOWN: '.dropdown-widget',
		STATIC_DROPDOWN_TOGGLE: '.dropdown-widget__toggle',
		STATIC_DROPDOWN_LABEL: '.dropdown-widget__label',
		STATIC_DROPDOWN_MENU: '.dropdown-widget__menu',
		STATIC_DROPDOWN_LIST: '.dropdown-widget__menu > ul',
		DIRECT_CHILD_TABS_CONTENT: ':scope > .tabs-content',
		DIRECT_CHILD_ANALYTICS_STATIC: ':scope > [data-analytics-name="Navigation tab"] > .tabs-static'
	},
	SCROLL: {
		ARROW_STEP: 200,
		DRAG_MULTIPLIER: 2,
		DRAG_THRESHOLD: 5,
		ARROW_VISIBILITY_THRESHOLD: 5
	},
	TIMEOUTS: {
		ARROW_UPDATE: 300,
		HASH_SCROLL: 500
	},
	CLASSES: {
		ACTIVE: 'active',
		DRAGGING: 'dragging',
		SHOW_ALL: 'show-all',
		VISIBLE: 'visible',
		STATIC_GROUP_CHILD: 'tabs-static--group-child',
		STATIC_GROUP_ITEM: 'tabs-static-dropdown-item--nested',
		STATIC_GROUP_DIVIDER: 'tabs-static-dropdown-item--group-end',
		STATIC_BREADCRUMB_SEPARATOR: 'tabs-static-dropdown-separator',
		STATIC_GROUP_ICON: 'tabs-static-dropdown-item-icon'
	},
	ICONS: {
		CHEVRON_RIGHT: 'fas fa-chevron-right fa-xs'
	}
};

/**
 * Utilities for DOM manipulation and element creation
 */
class TabsDOMUtils {
	static createElement( tag, attributes = {}, children = [] ) {
		const element = document.createElement( tag );

		for ( const [ key, value ] of Object.entries( attributes ) ) {
			if ( key === 'style' && typeof value === 'object' ) {
				Object.assign( element.style, value );
			} else if ( key === 'dataset' && typeof value === 'object' ) {
				Object.assign( element.dataset, value );
			} else if ( key === 'innerHTML' ) {
				element.innerHTML = value;
			} else {
				element.setAttribute( key, value );
			}
		}

		if ( Array.isArray( children ) ) {
			for ( const child of children ) {
				if ( child ) {
					element.appendChild( child );
				}
			}
		}

		return element;
	}
}

/**
 * Manages individual tab container instances
 */
class TabContainer {
	constructor( containerElement ) {
		this.container = containerElement;

		// Temporary solution for fighters
		this.wraps = containerElement.classList.contains( 'wraps' );

		this.navWrapper = containerElement.querySelector( TABS_CONFIG.SELECTORS.NAV_WRAPPER );
		this.navTabs = containerElement.querySelector( TABS_CONFIG.SELECTORS.NAV_TABS );
		this.contentContainer = containerElement.querySelector( TABS_CONFIG.SELECTORS.CONTENT_CONTAINER );
		this.cleanupFunctions = new Set();

		if ( !this.navTabs ) {
			return;
		}

		this.tabItems = Array.from( this.navTabs.querySelectorAll( TABS_CONFIG.SELECTORS.TAB_ITEMS ) );
		this.tabContents = this.findTabContents();

		this.dragState = {
			isDown: false,
			startX: 0,
			scrollLeft: 0,
			moved: false
		};

		this.init();
	}

	init() {
		this.indexElements();
		this._setupContentHandlers();
		this._setupScrollHandlers();
	}

	_setupContentHandlers() {
		this.createMobileHeadings();
		this.setupClickHandlers();
		this.setupKeyboardNavigation();
	}

	_setupScrollHandlers() {
		if ( !this.wraps ) {
			this.setupDragToScroll();
			this.setupArrows();
			this.scrollToActiveTab( true );
		}
	}

	findTabContents() {
		if ( this.contentContainer ) {
			return Array.from( this.contentContainer.children );
		}

		const nextSibling = this.container.nextElementSibling;
		if ( nextSibling?.classList.contains( 'tabs-content' ) ) {
			return Array.from( nextSibling.children );
		}

		return [];
	}

	indexElements() {
		this.tabItems.forEach( ( item, i ) => {
			item.dataset.count = i + 1;
		} );

		this.tabContents.forEach( ( content, i ) => {
			content.dataset.count = i + 1;
		} );
	}

	createMobileHeadings() {
		this.tabContents.forEach( ( tabContent, i ) => {
			if ( this.tabItems[ i ] ) {
				const heading = TabsDOMUtils.createElement( 'h6', {
					style: { display: 'none' },
					innerHTML: this.tabItems[ i ].innerHTML
				} );
				tabContent.insertAdjacentElement( 'afterbegin', heading );
			}
		} );
	}

	setupClickHandlers() {
		this.tabItems.forEach( ( tabItem, i ) => {
			if ( tabItem.classList.contains( TABS_CONFIG.CLASSES.ACTIVE ) && this.tabContents[ i ] ) {
				this.tabContents[ i ].classList.add( TABS_CONFIG.CLASSES.ACTIVE );
			}

			this.wrapInAnchor( tabItem );

			tabItem.addEventListener( 'click', ( event ) => {
				this.handleTabClick( event, tabItem, i );
			} );
		} );
	}

	setupKeyboardNavigation() {
		const handler = ( event ) => this.handleKeydown( event );
		this.navTabs.addEventListener( 'keydown', handler );

		this.cleanupFunctions.add( () => {
			this.navTabs.removeEventListener( 'keydown', handler );
		} );
	}

	wrapInAnchor( tabItem ) {
		if ( !tabItem.querySelector( 'a' ) ) {
			const link = TabsDOMUtils.createElement( 'a', { href: '#' }, [
				// Move existing child nodes to new anchor
				...Array.from( tabItem.childNodes )
			] );
			tabItem.appendChild( link );
		}
	}

	handleTabClick( event, tabItem, index ) {
		if ( tabItem.dataset.preventClick === 'true' ) {
			delete tabItem.dataset.preventClick;
			return;
		}

		event.preventDefault();

		this.deactivateAllTabs();
		tabItem.classList.add( TABS_CONFIG.CLASSES.ACTIVE );

		if ( tabItem.classList.contains( TABS_CONFIG.CLASSES.SHOW_ALL ) ) {
			this.showAllTabs();
		} else {
			this.showSingleTab( index );
		}

		this.scrollToActiveTab();
		liquipedia.tracker.track( 'Dynamic tabs clicked' );
	}

	handleKeydown( event ) {
		const visibleTabs = this.tabItems.filter( ( item ) => item.offsetParent !== null );
		const currentTab = event.target.closest( 'li' );

		if ( !currentTab ) {
			return;
		}

		const currentIndex = visibleTabs.indexOf( currentTab );

		const actions = {
			ArrowLeft: () => {
				this.focusTab( visibleTabs, currentIndex, -1 );
			},
			ArrowRight: () => {
				this.focusTab( visibleTabs, currentIndex, 1 );
			},
			Home: () => {
				if ( visibleTabs[ 0 ] ) {
					this.activateTabItem( visibleTabs[ 0 ] );
				}
			},
			End: () => {
				const lastTab = visibleTabs[ visibleTabs.length - 1 ];
				if ( lastTab ) {
					this.activateTabItem( lastTab );
				}
			}
		};

		const action = actions[ event.key ];
		if ( action ) {
			event.preventDefault();
			action();
		}
	}

	focusTab( tabs, currentIndex, direction ) {
		const nextIndex = ( currentIndex + direction + tabs.length ) % tabs.length;
		const nextTab = tabs[ nextIndex ];

		if ( nextTab ) {
			this.activateTabItem( nextTab );
		}
	}

	activateTabItem( tabItem ) {
		const link = tabItem.querySelector( 'a' );
		if ( link ) {
			link.focus();
			link.click();
		}
	}

	deactivateAllTabs() {
		this.tabItems.forEach( ( item ) => {
			item.classList.remove( TABS_CONFIG.CLASSES.ACTIVE );
		} );

		this.tabContents.forEach( ( content ) => {
			content.classList.remove( TABS_CONFIG.CLASSES.ACTIVE );
		} );
	}

	showSingleTab( index ) {
		const targetContent = this.tabContents[ index ];
		if ( targetContent ) {
			targetContent.classList.add( TABS_CONFIG.CLASSES.ACTIVE );
		}

		this.tabContents.forEach( ( tabContent ) => {
			const heading = tabContent.querySelector( 'h6:first-child' );
			if ( heading ) {
				heading.style.display = 'none';
			}
		} );
	}

	showAllTabs() {
		this.tabContents.forEach( ( tabContent ) => {
			tabContent.classList.add( TABS_CONFIG.CLASSES.ACTIVE );
			const heading = tabContent.querySelector( 'h6:first-child' );
			if ( heading ) {
				heading.style.display = 'block';
			}
		} );
	}

	setupDragToScroll() {
		if ( !this.navTabs ) {
			return;
		}

		const listeners = {
			mousedown: ( event ) => this.handleDragStart( event ),
			mouseleave: () => this.handleDragEnd(),
			mouseup: () => this.handleDragEnd(),
			mousemove: ( event ) => this.handleDragMove( event ),
			click: ( event ) => this.handleDragClick( event )
		};

		for ( const [ event, handler ] of Object.entries( listeners ) ) {
			const options = event === 'click';
			this.navTabs.addEventListener( event, handler, options );
		}
	}

	handleDragStart( event ) {
		this.dragState.isDown = true;
		this.navTabs.classList.add( TABS_CONFIG.CLASSES.DRAGGING );
		this.dragState.startX = event.pageX - this.navTabs.offsetLeft;
		this.dragState.scrollLeft = this.navTabs.scrollLeft;
		this.dragState.moved = false;
	}

	handleDragEnd() {
		this.dragState.isDown = false;
		this.navTabs.classList.remove( TABS_CONFIG.CLASSES.DRAGGING );
	}

	handleDragMove( event ) {
		if ( !this.dragState.isDown ) {
			return;
		}

		event.preventDefault();
		const x = event.pageX - this.navTabs.offsetLeft;
		const walk = ( x - this.dragState.startX ) * TABS_CONFIG.SCROLL.DRAG_MULTIPLIER;

		if ( Math.abs( walk ) > TABS_CONFIG.SCROLL.DRAG_THRESHOLD ) {
			this.dragState.moved = true;
		}

		this.navTabs.scrollLeft = this.dragState.scrollLeft - walk;

		if ( this.navWrapper ) {
			this.updateArrowsVisibility();
		}
	}

	handleDragClick( event ) {
		if ( this.dragState.moved ) {
			const tab = event.target.closest( 'li' );
			if ( tab ) {
				tab.dataset.preventClick = 'true';
			}
		}
	}

	setupArrows() {
		if ( !this.navWrapper || !this.navTabs ) {
			return;
		}

		const leftArrow = this.navWrapper.querySelector( TABS_CONFIG.SELECTORS.ARROW_LEFT );
		const rightArrow = this.navWrapper.querySelector( TABS_CONFIG.SELECTORS.ARROW_RIGHT );

		if ( !leftArrow || !rightArrow ) {
			return;
		}

		const updateArrows = () => this.updateArrowsVisibility();

		this.navTabs.addEventListener( 'scroll', updateArrows );
		window.addEventListener( 'resize', updateArrows );

		this.cleanupFunctions.add( () => {
			this.navTabs.removeEventListener( 'scroll', updateArrows );
			window.removeEventListener( 'resize', updateArrows );
		} );

		updateArrows();

		leftArrow.addEventListener( 'click', () => {
			this.navTabs.scrollBy( {
				left: -TABS_CONFIG.SCROLL.ARROW_STEP,
				behavior: 'smooth'
			} );
		} );

		rightArrow.addEventListener( 'click', () => {
			this.navTabs.scrollBy( {
				left: TABS_CONFIG.SCROLL.ARROW_STEP,
				behavior: 'smooth'
			} );
		} );
	}

	updateArrowsVisibility() {
		const leftArrow = this.navWrapper.querySelector( TABS_CONFIG.SELECTORS.ARROW_LEFT );
		const rightArrow = this.navWrapper.querySelector( TABS_CONFIG.SELECTORS.ARROW_RIGHT );

		if ( !leftArrow || !rightArrow ) {
			return;
		}

		const hasOverflow = this.navTabs.scrollWidth > this.navTabs.clientWidth;
		const threshold = TABS_CONFIG.SCROLL.ARROW_VISIBILITY_THRESHOLD;

		if ( hasOverflow ) {
			const isAtStart = this.navTabs.scrollLeft <= threshold;
			const isAtEnd = this.navTabs.scrollLeft + this.navTabs.clientWidth >=
				this.navTabs.scrollWidth - threshold;

			leftArrow.classList.toggle( TABS_CONFIG.CLASSES.VISIBLE, !isAtStart );
			rightArrow.classList.toggle( TABS_CONFIG.CLASSES.VISIBLE, !isAtEnd );
		} else {
			leftArrow.classList.remove( TABS_CONFIG.CLASSES.VISIBLE );
			rightArrow.classList.remove( TABS_CONFIG.CLASSES.VISIBLE );
		}
	}

	scrollToActiveTab( instant = false ) {
		const activeTab = this.navTabs.querySelector( TABS_CONFIG.SELECTORS.ACTIVE_TAB );
		if ( !activeTab ) {
			return;
		}

		const sliderWidth = this.navTabs.clientWidth;
		const itemOffset = activeTab.offsetLeft;
		const itemWidth = activeTab.clientWidth;
		const targetScroll = itemOffset - ( sliderWidth / 2 ) + ( itemWidth / 2 );

		if ( typeof this.navTabs.scrollTo === 'function' ) {
			this.navTabs.scrollTo( {
				left: targetScroll,
				behavior: instant ? 'auto' : 'smooth'
			} );
		}

		setTimeout( () => {
			if ( this.navWrapper ) {
				this.updateArrowsVisibility();
			}
		}, instant ? 0 : TABS_CONFIG.TIMEOUTS.ARROW_UPDATE );
	}

	activateTab( tabNumber ) {
		this.deactivateAllTabs();

		const activeTab = this.navTabs.querySelector( `.tab${ tabNumber }` );
		if ( activeTab ) {
			activeTab.classList.add( TABS_CONFIG.CLASSES.ACTIVE );
			this.scrollToActiveTab();
		}

		const content = this.container.querySelector( `.tabs-content > .content${ tabNumber }` );
		if ( content ) {
			content.classList.add( TABS_CONFIG.CLASSES.ACTIVE );
		}
	}

	cleanup() {
		this.cleanupFunctions.forEach( ( cleanupFn ) => cleanupFn() );
		this.cleanupFunctions.clear();
	}
}

class StaticTabContainer extends TabContainer {
	init() {
		this.indexElements();
		this._setupScrollHandlers();
		this.setupMobileDropdown();
	}

	buildBreadcrumb() {
		const labels = [];

		const activeItem = this.navTabs.querySelector( TABS_CONFIG.SELECTORS.ACTIVE_TAB );
		if ( activeItem ) {
			labels.push( ( activeItem.textContent || '' ).trim() );
		}

		let ancestor = this.container.parentElement &&
			this.container.parentElement.closest( TABS_CONFIG.SELECTORS.STATIC_CONTAINER );
		while ( ancestor ) {
			const ancestorNavTabs = ancestor.querySelector( TABS_CONFIG.SELECTORS.NAV_TABS );
			if ( ancestorNavTabs ) {
				const ancestorActive = ancestorNavTabs.querySelector( TABS_CONFIG.SELECTORS.ACTIVE_TAB );
				if ( ancestorActive ) {
					labels.unshift( ( ancestorActive.textContent || '' ).trim() );
				}
			}
			ancestor = ancestor.parentElement &&
				ancestor.parentElement.closest( TABS_CONFIG.SELECTORS.STATIC_CONTAINER );
		}

		return labels.join( ' > ' );
	}

	updateBreadcrumb() {
		const label = this.container.querySelector( TABS_CONFIG.SELECTORS.STATIC_DROPDOWN_LABEL );
		if ( label ) {
			label.textContent = this.buildBreadcrumb();
		}
	}

	setupMobileDropdown() {
		const dropdown = this.container.querySelector( TABS_CONFIG.SELECTORS.STATIC_DROPDOWN );

		if ( !dropdown ) {
			return;
		}

		this.updateBreadcrumb();

		const beforeOpenHandler = () => {
			this.updateBreadcrumb();
		};
		dropdown.addEventListener( 'dropdown:beforeopen', beforeOpenHandler );
		this.cleanupFunctions.add( () => {
			dropdown.removeEventListener( 'dropdown:beforeopen', beforeOpenHandler );
		} );
	}
}

/**
 * Manages a nested chain of static tab containers,
 * building a single unified mobile dropdown across all levels.
 */
class StaticTabsGroup {
	constructor( containers ) {
		this.containers = containers;
		this.primaryContainer = containers[ 0 ];
		containers.slice( 1 ).forEach( ( container ) => {
			container.container.classList.add( TABS_CONFIG.CLASSES.STATIC_GROUP_CHILD );
		} );
		this._buildMergedMenu();
		this._overrideBreadcrumb();
	}

	_overrideBreadcrumb() {
		this.primaryContainer.updateBreadcrumb = () => this._renderBreadcrumb();
		this._renderBreadcrumb();
	}

	_renderBreadcrumb() {
		const label = this.primaryContainer.container.querySelector( TABS_CONFIG.SELECTORS.STATIC_DROPDOWN_LABEL );
		if ( !label ) {
			return;
		}

		const nodes = [];
		this.containers.forEach( ( container ) => {
			const activeItem = container.navTabs.querySelector( TABS_CONFIG.SELECTORS.ACTIVE_TAB );
			const text = activeItem ? ( activeItem.textContent || '' ).trim() : null;
			if ( !text ) {
				return;
			}
			if ( nodes.length > 0 ) {
				const separator = document.createElement( 'i' );
				separator.className = TABS_CONFIG.CLASSES.STATIC_BREADCRUMB_SEPARATOR;
				separator.classList.add( ...TABS_CONFIG.ICONS.CHEVRON_RIGHT.split( ' ' ) );
				nodes.push( separator );
			}
			nodes.push( document.createTextNode( text ) );
		} );

		label.replaceChildren( ...nodes );
	}

	_buildMergedMenu() {
		const primaryMenu = this.primaryContainer.container.querySelector( TABS_CONFIG.SELECTORS.STATIC_DROPDOWN_MENU );
		if ( !primaryMenu ) {
			return;
		}

		const primaryList = this.primaryContainer.container.querySelector( TABS_CONFIG.SELECTORS.STATIC_DROPDOWN_LIST );
		if ( !primaryList ) {
			return;
		}

		const primarySourceItems = Array.from( primaryList.children ).filter(
			( item ) => !item.classList.contains( TABS_CONFIG.CLASSES.STATIC_GROUP_ITEM ),
		);
		const mergedItems = primarySourceItems.map( ( item ) => item.cloneNode( true ) );
		let insertionRange = mergedItems;

		this.containers.slice( 1 ).forEach( ( container, levelIndex ) => {
			const level = levelIndex + 1;
			const list = container.container.querySelector( TABS_CONFIG.SELECTORS.STATIC_DROPDOWN_LIST );
			if ( !list ) {
				return;
			}

			const sourceItems = Array.from( list.children ).filter(
				( item ) => !item.classList.contains( TABS_CONFIG.CLASSES.STATIC_GROUP_ITEM ),
			);

			const items = sourceItems.map( ( item ) => {
				const clone = item.cloneNode( true );
				clone.classList.remove( TABS_CONFIG.CLASSES.STATIC_GROUP_DIVIDER );
				clone.classList.add( TABS_CONFIG.CLASSES.STATIC_GROUP_ITEM );
				clone.style.setProperty( '--tabs-static-item-level', String( level ) );

				const icon = document.createElement( 'i' );
				icon.className = TABS_CONFIG.CLASSES.STATIC_GROUP_ICON;
				icon.classList.add( ...TABS_CONFIG.ICONS.CHEVRON_RIGHT.split( ' ' ) );
				clone.insertBefore( icon, clone.firstChild );
				return clone;
			} );

			if ( items.length > 0 ) {
				items[ items.length - 1 ].classList.add( TABS_CONFIG.CLASSES.STATIC_GROUP_DIVIDER );
			}

			const activeParent = insertionRange.find( ( item ) => item.classList.contains( TABS_CONFIG.CLASSES.ACTIVE ) );
			if ( !activeParent ) {
				return;
			}

			const insertionIndex = mergedItems.indexOf( activeParent );
			mergedItems.splice( insertionIndex + 1, 0, ...items );
			insertionRange = items;
		} );

		const lastMergedItem = mergedItems[ mergedItems.length - 1 ];
		if ( lastMergedItem ) {
			lastMergedItem.classList.remove( TABS_CONFIG.CLASSES.STATIC_GROUP_DIVIDER );
		}

		primaryList.replaceChildren( ...mergedItems );
	}
}

/**
 * Manages hash-based navigation
 */
class HashRouter {
	constructor( tabsModule ) {
		this.tabsModule = tabsModule;
		this.cleanupFunctions = new Set();
	}

	init() {
		const onHashChange = () => this.handleHashChange();
		this.handleHashChange();

		window.addEventListener( 'hashchange', onHashChange, false );
		this.cleanupFunctions.add( () => {
			window.removeEventListener( 'hashchange', onHashChange );
		} );
	}

	handleHashChange() {
		const hash = location.hash.slice( 1 );
		if ( !hash ) {
			return;
		}

		let tabNumber;
		let scrollTo;

		if ( hash.startsWith( 'tab-' ) ) {
			const hashParts = hash.split( '-scrollto-' );
			tabNumber = hashParts[ 0 ].replace( 'tab-', '' );
			scrollTo = hashParts.length === 2 ? `#${ hashParts[ 1 ] }` : null;
			this.showDynamicTab( tabNumber, scrollTo );
		} else {
			const escapedHash = hash.replace( /(\.)/g, '\\$1' );
			const element = document.getElementById( escapedHash );

			if ( element ) {
				const tabContent = element.closest( '.tabs-dynamic .tabs-content > div' );
				if ( tabContent ) {
					tabNumber = tabContent.dataset.count;
					if ( tabNumber ) {
						this.showDynamicTab( tabNumber, `#${ escapedHash }` );
					}
				}
			}
		}
	}

	showDynamicTab( tabNumber, scrollTo ) {
		let scrollToElement = null;

		if ( scrollTo ) {
			scrollToElement = document.getElementById( scrollTo.slice( 1 ) );
		}

		if ( scrollToElement ) {
			const tabsContainer = scrollToElement.closest( TABS_CONFIG.SELECTORS.DYNAMIC_CONTAINER );
			if ( tabsContainer ) {
				const container = this.tabsModule.getDynamicContainer( tabsContainer );
				if ( container ) {
					container.activateTab( tabNumber );
				}

				setTimeout( () => {
					const scrollY = window.scrollY !== undefined ? window.scrollY : window.pageYOffset;
					window.scrollTo( 0, scrollToElement.getBoundingClientRect().top + scrollY );
				}, TABS_CONFIG.TIMEOUTS.HASH_SCROLL );
			}
		} else {
			this.tabsModule.getDynamicContainers().forEach( ( container ) => {
				container.activateTab( tabNumber );
			} );
		}
	}

	cleanup() {
		this.cleanupFunctions.forEach( ( cleanupFn ) => cleanupFn() );
		this.cleanupFunctions.clear();
	}
}

/**
 * Main tabs module class
 */
class TabsModule {
	constructor() {
		this.dynamicContainers = new Map();
		this.staticContainers = new Map();
		this.hashRouter = new HashRouter( this );
	}

	init() {
		this.initializeContainers();
		this.hashRouter.init();
	}

	initializeContainers() {
		const containers = document.querySelectorAll( TABS_CONFIG.SELECTORS.DYNAMIC_CONTAINER );
		containers.forEach( ( containerElement ) => {
			const container = new TabContainer( containerElement );
			if ( container.navTabs ) {
				this.dynamicContainers.set( containerElement, container );
			}
		} );

		const staticContainers = document.querySelectorAll( TABS_CONFIG.SELECTORS.STATIC_CONTAINER );
		staticContainers.forEach( ( containerElement ) => {
			const container = new StaticTabContainer( containerElement );
			if ( container.navTabs ) {
				this.staticContainers.set( containerElement, container );
			}
		} );

		this._groupStaticContainers();
	}

	_groupStaticContainers() {
		const groupedContainers = new Set();

		this._groupNestedStaticContainers( groupedContainers );
		this._groupSiblingStaticContainers( groupedContainers );
	}

	_groupNestedStaticContainers( groupedContainers ) {
		const topLevelContainers = Array.from( this.staticContainers.keys() ).filter(
			( containerElement ) => !containerElement.parentElement?.closest( TABS_CONFIG.SELECTORS.STATIC_CONTAINER ),
		);

			topLevelContainers.forEach( ( rootElement ) => {
			if ( groupedContainers.has( rootElement ) ) {
				return;
			}

			const containerElements = [];
			let currentElement = rootElement;

			while ( currentElement ) {
				const container = this.staticContainers.get( currentElement );
				if ( !container ) {
					break;
				}

				containerElements.push( currentElement );

				currentElement = this._findNestedStaticContainer( currentElement );
			}

			this._createStaticTabsGroup( containerElements, groupedContainers );
		} );
	}

	_findNestedStaticContainer( containerElement ) {
		const directChildStatic = containerElement.querySelector( TABS_CONFIG.SELECTORS.DIRECT_CHILD_ANALYTICS_STATIC );
		if ( directChildStatic ) {
			return directChildStatic;
		}

		const contentContainer = containerElement.querySelector( TABS_CONFIG.SELECTORS.DIRECT_CHILD_TABS_CONTENT );
		if ( !contentContainer ) {
			return null;
		}

		return this._findDirectChildStaticContainer( contentContainer );
	}

	_groupSiblingStaticContainers( groupedContainers ) {
		const staticElements = Array.from( this.staticContainers.keys() );
		let group = [];

		const processGroup = () => {
			if ( group.length > 1 ) {
				this._createStaticTabsGroup( group, groupedContainers );
			}
			group = [];
		};

		staticElements.forEach( ( element ) => {
			if ( groupedContainers.has( element ) ) {
				processGroup();
				return;
			}

			const anchor = this._getStaticGroupAnchor( element );

			if ( group.length === 0 ) {
				group.push( element );
				return;
			}

			const previousAnchor = this._getStaticGroupAnchor( group[ group.length - 1 ] );
			const isAdjacentSibling = previousAnchor.parentElement === anchor.parentElement &&
				previousAnchor.nextElementSibling === anchor;

			if ( isAdjacentSibling ) {
				group.push( element );
			} else {
				processGroup();
				group.push( element );
			}
		} );

		processGroup();
	}

	_createStaticTabsGroup( elements, groupedContainers ) {
		if ( elements.length < 2 ) {
			return;
		}

		const containers = elements
			.filter( ( element ) => !groupedContainers.has( element ) )
			.map( ( element ) => this.staticContainers.get( element ) )
			.filter( Boolean );

		if ( containers.length < 2 ) {
			return;
		}

		new StaticTabsGroup( containers );
		containers.forEach( ( container ) => {
			groupedContainers.add( container.container );
		} );
	}

	_findDirectChildStaticContainer( parentElement ) {
		for ( const child of parentElement.children ) {
			if ( child.matches?.( TABS_CONFIG.SELECTORS.STATIC_CONTAINER ) ) {
				return child;
			}

			if ( child.getAttribute?.( 'data-analytics-name' ) === 'Navigation tab' ) {
				for ( const grandChild of child.children ) {
					if ( grandChild.matches?.( TABS_CONFIG.SELECTORS.STATIC_CONTAINER ) ) {
						return grandChild;
					}
				}
			}
		}

		return null;
	}

	_getStaticGroupAnchor( containerElement ) {
		const parent = containerElement.parentElement;
		if ( parent?.getAttribute( 'data-analytics-name' ) === 'Navigation tab' ) {
			return parent;
		}

		return containerElement;
	}

	getDynamicContainer( element ) {
		return this.dynamicContainers.get( element );
	}

	getDynamicContainers() {
		return Array.from( this.dynamicContainers.values() );
	}

	cleanup() {
		this.dynamicContainers.forEach( ( container ) => container.cleanup() );
		this.staticContainers.forEach( ( container ) => container.cleanup() );
		this.dynamicContainers.clear();
		this.staticContainers.clear();
		this.hashRouter.cleanup();
	}
}

liquipedia.tabs = new TabsModule();
liquipedia.core.modules.push( 'tabs' );
