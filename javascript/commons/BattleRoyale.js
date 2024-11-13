/*******************************************************************************
 * Template(s): BattleRoyale
 * Author(s): Elysienna
 ******************************************************************************/
liquipedia.battleRoyale = {

	DIRECTION_LEFT: 'left',
	DIRECTION_RIGHT: 'right',
	ICON_SORT: 'fa-arrows-alt-v',
	ICON_SORT_UP: 'fa-long-arrow-alt-up',
	ICON_SORT_DOWN: 'fa-long-arrow-alt-down',
	instancesLoaded: {},
	battleRoyaleInstances: {},
	battleRoyaleMap: {},
	gameWidth: parseFloat( getComputedStyle( document.documentElement ).fontSize ) * 9.25,

	isMobile: function() {
		return window.matchMedia( '(max-width: 767px)' ).matches;
	},

	implementOnElementResize: function( instanceId ) {
		this.instancesLoaded[ instanceId ] = false;

		// eslint-disable-next-line compat/compat
		const obs = new ResizeObserver( ( entries ) => {
			for ( const entry of entries ) {
				if ( entry.borderBoxSize[ 0 ].blockSize > 0 && !this.instancesLoaded[ instanceId ] ) {
					this.instancesLoaded[ instanceId ] = true;
					this.recheckNavigationStates( instanceId );
				}
			}
		} );
		obs.observe( document.querySelector( `[data-js-battle-royale-id=${ instanceId }]` ) );
	},

	implementOnWindowResize: function( instanceId ) {
		window.addEventListener( 'resize', () => {
			this.recheckNavigationStates( instanceId );
		} );
	},

	hasVisibleSideScrollButtons: function( table ) {
		const el = table.querySelector(
			'[data-js-battle-royale="game-nav-holder"] > [data-js-battle-royale="game-container"]'
		);
		return el.scrollWidth > el.offsetWidth;
	},

	handleWheelEvent: function( e, table ) {
		if ( this.hasVisibleSideScrollButtons( table ) ) {
			const delta = e.deltaY || e.detail || e.wheelDelta;
			const dir = delta > 0 ? this.DIRECTION_RIGHT : this.DIRECTION_LEFT;

			const gameContainer = table.querySelector( '[data-js-battle-royale="game-container"]' );

			if ( dir === this.DIRECTION_RIGHT && (
				gameContainer.scrollWidth <= gameContainer.scrollLeft + gameContainer.offsetWidth ) ||
				dir === this.DIRECTION_LEFT && gameContainer.scrollLeft === 0
			) {
				// Resume default browser scroll behavior if scrolling down and the table is already at the far right
				// or scrolling up and the table is at the far left
				return;
			}

			e.preventDefault();
			this.handleTableSideScroll( table, dir );
		}
	},

	implementScrollWheelEvent: function() {
		document.querySelectorAll( '[data-js-battle-royale="game-nav-holder"]' ).forEach( ( el ) => {
			const table = el.closest( '[data-js-battle-royale="table"]' );
			const gameContainerElements = table.querySelectorAll(
				'[data-js-battle-royale="row"] > [data-js-battle-royale="game-container"]'
			);

			el.addEventListener( 'wheel', ( e ) => this.handleWheelEvent( e, table ) );
			gameContainerElements.forEach( ( gameContainer ) => {
				gameContainer.addEventListener( 'wheel', ( e ) => this.handleWheelEvent( e, table ) );
			} );
		} );
	},

	implementScrollendEvent: function( instanceId ) {
		if ( !( 'onscrollend' in window ) || typeof window.onscrollend === 'undefined' ) {
			this.battleRoyaleInstances[ instanceId ].querySelectorAll( '[data-js-battle-royale="game-nav-holder"]' )
				.forEach( ( tableEl ) => {
					const scrollingEl = tableEl.querySelector( '[data-js-battle-royale="game-container"]' );
					const options = {
						passive: true
					};
					const scrollEnd = this.debounce( ( e ) => {
						e.target.dispatchEvent( new CustomEvent( 'scrollend', {
							bubbles: true
						} ) );
					}, 100 );

					scrollingEl.addEventListener( 'scroll', scrollEnd, options );
				} );
		}
	},

	debounce: function( callback, wait ) {
		let timeout;
		return function( e ) {
			clearTimeout( timeout );
			timeout = setTimeout( () => {
				callback( e );
			}, wait );
		};
	},

	handleTableSideScroll: function( tableElement, direction ) {
		tableElement.querySelectorAll( '.cell--game-container' ).forEach( ( i ) => {
			const isNav = i.parentNode.classList.contains( 'cell--game-container-nav-holder' );
			if ( direction === this.DIRECTION_RIGHT ) {
				i.scrollLeft += this.gameWidth;
				if ( isNav ) {
					this.onScrollEndSideScrollButtonStates( tableElement );
				}
			} else {
				i.scrollLeft -= this.gameWidth;
				if ( isNav ) {
					this.onScrollEndSideScrollButtonStates( tableElement );
				}
			}
		} );
	},

	onScrollEndSideScrollButtonStates: function( tableElement ) {
		tableElement.querySelector( '.cell--game-container' ).addEventListener( 'scrollend', () => {
			this.recheckSideScrollButtonStates( tableElement );
		}, {
			once: true
		} );
	},

	recheckNavigationStates: function( instanceId ) {
		if ( this.isMobile() ) {
			return;
		}
		this.battleRoyaleInstances[ instanceId ]
			.querySelectorAll( '[data-js-battle-royale="game-nav-holder"]' )
			.forEach( ( tableEl ) => {
				this.recheckSideScrollButtonStates( tableEl );
				this.recheckSideScrollHintElements( tableEl.closest( '[data-js-battle-royale="table"]' ) );
			} );

	},

	recheckSideScrollButtonStates: function( tableElement ) {
		const navLeft = tableElement.querySelector( '[data-js-battle-royale="navigate-left"]' );
		const navRight = tableElement.querySelector( '[data-js-battle-royale="navigate-right"]' );
		const el = tableElement.querySelector(
			'[data-js-battle-royale="game-nav-holder"] > [data-js-battle-royale="game-container"]'
		);

		const isScrollable = el.scrollWidth > el.offsetWidth;
		// Check LEFT
		if ( isScrollable && el.scrollLeft > 0 ) {
			navLeft.classList.remove( 'd-none' );
		} else {
			navLeft.classList.add( 'd-none' );
		}
		// Check RIGHT
		if ( isScrollable && ( el.offsetWidth + Math.ceil( el.scrollLeft ) ) < el.scrollWidth ) {
			navRight.classList.remove( 'd-none' );
		} else {
			navRight.classList.add( 'd-none' );
		}
	},

	handleNavigationTabChange: function( instanceId, tab ) {
		this.battleRoyaleMap[ instanceId ].navigationTabs.forEach( ( item ) => {
			if ( item === tab ) {
				// activate nav tab
				item.classList.add( 'tab--active' );
			} else {
				// deactivate nav tab
				item.classList.remove( 'tab--active' );
			}
		} );
		this.battleRoyaleMap[ instanceId ].navigationContents.forEach( ( content ) => {
			if ( content.dataset.jsBattleRoyaleContentId === tab.dataset.targetId ) {
				// activate nav tab content
				content.classList.remove( 'is--hidden' );
			} else {
				// deactivate nav tab content
				content.classList.add( 'is--hidden' );
			}
		} );

		this.recheckNavigationStates( instanceId );
	},

	handlePanelTabChange: function( instanceId, contentId, panelTab ) {
		const tabs = this.battleRoyaleMap[ instanceId ].navigationContentPanelTabs[ contentId ];
		tabs.forEach( ( item ) => {
			if ( item === panelTab ) {
				// activate content tab
				item.classList.add( 'is--active' );
			} else {
				// deactivate content tab
				item.classList.remove( 'is--active' );
			}
		} );
		const contents = this.battleRoyaleMap[ instanceId ].navigationContentPanelTabContents[ contentId ];
		Object.keys( contents ).forEach( ( panelId ) => {
			if ( panelId === panelTab.dataset.jsBattleRoyaleContentTargetId ) {
				// activate content tab panel
				contents[ panelId ].classList.remove( 'is--hidden' );
			} else {
				// deactivate content tab panel
				contents[ panelId ].classList.add( 'is--hidden' );
			}
		} );

		this.recheckNavigationStates( instanceId );
	},

	buildBattleRoyaleMap: function( id ) {
		this.battleRoyaleMap[ id ] = {
			navigationTabs: Array.from(
				this.battleRoyaleInstances[ id ].querySelectorAll( '[data-js-battle-royale="navigation-tab"]' ) ),
			navigationContents: Array.from(
				this.battleRoyaleInstances[ id ].querySelectorAll( '[data-js-battle-royale-content-id]' ) ),
			navigationContentPanelTabs: {},
			navigationContentPanelTabContents: {},
			collapsibles: []
		};

		this.battleRoyaleMap[ id ].navigationContents.forEach( ( content ) => {
			const brContentId = content.dataset.jsBattleRoyaleContentId;
			this.battleRoyaleMap[ id ].navigationContentPanelTabs[ brContentId ] =
				Array.from( content.querySelectorAll( '[data-js-battle-royale="panel-tab"]' ) );

			this.battleRoyaleMap[ id ].navigationContentPanelTabs[ brContentId ].forEach( ( node ) => {
				// Create object keys
				if ( !( brContentId in this.battleRoyaleMap[ id ].navigationContentPanelTabContents ) ) {
					this.battleRoyaleMap[ id ].navigationContentPanelTabContents[ brContentId ] = {};
				}
				this.battleRoyaleMap[ id ]
					.navigationContentPanelTabContents[ brContentId ][ node.dataset.jsBattleRoyaleContentTargetId ] =
					content.querySelector( '#' + node.dataset.jsBattleRoyaleContentTargetId );

				// Query all collapsible elements and push it to the array
				const collapsibleElements = this.battleRoyaleMap[ id ]
					.navigationContentPanelTabContents[ brContentId ][ node.dataset.jsBattleRoyaleContentTargetId ]
					.querySelectorAll( '[data-js-battle-royale="collapsible"]' );

				this.battleRoyaleMap[ id ].collapsibles.push( ...collapsibleElements );
			} );
		} );
	},

	attachHandlers: function( id ) {
		this.battleRoyaleMap[ id ].navigationTabs.forEach( ( tab ) => {
			tab.addEventListener( 'click', () => {
				this.handleNavigationTabChange( id, tab );
			} );
		} );

		Object.keys( this.battleRoyaleMap[ id ].navigationContentPanelTabs ).forEach( ( contentId ) => {
			this.battleRoyaleMap[ id ].navigationContentPanelTabs[ contentId ].forEach( ( panelTab ) => {
				panelTab.addEventListener( 'click', () => {
					this.handlePanelTabChange( id, contentId, panelTab );
				} );
			} );
		} );
	},

	makeCollapsibles: function ( id ) {
		this.battleRoyaleMap[ id ].collapsibles.forEach( ( element ) => {
			const button = element.querySelector( '[data-js-battle-royale="collapsible-button"]' );
			if ( button && element ) {
				button.addEventListener( 'click', () => {
					element.classList.toggle( 'is--collapsed' );
				} );
			}
		} );
	},

	createScrollHintElement: function( dir ) {
		const element = document.createElement( 'div' );
		element.classList.add( 'panel-table__swipe-hint', `swipe-hint--${ dir }`, 'd-none' );
		element.setAttribute( 'data-js-battle-royale', 'swipe-hint-' + dir );

		const icon = document.createElement( 'i' );
		icon.classList.add( 'fas', `fa-chevron-${ dir }` );
		element.append( icon );
		return element;
	},

	makeTableScrollHint: function( instanceId ) {
		this.battleRoyaleInstances[ instanceId ]
			.querySelectorAll( '[data-js-battle-royale="table"]' ).forEach( ( table ) => {
				const swipeHintLeft = this.createScrollHintElement( this.DIRECTION_LEFT );
				const swipeHintRight = this.createScrollHintElement( this.DIRECTION_RIGHT );
				table.prepend( swipeHintLeft, swipeHintRight );

				table.addEventListener( 'scroll', () => {
					this.recheckSideScrollHintElements( table );
				} );
				this.recheckSideScrollHintElements( table );
			} );
	},

	recheckSideScrollHintElements: function( table ) {
		const swipeHintLeft = table.querySelector( '[data-js-battle-royale="swipe-hint-left"]' );
		const swipeHintRight = table.querySelector( '[data-js-battle-royale="swipe-hint-right"]' );

		// Added a padding of 5px to prevent rounding errors
		if ( table.scrollLeft > 5 ) {
			swipeHintLeft.style.left = table.scrollLeft + 'px';
			if ( swipeHintLeft.classList.contains( 'd-none' ) ) {
				swipeHintLeft.classList.remove( 'd-none' );
			}
		} else {
			if ( !swipeHintLeft.classList.contains( 'd-none' ) ) {
				swipeHintLeft.classList.add( 'd-none' );
			}
		}
		if ( table.scrollLeft >= table.scrollWidth - table.offsetWidth - 5 ) {
			if ( !swipeHintRight.classList.contains( 'd-none' ) ) {
				swipeHintRight.classList.add( 'd-none' );
			}
		} else {
			swipeHintRight.style.right = ( table.scrollLeft * -1 ) + 'px';
			if ( swipeHintRight.classList.contains( 'd-none' ) ) {
				swipeHintRight.classList.remove( 'd-none' );
			}
		}
	},

	createNavigationElement: function( dir ) {
		const element = document.createElement( 'div' );
		element.classList.add( 'panel-table__navigate', 'navigate--' + dir );
		element.setAttribute( 'data-js-battle-royale', 'navigate-' + dir );

		const icon = document.createElement( 'i' );
		icon.classList.add( 'fas', `fa-chevron-${ dir }` );
		element.append( icon );
		return element;
	},

	makeSideScrollElements: function( id ) {
		this.battleRoyaleInstances[ id ].querySelectorAll( '[data-js-battle-royale="table"]' ).forEach( ( table ) => {
			const navHolder = table.querySelector( '.row--header > .cell--game-container-nav-holder' );
			if ( navHolder ) {
				for ( const dir of [ this.DIRECTION_LEFT, this.DIRECTION_RIGHT ] ) {
					const element = this.createNavigationElement( dir );
					element.addEventListener( 'click', () => {
						this.handleTableSideScroll( table, dir );
					} );
					navHolder.appendChild( element );
				}
				this.recheckSideScrollButtonStates( navHolder );
			}
		} );

	},

	getSortingIcon: function( element ) {
		return element.querySelector( '[data-js-battle-royale="sort-icon"]' );
	},

	changeButtonStyle: function( button, order = 'default' ) {
		const sortingOrder = {
			ascending: this.ICON_SORT_DOWN,
			descending: this.ICON_SORT_UP,
			default: this.ICON_SORT
		};

		button.setAttribute( 'data-order', order );

		const sortIcon = this.getSortingIcon( button );
		sortIcon.removeAttribute( 'class' );
		sortIcon.classList.add( 'far', sortingOrder[ order ] );
	},

	comparator: function ( a, b, dir = 'ascending', sortType = 'team' ) {
		let valA = a.querySelector( `[data-sort-type='${ sortType }']` ).dataset.sortVal;
		let valB = b.querySelector( `[data-sort-type='${ sortType }']` ).dataset.sortVal;

		if ( sortType !== 'team' ) {
			valA = parseInt( valA );
			valB = parseInt( valB );
		}

		if ( dir === 'ascending' ) {
			return valB > valA ? -1 : ( valA > valB ? 1 : 0 );
		} else {
			return valB < valA ? -1 : ( valA < valB ? 1 : 0 );
		}
	},

	makeSortableTable: function( instance ) {
		const sortButtons = instance.querySelectorAll( '[data-js-battle-royale="header-row"] > [data-sort-type]' );

		sortButtons.forEach( ( button ) => {
			button.addEventListener( 'click', () => {
				const sortType = button.dataset.sortType;
				const table = button.closest( '[data-js-battle-royale="table"]' );
				const sortableRows = Array.from( table.querySelectorAll( '[data-js-battle-royale="row"]' ) );

				/**
				 * Check on dataset for descending/ascending order
				 */
				const expr = button.getAttribute( 'data-order' );
				const newOrder = expr === 'ascending' ? 'descending' : 'ascending';
				for ( const b of sortButtons ) {
					this.changeButtonStyle( b, 'default' );
				}
				this.changeButtonStyle( button, newOrder );
				const sorted = sortableRows.sort( ( a, b ) => this.comparator( a, b, newOrder, sortType ) );

				sorted.forEach( ( element, index ) => {
					if ( element.style.order ) {
						element.style.removeProperty( 'order' );
					}
					element.style.order = index.toString();
				} );
			} );
		} );
	},

	createBottomNav( instanceId, navigationTab, currentPanelIndex ) {
		const contentPanel = Object.values(
			this.battleRoyaleMap[ instanceId ].navigationContentPanelTabContents[ navigationTab ]
		)[ currentPanelIndex ];
		const navPanels = this.battleRoyaleMap[ instanceId ].navigationContentPanelTabs[ navigationTab ];
		if ( navPanels.length <= 1 ) {
			return;
		}

		const element = document.createElement( 'div' );
		element.classList.add( 'panel-content__bottom-navigation' );
		element.setAttribute( 'data-js-battle-royale', 'bottom-nav' );
		if ( currentPanelIndex !== 0 ) {
			element.append(
				this.createBottomNavLink(
					instanceId, navigationTab, navPanels[ currentPanelIndex - 1 ], this.DIRECTION_LEFT
				)
			);
		}
		if ( currentPanelIndex < navPanels.length - 1 ) {
			element.append(
				this.createBottomNavLink(
					instanceId, navigationTab, navPanels[ currentPanelIndex + 1 ], this.DIRECTION_RIGHT
				)
			);
		}
		contentPanel.append( element );
	},

	createBottomNavLink: function( instanceId, navigationTab, destinationPanel, direction = this.DIRECTION_LEFT ) {
		const element = document.createElement( 'div' );
		element.classList.add( 'panel-content__bottom-navigation__link', `navigate--${ direction }` );
		element.setAttribute( 'data-js-battle-royale', `bottom-nav-${ direction }` );
		element.setAttribute( 'tabindex', '0' );

		const textElement = document.createElement( 'span' );
		textElement.setAttribute( 'data-js-battle-royale', `bottom-nav-${ direction }-text` );
		textElement.innerText = destinationPanel.innerText;

		const icon = document.createElement( 'i' );
		icon.classList.add( 'fas', `fa-arrow-${ direction }`, 'panel-content__bottom-navigation__icon' );
		icon.setAttribute( 'data-js-battle-royale', `bottom-nav-${ direction }-icon` );
		element.append( textElement, icon );

		element.addEventListener( 'click', () => {
			this.handlePanelTabChange( instanceId, navigationTab, destinationPanel );
		} );

		return element;
	},

	init: function() {
		Array.from( document.querySelectorAll( '[ data-js-battle-royale-id ]' ) ).forEach( ( instance ) => {
			this.battleRoyaleInstances[ instance.dataset.jsBattleRoyaleId ] = instance;

			this.makeSortableTable( instance );
		} );

		Object.keys( this.battleRoyaleInstances ).forEach( ( instanceId ) => {
			// create object based on id
			this.buildBattleRoyaleMap( instanceId );

			this.attachHandlers( instanceId );
			this.makeCollapsibles( instanceId );
			if ( !this.isMobile() ) {
				this.makeSideScrollElements( instanceId );
				this.makeTableScrollHint( instanceId );
			}

			// load the first tab for nav tabs and content tabs of all nav tabs
			const instanceElement = this.battleRoyaleInstances[ instanceId ];
			let firstTab = parseInt( instanceElement.getAttribute( 'data-js-battle-royale-init-tab' ) );
			if ( Number.isNaN( firstTab ) ) {
				firstTab = 0;
			}
			this.handleNavigationTabChange( instanceId, this.battleRoyaleMap[ instanceId ].navigationTabs[ firstTab ] );
			this.battleRoyaleMap[ instanceId ].navigationTabs.forEach( ( navTab ) => {
				const target = navTab.dataset.targetId;
				const panels = this.battleRoyaleMap[ instanceId ].navigationContentPanelTabs[ target ];

				if ( target && Array.isArray( panels ) && panels.length ) {
					// Set on first panel on init
					this.handlePanelTabChange( instanceId, target, panels[ 0 ] );
				}

				panels.forEach( ( panel, index ) => {
					this.createBottomNav( instanceId, target, index );
				} );
			} );

			if ( !this.isMobile() ) {
				this.implementScrollendEvent( instanceId );
				this.implementOnWindowResize( instanceId );
				this.implementOnElementResize( instanceId );
				this.implementScrollWheelEvent();
			}

		} );
	}
};
liquipedia.core.modules.push( 'battleRoyale' );
