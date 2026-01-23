/*******************************************************************************
 * Description: Manages dynamic tab interfaces on Liquipedia pages, enabling
 *              tab switching, drag-to-scroll navigation, hash-based routing,
 *              and responsive mobile/show-all views.
 ******************************************************************************/

const TABS_CONFIG = {
	SELECTORS: {
		CONTAINER: '.tabs-dynamic',
		NAV_WRAPPER: '.tabs-nav-wrapper',
		NAV_TABS: '.nav-tabs',
		CONTENT_CONTAINER: '.tabs-content',
		ARROW_LEFT: '.tabs-scroll-arrow.left',
		ARROW_RIGHT: '.tabs-scroll-arrow.right'
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
 * Manages individual tab container instances
 */
class TabContainer {
	constructor(containerElement) {
		this.container = containerElement;
		this.navWrapper = containerElement.querySelector(TABS_CONFIG.SELECTORS.NAV_WRAPPER);
		this.navTabs = containerElement.querySelector(TABS_CONFIG.SELECTORS.NAV_TABS);
		this.contentContainer = containerElement.querySelector(TABS_CONFIG.SELECTORS.CONTENT_CONTAINER);
		
		if (!this.navTabs) {
			return;
		}

		this.tabItems = Array.from(this.navTabs.querySelectorAll('li'));
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
		this.setupDragToScroll();
		this.setupArrows();
		this.scrollToActiveTab(true);
	}

	findTabContents() {
		if (this.contentContainer) {
			return Array.from(this.contentContainer.children);
		}

		const nextSibling = this.container.nextElementSibling;
		if (nextSibling?.classList.contains('tabs-content')) {
			return Array.from(nextSibling.children);
		}

		return [];
	}

	indexElements() {
		this.tabItems.forEach((item, i) => {
			item.dataset.count = i + 1;
		});

		this.tabContents.forEach((content, i) => {
			content.dataset.count = i + 1;
		});
	}

	createMobileHeadings() {
		this.tabContents.forEach((tabContent, i) => {
			if (this.tabItems[i]) {
				const heading = document.createElement('h6');
				heading.style.display = 'none';
				heading.innerHTML = this.tabItems[i].innerHTML;
				tabContent.insertAdjacentElement('afterbegin', heading);
			}
		});
	}

	setupClickHandlers() {
		this.tabItems.forEach((tabItem, i) => {
			if (tabItem.classList.contains(TABS_CONFIG.CLASSES.ACTIVE) && this.tabContents[i]) {
				this.tabContents[i].classList.add(TABS_CONFIG.CLASSES.ACTIVE);
			}

			this.wrapInAnchor(tabItem);

			tabItem.addEventListener('click', (event) => {
				this.handleTabClick(event, tabItem, i);
			});
		});
	}

	wrapInAnchor(tabItem) {
		if (!tabItem.querySelector('a')) {
			tabItem.innerHTML = `<a href="#">${tabItem.innerHTML}</a>`;
		}
	}

	handleTabClick(event, tabItem, index) {
		if (tabItem.dataset.preventClick === 'true') {
			delete tabItem.dataset.preventClick;
			return;
		}

		event.preventDefault();

		this.deactivateAllTabs();
		tabItem.classList.add(TABS_CONFIG.CLASSES.ACTIVE);

		if (tabItem.classList.contains(TABS_CONFIG.CLASSES.SHOW_ALL)) {
			this.showAllTabs();
		} else {
			this.showSingleTab(index);
		}

		this.scrollToActiveTab();
		liquipedia.tracker.track('Dynamic tabs clicked');
	}

	deactivateAllTabs() {
		this.tabItems.forEach((item) => {
			item.classList.remove(TABS_CONFIG.CLASSES.ACTIVE);
		});

		this.tabContents.forEach((content) => {
			content.classList.remove(TABS_CONFIG.CLASSES.ACTIVE);
		});
	}

	showSingleTab(index) {
		const targetContent = this.tabContents[index];
		if (targetContent) {
			targetContent.classList.add(TABS_CONFIG.CLASSES.ACTIVE);
		}

		this.tabContents.forEach((tabContent) => {
			const heading = tabContent.querySelector('h6:first-child');
			if (heading) {
				heading.style.display = 'none';
			}
		});
	}

	showAllTabs() {
		this.tabContents.forEach((tabContent) => {
			tabContent.classList.add(TABS_CONFIG.CLASSES.ACTIVE);
			const heading = tabContent.querySelector('h6:first-child');
			if (heading) {
				heading.style.display = 'block';
			}
		});
	}

	setupDragToScroll() {
		if (!this.navTabs) {
			return;
		}

		this.navTabs.addEventListener('mousedown', (event) => {
			this.handleDragStart(event);
		});

		this.navTabs.addEventListener('mouseleave', () => {
			this.handleDragEnd();
		});

		this.navTabs.addEventListener('mouseup', () => {
			this.handleDragEnd();
		});

		this.navTabs.addEventListener('mousemove', (event) => {
			this.handleDragMove(event);
		});

		this.navTabs.addEventListener('click', (event) => {
			this.handleDragClick(event);
		}, true);
	}

	handleDragStart(event) {
		this.dragState.isDown = true;
		this.navTabs.classList.add(TABS_CONFIG.CLASSES.DRAGGING);
		this.dragState.startX = event.pageX - this.navTabs.offsetLeft;
		this.dragState.scrollLeft = this.navTabs.scrollLeft;
		this.dragState.moved = false;
	}

	handleDragEnd() {
		this.dragState.isDown = false;
		this.navTabs.classList.remove(TABS_CONFIG.CLASSES.DRAGGING);
	}

	handleDragMove(event) {
		if (!this.dragState.isDown) {
			return;
		}

		event.preventDefault();
		const x = event.pageX - this.navTabs.offsetLeft;
		const walk = (x - this.dragState.startX) * TABS_CONFIG.SCROLL.DRAG_MULTIPLIER;

		if (Math.abs(walk) > TABS_CONFIG.SCROLL.DRAG_THRESHOLD) {
			this.dragState.moved = true;
		}

		this.navTabs.scrollLeft = this.dragState.scrollLeft - walk;

		if (this.navWrapper) {
			this.updateArrowsVisibility();
		}
	}

	handleDragClick(event) {
		if (this.dragState.moved) {
			const tab = event.target.closest('li');
			if (tab) {
				tab.dataset.preventClick = 'true';
			}
		}
	}

	setupArrows() {
		if (!this.navWrapper || !this.navTabs) {
			return;
		}

		const leftArrow = this.navWrapper.querySelector(TABS_CONFIG.SELECTORS.ARROW_LEFT);
		const rightArrow = this.navWrapper.querySelector(TABS_CONFIG.SELECTORS.ARROW_RIGHT);

		if (!leftArrow || !rightArrow) {
			return;
		}

		const updateArrows = () => this.updateArrowsVisibility();

		this.navTabs.addEventListener('scroll', updateArrows);
		window.addEventListener('resize', updateArrows);
		updateArrows();

		leftArrow.addEventListener('click', () => {
			this.navTabs.scrollBy({
				left: -TABS_CONFIG.SCROLL.ARROW_STEP,
				behavior: 'smooth'
			});
		});

		rightArrow.addEventListener('click', () => {
			this.navTabs.scrollBy({
				left: TABS_CONFIG.SCROLL.ARROW_STEP,
				behavior: 'smooth'
			});
		});
	}

	updateArrowsVisibility() {
		const leftArrow = this.navWrapper.querySelector(TABS_CONFIG.SELECTORS.ARROW_LEFT);
		const rightArrow = this.navWrapper.querySelector(TABS_CONFIG.SELECTORS.ARROW_RIGHT);

		if (!leftArrow || !rightArrow) {
			return;
		}

		const hasOverflow = this.navTabs.scrollWidth > this.navTabs.clientWidth;
		const threshold = TABS_CONFIG.SCROLL.ARROW_VISIBILITY_THRESHOLD;

		if (hasOverflow) {
			if (this.navTabs.scrollLeft > threshold) {
				leftArrow.classList.add(TABS_CONFIG.CLASSES.VISIBLE);
			} else {
				leftArrow.classList.remove(TABS_CONFIG.CLASSES.VISIBLE);
			}

			if (this.navTabs.scrollLeft + this.navTabs.clientWidth < this.navTabs.scrollWidth - threshold) {
				rightArrow.classList.add(TABS_CONFIG.CLASSES.VISIBLE);
			} else {
				rightArrow.classList.remove(TABS_CONFIG.CLASSES.VISIBLE);
			}
		} else {
			leftArrow.classList.remove(TABS_CONFIG.CLASSES.VISIBLE);
			rightArrow.classList.remove(TABS_CONFIG.CLASSES.VISIBLE);
		}
	}

	scrollToActiveTab(instant = false) {
		const activeTab = this.navTabs.querySelector(`li.${TABS_CONFIG.CLASSES.ACTIVE}`);
		if (!activeTab) {
			return;
		}

		const sliderWidth = this.navTabs.clientWidth;
		const itemOffset = activeTab.offsetLeft;
		const itemWidth = activeTab.clientWidth;
		const targetScroll = itemOffset - (sliderWidth / 2) + (itemWidth / 2);

		this.navTabs.scrollTo({
			left: targetScroll,
			behavior: instant ? 'auto' : 'smooth'
		});

		setTimeout(() => {
			if (this.navWrapper) {
				this.updateArrowsVisibility();
			}
		}, instant ? 0 : TABS_CONFIG.TIMEOUTS.ARROW_UPDATE);
	}

	activateTab(tabNumber) {
		this.deactivateAllTabs();

		const activeTab = this.navTabs.querySelector(`.tab${tabNumber}`);
		if (activeTab) {
			activeTab.classList.add(TABS_CONFIG.CLASSES.ACTIVE);
			this.scrollToActiveTab();
		}

		const content = this.container.querySelector(`.tabs-content > .content${tabNumber}`);
		if (content) {
			content.classList.add(TABS_CONFIG.CLASSES.ACTIVE);
		}
	}
}

/**
 * Manages hash-based navigation
 */
class HashRouter {
	constructor(tabsModule) {
		this.tabsModule = tabsModule;
	}

	init() {
		this.handleHashChange();
		window.addEventListener('hashchange', () => this.handleHashChange(), false);
	}

	handleHashChange() {
		const hash = location.hash.slice(1);
		if (!hash) {
			return;
		}

		let tabNumber;
		let scrollTo;

		if (hash.startsWith('tab-')) {
			const hashParts = hash.split('-scrollto-');
			tabNumber = hashParts[0].replace('tab-', '');
			scrollTo = hashParts.length === 2 ? `#${hashParts[1]}` : null;
			this.showDynamicTab(tabNumber, scrollTo);
		} else {
			const escapedHash = hash.replace(/(\.)/g, '\\$1');
			const element = document.getElementById(escapedHash);

			if (element) {
				const tabContent = element.closest('.tabs-dynamic .tabs-content > div');
				if (tabContent) {
					tabNumber = tabContent.dataset.count;
					if (tabNumber) {
						this.showDynamicTab(tabNumber, `#${escapedHash}`);
					}
				}
			}
		}
	}

	showDynamicTab(tabNumber, scrollTo) {
		let scrollToElement = null;

		if (scrollTo) {
			scrollToElement = document.getElementById(scrollTo.slice(1));
		}

		if (scrollToElement) {
			const tabsContainer = scrollToElement.closest('.tabs-dynamic');
			if (tabsContainer) {
				const container = this.tabsModule.tabContainers.get(tabsContainer);
				if (container) {
					container.activateTab(tabNumber);
				}

				setTimeout(() => {
					const scrollY = window.scrollY !== undefined ? window.scrollY : window.pageYOffset;
					window.scrollTo(0, scrollToElement.getBoundingClientRect().top + scrollY);
				}, TABS_CONFIG.TIMEOUTS.HASH_SCROLL);
			}
		} else {
			this.tabsModule.tabContainers.forEach((container) => {
				container.activateTab(tabNumber);
			});
		}
	}
}

/**
 * Main tabs module class
 */
class TabsModule {
	constructor() {
		this.tabContainers = new Map();
		this.hashRouter = new HashRouter(this);
	}

	init() {
		this.initializeContainers();
		this.hashRouter.init();
	}

	initializeContainers() {
		const containers = document.querySelectorAll(TABS_CONFIG.SELECTORS.CONTAINER);
		containers.forEach((containerElement) => {
			const container = new TabContainer(containerElement);
			if (container.navTabs) {
				this.tabContainers.set(containerElement, container);
			}
		});
	}

	cleanup() {
		this.tabContainers.clear();
	}
}

// Export for liquipedia integration
liquipedia.tabs = new TabsModule();
liquipedia.core.modules.push('tabs');
