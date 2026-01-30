/*******************************************************************************
 * Description: Manages dynamic tab interfaces on Liquipedia pages, enabling
 *              tab switching, drag-to-scroll navigation, hash-based routing,
 *              responsive mobile/show-all views, and keyboard accessibility.
 ******************************************************************************/

const TABS_CONFIG = {
	SELECTORS: {
		CONTAINER: '.tabs-dynamic',
		NAV_WRAPPER: '.tabs-nav-wrapper',
		NAV_TABS: '.nav-tabs',
		CONTENT_CONTAINER: '.tabs-content',
		ARROW_LEFT: '.tabs-scroll-arrow-wrapper--left .tabs-scroll-arrow',
		ARROW_RIGHT: '.tabs-scroll-arrow-wrapper--right .tabs-scroll-arrow',
		ACTIVE_TAB: 'li.active',
		TAB_ITEMS: 'li'
	},
	SCROLL: {
		ARROW_STEP: 200,
		DRAG_MULTIPLIER: 2,
		DRAG_THRESHOLD: 5,
		ARROW_VISIBILITY_THRESHOLD: 5
	},
	TIMEOUTS: {
		INITIAL_SCROLL: 100,
		ARROW_UPDATE: 300,
		HASH_SCROLL: 500
	},
	CLASSES: {
		ACTIVE: 'active',
		DRAGGING: 'dragging',
		SHOW_ALL: 'show-all',
		VISIBLE: 'visible'
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
		this.createMobileHeadings();
		this.setupClickHandlers();
		this.setupKeyboardNavigation();
		this.setupDragToScroll();
		this.setupArrows();
		this.scrollToActiveTab( true );
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

		this.navTabs.scrollTo( {
			left: targetScroll,
			behavior: instant ? 'auto' : 'smooth'
		} );

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
			const tabsContainer = scrollToElement.closest( TABS_CONFIG.SELECTORS.CONTAINER );
			if ( tabsContainer ) {
				const container = this.tabsModule.getContainer( tabsContainer );
				if ( container ) {
					container.activateTab( tabNumber );
				}

				setTimeout( () => {
					const scrollY = window.scrollY !== undefined ? window.scrollY : window.pageYOffset;
					window.scrollTo( 0, scrollToElement.getBoundingClientRect().top + scrollY );
				}, TABS_CONFIG.TIMEOUTS.HASH_SCROLL );
			}
		} else {
			this.tabsModule.getAllContainers().forEach( ( container ) => {
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
		this.tabContainers = new Map();
		this.hashRouter = new HashRouter( this );
	}

	init() {
		this.initializeContainers();
		this.hashRouter.init();
	}

	initializeContainers() {
		const containers = document.querySelectorAll( TABS_CONFIG.SELECTORS.CONTAINER );
		containers.forEach( ( containerElement ) => {
			const container = new TabContainer( containerElement );
			if ( container.navTabs ) {
				this.tabContainers.set( containerElement, container );
			}
		} );
	}

	getContainer( element ) {
		return this.tabContainers.get( element );
	}

	getAllContainers() {
		return Array.from( this.tabContainers.values() );
	}

	cleanup() {
		this.tabContainers.forEach( ( container ) => container.cleanup() );
		this.tabContainers.clear();
		this.hashRouter.cleanup();
	}
}

liquipedia.tabs = new TabsModule();
liquipedia.core.modules.push( 'tabs' );
