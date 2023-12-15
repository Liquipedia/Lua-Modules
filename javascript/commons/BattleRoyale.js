liquipedia.battleRoyale = {

	DIRECTION_LEFT: 'left',
	DIRECTION_RIGHT: 'right',
	battleRoyaleInstances: {},
	battleRoyaleMap: {},
	gameWidth: parseFloat(getComputedStyle(document.documentElement).fontSize) * 9.25,

	implementOnWindowResize: function(instanceId) {
		window.addEventListener('resize', () => {
			this.battleRoyaleInstances[instanceId].querySelectorAll('.cell--game-container-nav-holder').forEach(tableEl => {
				this.recheckSideScrollButtonStates(tableEl);
			});
		});
	},

	implementScrollendEvent: function(instanceId) {
		if(!('onscrollend' in window) || typeof window.onscrollend === 'undefined') {
			this.battleRoyaleInstances[instanceId].querySelectorAll('.cell--game-container-nav-holder').forEach(tableEl => {
				const scrollingEl = tableEl.querySelector('.cell--game-container');
				const options = {
					passive: true
				}
				const scrollEnd = this.debounce(e => {
					e.target.dispatchEvent(new CustomEvent('scrollend', {
						bubbles: true
					}));
				}, 100);

				scrollingEl.addEventListener('scroll', scrollEnd, options);
			});
		}
	},

	debounce: function(callback, wait) {
		let timeout;
		return function(e) {
			clearTimeout(timeout);
			timeout = setTimeout(() => {
				callback(e);
			}, wait);
		}
	},

	handleTableSideScroll: function(tableElement, direction) {
		tableElement.querySelectorAll('.cell--game-container').forEach(i => {
			const isNav = i.parentNode.classList.contains('cell--game-container-nav-holder');
			if (direction === this.DIRECTION_RIGHT) {
				i.scrollLeft += this.gameWidth;
				if(isNav) {
					this.onScrollEndSideScrollButtonStates(tableElement);
				}
			} else {
				i.scrollLeft -= this.gameWidth;
				if(isNav) {
					this.onScrollEndSideScrollButtonStates(tableElement);
				}
			}
		});
	},

	onScrollEndSideScrollButtonStates: function(tableElement) {
		tableElement.querySelector('.cell--game-container').addEventListener('scrollend', () => {
			this.recheckSideScrollButtonStates(tableElement);
		}, {
			once: true
		});
	},

	recheckSideScrollButtonStates: function(tableElement) {
		const navLeft = tableElement.querySelector('.cell--game-container-nav-holder > .navigate--left');
		const navRight = tableElement.querySelector('.cell--game-container-nav-holder > .navigate--right');
		const el = tableElement.querySelector('.cell--game-container-nav-holder > .cell--game-container');

		const isScrollable = el.scrollWidth > el.offsetWidth;
		// Check LEFT
		if(isScrollable && el.scrollLeft > 0) {
			navLeft.classList.remove('d-none');
		} else {
			navLeft.classList.add('d-none');
		}
		// Check RIGHT
		if(isScrollable && (el.offsetWidth + Math.ceil(el.scrollLeft)) < el.scrollWidth) {
			navRight.classList.remove('d-none');
		} else {
			navRight.classList.add('d-none');
		}
	},

	handleNavigationTabChange: function(instanceId, tab) {
		this.battleRoyaleMap[instanceId].navigationTabs.forEach(item => {
			if (item === tab) {
				// activate nav tab
				item.classList.add('tab--active');
			} else {
				// deactivate nav tab
				item.classList.remove('tab--active');
			}
		});
		this.battleRoyaleMap[instanceId].navigationContents.forEach(content => {
			if (content.dataset.jsBattleRoyaleContentId === tab.dataset.targetId) {
				// activate nav tab content
				content.classList.remove('is--hidden');
			} else {
				// deactivate nav tab content
				content.classList.add('is--hidden');
			}
		});
	},

	handlePanelTabChange: function(instanceId, contentId, panelTab) {
		const tabs = this.battleRoyaleMap[instanceId].navigationContentPanelTabs[contentId];
		tabs.forEach(item => {
			if(item === panelTab) {
				// activate content tab
				item.classList.add('is--active');
			} else {
				// deactivate content tab
				item.classList.remove('is--active');
			}
		});
		const contents = this.battleRoyaleMap[instanceId].navigationContentPanelTabContents[contentId];
		Object.keys(contents).forEach(panelId => {
			if(panelId === panelTab.dataset.jsBattleRoyaleContentTargetId) {
				// activate content tab panel
				contents[panelId].classList.remove('is--hidden');
			} else {
				// deactivate content tab panel
				contents[panelId].classList.add('is--hidden');
			}
		})
	},

	buildBattleRoyaleMap: function(id) {
		this.battleRoyaleMap[id] = {
			navigationTabs: Array.from(this.battleRoyaleInstances[id].querySelectorAll('[data-js-battle-royale="navigation-tab"]')),
			navigationContents: Array.from(this.battleRoyaleInstances[id].querySelectorAll('[data-js-battle-royale-content-id]')),
			navigationContentPanelTabs: {},
			navigationContentPanelTabContents: {},
			collapsibles: [],
		};

		this.battleRoyaleMap[id].navigationContents.forEach(content => {
			// content.classList.add('is--hidden');
			const brContentId = content.dataset.jsBattleRoyaleContentId;
			this.battleRoyaleMap[id].navigationContentPanelTabs[brContentId] =
				Array.from(content.querySelectorAll('[data-js-battle-royale="panel-tab"]'));

			this.battleRoyaleMap[id].navigationContentPanelTabs[brContentId].forEach(node => {
				// Create object keys
				if(!(brContentId in this.battleRoyaleMap[id].navigationContentPanelTabContents)) {
					this.battleRoyaleMap[id].navigationContentPanelTabContents[brContentId] = {};
				}
				this.battleRoyaleMap[id].navigationContentPanelTabContents[brContentId][node.dataset.jsBattleRoyaleContentTargetId] =
					content.querySelector('#'+node.dataset.jsBattleRoyaleContentTargetId);

				// Query all collapsible elements and push it to the array
				let collapsibleElements = this.battleRoyaleMap[id].navigationContentPanelTabContents[brContentId]
					[node.dataset.jsBattleRoyaleContentTargetId].querySelectorAll('[data-js-battle-royale="collapsible"]');

				this.battleRoyaleMap[id].collapsibles.push(...collapsibleElements);
			});
		});
	},

	attachHandlers: function(id) {
		this.battleRoyaleMap[id].navigationTabs.forEach(tab => {
			tab.addEventListener('click', () => {
				this.handleNavigationTabChange(id, tab)
			});
		});

		Object.keys(this.battleRoyaleMap[id].navigationContentPanelTabs).forEach(contentId => {
			this.battleRoyaleMap[id].navigationContentPanelTabs[contentId].forEach(panelTab => {
				panelTab.addEventListener('click', () => {
					this.handlePanelTabChange(id, contentId, panelTab)
				});
			});
		});
	},

	makeCollapsibles: function (id) {
		this.battleRoyaleMap[id].collapsibles.forEach(element => {
			const button = element.querySelector('[data-js-battle-royale="collapsible-button"]');
			if (button && element) {
				button.addEventListener('click', () => {
					element.classList.toggle('is--collapsed');
				});
			}
		});
	},

	makeSideScrollElements: function(id) {
		this.battleRoyaleInstances[id].querySelectorAll('.panel-table').forEach(table => {
			const navHolder = table.querySelector('.row--header > .cell--game-container-nav-holder');
			if(navHolder) {
				for (let dir of [this.DIRECTION_LEFT, this.DIRECTION_RIGHT]) {
					const element = document.createElement('div');
					element.classList.add('panel-table__navigate', 'navigate--' + dir);
					element.setAttribute('data-js-battle-royale', 'navigate-' + dir);
					element.innerText = dir === this.DIRECTION_RIGHT ? '>' : '<';
					element.addEventListener('click', () => {
						this.handleTableSideScroll(table, dir);
					});
					navHolder.appendChild(element);
				}
				this.recheckSideScrollButtonStates(navHolder);
			}
		})

	},

	getSortingIcon: function(element) {
		return element.querySelector('[data-js-battle-royale="sort-icon"]');
	},

	changeButtonStyle: function(button, order = 'default') {
		const sortingOrder = {
			'ascending': 'fa-sort-down',
			'descending': 'fa-sort-up',
			'default': 'fa-sort'
		}

		button.setAttribute('data-order', order);

		let sortIcon = this.getSortingIcon(button);
		sortIcon.removeAttribute('class');
		sortIcon.classList.add('fas', sortingOrder[order]);
	},

	comparator: function (a, b, dir = 'ascending', sortType = 'team') {
		let valA = a.querySelector(`[data-sort-type='${sortType}']`).dataset.sortVal;
		let valB = b.querySelector(`[data-sort-type='${sortType}']`).dataset.sortVal;
		if(dir === 'ascending') {
			return valB > valA ? -1 : (valA > valB ? 1 : 0);
		} else {
			return valB < valA ? -1 : (valA < valB ? 1 : 0);
		}
	},

	makeSortableTable: function(instance) {
		const sortButtons = instance.querySelectorAll('[data-js-battle-royale="header-row"] > [data-sort-type]');

		sortButtons.forEach( button => {
			button.addEventListener( 'click', () => {

				const sortType = button.dataset.sortType;
				const table = button.closest('.panel-table');
				const sortableRows = Array.from(table.querySelectorAll('[data-js-battle-royale="row"]'));

				/**
				 * Check on dataset for descending/ascending order
				 */
				const expr = button.getAttribute('data-order');
				const newOrder = expr === 'ascending' ? 'descending' : 'ascending';
				for(let b of sortButtons) {
					this.changeButtonStyle(b, 'default');
				}
				this.changeButtonStyle(button, newOrder);
				const sorted = sortableRows.sort(function(a,b) {
					return this.comparator(a,b,newOrder, sortType);
				}.bind(this));

				sorted.forEach((element, index) => {
					if (element.style.order) {
						element.style.removeProperty('order');
					}
					element.style.order = index.toString();
				});
			})
		})
	},

	init: function() {
		Array.from(document.querySelectorAll('[data-js-battle-royale-id]')).forEach(instance => {
			this.battleRoyaleInstances[instance.dataset.jsBattleRoyaleId] = instance;

			this.makeSortableTable(instance);
		});

		Object.keys(this.battleRoyaleInstances).forEach( function(instanceId) {

			// create object based on id
			this.buildBattleRoyaleMap(instanceId);

			this.attachHandlers(instanceId);
			this.makeCollapsibles(instanceId);
			this.makeSideScrollElements(instanceId);

			// load the first tab for nav tabs and content tabs of all nav tabs
			this.handleNavigationTabChange(instanceId, this.battleRoyaleMap[instanceId].navigationTabs[0]);
			this.battleRoyaleMap[instanceId].navigationTabs.forEach(navTab => {
				const target = navTab.dataset.targetId;
				const panels = this.battleRoyaleMap[instanceId].navigationContentPanelTabs[target];
				if(target && Array.isArray(panels) && panels.length) {
					this.handlePanelTabChange(instanceId, target, panels[0]);
				}
			});

			this.implementScrollendEvent(instanceId);
			this.implementOnWindowResize(instanceId);

		}.bind(this));
	},
};
liquipedia.core.modules.push( 'battleRoyale' );
liquipedia.battleRoyale.init();
