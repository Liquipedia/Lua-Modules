/*******************************************************************************
 * Template(s): BattleRoyale
 * Author(s): Elysienna
 * Description: This script manages the Battle Royale interface, including
 *              navigation, tab handling, and dynamic content loading. It
 *              ensures proper display and interaction of game tabs, panels,
 *              and collapsible elements within the Battle Royale map.
 ******************************************************************************/
/**
 * Example of a Battle Royale Map:
 * {
 *   "bxishKhYAc": {
 *     "collapsibles": [HTMLElement, HTMLElement, HTMLElement],
 *     "gamePanels": {
 *       "navigationContent1": {
 *         {"bxishKhYAc_R01-M001panel0": HTMLElement},
 *         {"bxishKhYAc_R01-M001panel1": HTMLElement},
 *         {"bxishKhYAc_R01-M001panel2": HTMLElement},
 *         {"bxishKhYAc_R01-M001panel3": HTMLElement},
 *       }
 *     },
 *     "gameTabs": {
 *       {"navigationContent1": [HTMLElement, HTMLElement, HTMLElement, HTMLElement]}
 *     },
 *     "matchButtons": [HTMLElement, HTMLElement, HTMLElement],
 *     "matchContents": [HTMLElement, HTMLElement, HTMLElement]
 *   }
 * }
 *
 * collapsibles: Array of collapsible elements within the Battle Royale instance.
 * gamePanels: Object containing game panels for each match.
 * gameTabs: Object containing the game tabs for each match.
 * matchButtons: Array of match buttons.
 * matchContents: Array of match content elements.
 *
 *
 * Every BR instance has data attribute `data-js-battle-royale-id` with a unique id.
 * This id is used to store the instance in the battleRoyaleInstances object.
 * It is also used to create the battleRoyaleMap object.
 *
 * Inside every id instance, there are multiple elements that are used to create the battleRoyaleMap object.
 * At the top level you have the match buttons and the match content.
 * Inside the match content you find the game tabs and the game panels.
 *
 * Match buttons are the navigation tabs at the top of the BR instance.
 * They contain a data attribute like `data-target-id="navigationContent1"` which is used to link to the match content.
 * And a data attribute like `data-js-battle-royale-matchid="R1M1"` which is used to link to the match id.
 *
 * Match Content is the content that is displayed when a match button is clicked and has a data attribute like
 * `data-js-battle-royale-content-id="navigationContent1"`. That is the same value as the match button data-target-id.
 * Each match content contains game tabs and game panels.
 *
 * Game tabs are the tabs that are displayed when a match content is clicked.
 * They contain a data attribute like `data-js-battle-royale-content-target-id="panel1"` which is used to link to the
 * game panel.
 * On init, only the first game tab is loaded. Which usually is the overall standings tab.
 * When you click on one of the game tabs (except for first), an api call is made to load all games for that match.
 * It will set the loadedTabs[instanceId] to true to prevent calling the games again.
 * The panels that are not selected are hidden with `is--hidden` class.
 *
 * Table
 * The table is the main element that contains the game data.
 * It has a data attribute `data-js-battle-royale="table"`.
 * Inside the table, you have the header row and the row elements.
 * The header row contains the sorting buttons. The sorting buttons have a data attribute `data-sort-type="x"`.
 * The row elements contain the data for the games. The data is sorted by the data-sort-val attribute. They also have
 * a data-sort-type attribute to link to the sorting buttons.
 * With inline css the order of the rows is set to the index of the row.
 * The table contains the game nav holder with the horizontally scrollable game container
 * (`data-js-battle-royale="game-container"`).
 * The game container has a scroll event listener to check side scroll buttons.
 * The table also includes swipe hint elements and side scroll buttons for horizontal scrolling.
 *
 * Collapsibles
 * Are created on init and when new game tabs are loaded, can be collapsed to show less information.
 * The wrapper element (`data-js-battle-royale="collapsible"`) contains the button
 * `data-js-battle-royale="collapsible-button"` and the content `data-js-battle-royale="collapsible-content"`.
 *
 * Bottom navigation
 * The bottom navigation is created dynamically on init for the first panel and for the rest of the panels after the
 * api call. It contains links to the previous and next game tab.
 *
 * CreateBottomNavLinks creates the bottom navigation links.
 * The bottom navigation is added to the content panel.
 *
 */
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
	loadedTabs: {},
	isLoading: {},

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
		obs.observe( document.querySelector( `[data-js-battle-royale-id="${ instanceId }"]` ) );
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

	implementScrollendEvent: function( battleRoyaleId ) {
		if ( !( 'onscrollend' in window ) || typeof window.onscrollend === 'undefined' ) {
			this.battleRoyaleInstances[ battleRoyaleId ].querySelectorAll( '[data-js-battle-royale="game-nav-holder"]' )
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

	/**
	 * Recheck and update the state of navigation elements within the table.
	 * This function is called when the window is resized or when an element is resized to ensure
	 * that the navigation elements are correctly displayed and functional.
	 *
	 * @param {string} battleRoyaleId
	 */
	recheckNavigationStates: function( battleRoyaleId ) {
		if ( this.isMobile() ) {
			return;
		}
		this.battleRoyaleInstances[ battleRoyaleId ]
			.querySelectorAll( '[data-js-battle-royale="game-nav-holder"]' )
			.forEach( ( tableEl ) => {
				this.recheckSideScrollButtonStates( tableEl );
				this.recheckSideScrollHintElements( tableEl.closest( '[data-js-battle-royale="table"]' ) );
			} );

	},

	/**
	 * Ensure that the side scroll buttons are correctly displayed based on the current scroll position
	 * and scrollable width of the table.
	 *
	 * @param {HTMLElement} tableElement
	 */
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

	handleActiveMatchChange: function( battleRoyaleId, tab ) {
		this.battleRoyaleMap[ battleRoyaleId ].matchButtons.forEach( ( item ) => {
			if ( item === tab ) {
				// activate nav tab
				item.classList.add( 'tab--active' );
			} else {
				// deactivate nav tab
				item.classList.remove( 'tab--active' );
			}
		} );
		this.battleRoyaleMap[ battleRoyaleId ].matchContents.forEach( ( content ) => {
			if ( content.dataset.jsBattleRoyaleContentId === tab.dataset.targetId ) {
				// activate nav tab content
				content.classList.remove( 'is--hidden' );
			} else {
				// deactivate nav tab content
				content.classList.add( 'is--hidden' );
			}
		} );

		this.recheckNavigationStates( battleRoyaleId );
	},

	/**
	 * @param {string} battleRoyaleId
	 * @param {string} matchContentId
	 * @param {HTMLElement} gameTab
	 * @param {boolean} loadTemplate
	 *
	 * Set loadTemplate to false if you don't want to load the template.
	 */
	handleGameTabChange: function( battleRoyaleId, matchContentId, gameTab, loadTemplate = true ) {
		const matchButton = this.battleRoyaleMap[ battleRoyaleId ].matchButtons.find(
			( button ) => button.dataset.targetId === matchContentId
		);
		const matchId = matchButton ? matchButton.dataset.jsBattleRoyaleMatchid : null;
		const gameId = gameTab.dataset.jsBattleRoyaleGameIdx;

		if ( loadTemplate && !this.loadedTabs[ battleRoyaleId ][ matchContentId ] ) {
			this.callTemplate( battleRoyaleId, matchId, gameId, matchContentId, () => {
				this.buildBattleRoyaleMapMatchContents(
					battleRoyaleId, this.battleRoyaleInstances[ battleRoyaleId ].querySelector(
						`[data-js-battle-royale-content-id="${ matchContentId }"]`
					), true
				);
				this.loadedTabs[ battleRoyaleId ][ matchContentId ] = true;
				this.updateGameTabDisplay( battleRoyaleId, matchContentId, gameTab );
				this.makeCollapsibles( battleRoyaleId );
				this.battleRoyaleMap[ battleRoyaleId ].gameTabs[ matchContentId ].forEach(
					( panel, index ) => {
						if ( index !== 0 ) {
							this.createBottomNav( battleRoyaleId, matchContentId, index );
						}
					} );

				Object.entries( this.battleRoyaleMap[ battleRoyaleId ].gamePanels[ matchContentId ] )
					.forEach( ( [ , panel ] ) => {
						this.makeSortableTableFromElement( panel );
					} );

				// Trigger countdown initialization since we have new dates
				liquipedia.countdown.init();
			} );
		} else {
			this.updateGameTabDisplay( battleRoyaleId, matchContentId, gameTab );
		}
	},

	updateGameTabDisplay: function( battleRoyaleId, matchContentId, gameTab ) {
		const gameTabs = this.battleRoyaleMap[ battleRoyaleId ].gameTabs[ matchContentId ];
		gameTabs.forEach( ( tab ) => {
			if ( tab === gameTab ) {
				// activate content tab
				tab.classList.add( 'is--active' );
			} else {
				// deactivate content tab
				tab.classList.remove( 'is--active' );
			}
		} );

		if ( this.loadedTabs[ battleRoyaleId ][ matchContentId ] ) {
			const gamePanels = this.battleRoyaleMap[ battleRoyaleId ].gamePanels[ matchContentId ];
			Object.keys( gamePanels ).forEach( ( gamePanelKey ) => {
				// match the game tab with the correct game panel
				if ( gamePanelKey === gameTab.dataset.jsBattleRoyaleContentTargetId && gamePanelKey ) {
					// activate content tab panel
					gamePanels[ gamePanelKey ].classList.remove( 'is--hidden' );
				} else {
					// deactivate content tab panel
					gamePanels[ gamePanelKey ].classList.add( 'is--hidden' );
				}
			} );
		}
		this.recheckNavigationStates( battleRoyaleId );
	},

	callTemplate: function( battleRoyaleId, matchId, gameId, matchContentId, callback ) {
		// Create a new object for the match if it doesn't exist
		if ( !this.isLoading[ battleRoyaleId ] ) {
			this.isLoading[ battleRoyaleId ] = {};
		}

		// Prevent multiple calls for the same match
		if ( this.isLoading[ battleRoyaleId ][ matchId ] ) {
			return;
		}

		this.isLoading[ battleRoyaleId ][ matchId ] = true;

		const games = Object.keys( this.battleRoyaleMap[ battleRoyaleId ].gamePanels[ matchContentId ] ).length - 1;
		let wikitext = '';
		for ( let i = 1; i <= games; i++ ) {
			wikitext += `{{ShowSingleGame|id=${ battleRoyaleId }|matchid=${ matchId }|gameidx=${ i }}}`;
		}

		const element =
			this.battleRoyaleInstances[ battleRoyaleId ].querySelector(
				`[data-js-battle-royale-content-id="${ matchContentId }"]`
			);

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
				text: wikitext,
				disabletoc: true
			} ).then( ( data ) => {
				if ( data.parse?.text?.[ '*' ] ) {
					element.insertAdjacentHTML( 'beforeend', data.parse.text[ '*' ] );
					if ( callback ) {
						callback();
					}
				}
				this.isLoading[ battleRoyaleId ][ matchId ] = false;
			} ).catch( () => {
				this.isLoading[ battleRoyaleId ][ matchId ] = false;
			} );
		} );
	},

	// Build and populate the battleRoyaleMap object with game tabs and panels.
	// This function is used twice, once on init and once after the api call.
	// Because the map needs to be updated when new gameTabs are loaded.
	buildBattleRoyaleMapMatchContents: function( battleRoyaleId, matchContent ) {
		const matchContentId = matchContent.dataset.jsBattleRoyaleContentId;
		this.battleRoyaleMap[ battleRoyaleId ].gameTabs[ matchContentId ] =
			Array.from( matchContent.querySelectorAll( '[data-js-battle-royale="panel-tab"]' ) );
		this.battleRoyaleMap[ battleRoyaleId ].gameTabs[ matchContentId ].forEach( ( node ) => {

			if ( !( matchContentId in this.battleRoyaleMap[ battleRoyaleId ].gamePanels ) ) {
				this.battleRoyaleMap[ battleRoyaleId ].gamePanels[ matchContentId ] = {};
			}
			const targetId = node.dataset.jsBattleRoyaleContentTargetId;
			this.battleRoyaleMap[ battleRoyaleId ]
				.gamePanels[ matchContentId ][ targetId ] =
				document.getElementById( targetId );

			const panel = this.battleRoyaleMap[ battleRoyaleId ]
				.gamePanels[ matchContentId ][ targetId ];

			const collapsibleElements = panel ?
				panel.querySelectorAll( '[data-js-battle-royale="collapsible"]' ) : [];

			this.battleRoyaleMap[ battleRoyaleId ].collapsibles.push( ...collapsibleElements );
		} );
	},

	buildBattleRoyaleMap: function( battleRoyaleId ) {
		this.battleRoyaleMap[ battleRoyaleId ] = {
			matchButtons: Array.from(
				this.battleRoyaleInstances[ battleRoyaleId ]
					.querySelectorAll( '[data-js-battle-royale="navigation-tab"]' ) ),
			matchContents: Array.from(
				this.battleRoyaleInstances[ battleRoyaleId ]
					.querySelectorAll( '[data-js-battle-royale-content-id]' ) ),
			gameTabs: {},
			gamePanels: {},
			collapsibles: []
		};

		this.battleRoyaleMap[ battleRoyaleId ].matchContents.forEach( ( content ) => {
			this.buildBattleRoyaleMapMatchContents( battleRoyaleId, content );
		} );
	},

	attachHandlers: function( battleRoyaleId ) {
		this.battleRoyaleMap[ battleRoyaleId ].matchButtons.forEach( ( matchButton ) => {
			matchButton.addEventListener( 'click', () => {
				this.handleActiveMatchChange( battleRoyaleId, matchButton );
			} );
		} );

		Object.keys( this.battleRoyaleMap[ battleRoyaleId ].gameTabs ).forEach( ( matchContentId ) => {
			this.battleRoyaleMap[ battleRoyaleId ].gameTabs[ matchContentId ].forEach( ( gameTab ) => {
				gameTab.addEventListener( 'click', () => {
					this.handleGameTabChange( battleRoyaleId, matchContentId, gameTab );
				} );
			} );
		} );
	},

	makeCollapsibles: function ( battleRoyaleId ) {
		this.battleRoyaleMap[ battleRoyaleId ].collapsibles.forEach( ( element ) => {
			const button = element.querySelector( '[data-js-battle-royale="collapsible-button"]' );
			if ( button && element ) {
				button.removeEventListener( 'click', this.toggleCollapse );
				button.addEventListener( 'click', this.toggleCollapse );
			}
		} );
	},

	toggleCollapse: function( element ) {
		element.target.closest( '[data-js-battle-royale="collapsible"]' ).classList.toggle( 'is--collapsed' );
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

	makeTableScrollHint: function( battleRoyaleId ) {
		this.battleRoyaleInstances[ battleRoyaleId ]
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

	/**
	 * Ensures that the side scroll hint elements are correctly displayed based on the current scroll
	 * position and scrollable width of the table.
	 *
	 * @param {HTMLElement} table
	 */
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

	makeSideScrollElements: function( battleRoyaleId ) {
		this.battleRoyaleInstances[ battleRoyaleId ].querySelectorAll( '[data-js-battle-royale="table"]' )
			.forEach( ( table ) => {
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
			valA = parseFloat( valA );
			valB = parseFloat( valB );
		}

		if ( dir === 'ascending' ) {
			return valB > valA ? -1 : ( valA > valB ? 1 : 0 );
		} else {
			return valB < valA ? -1 : ( valA < valB ? 1 : 0 );
		}
	},

	makeSortableTable: function( battleRoyaleId ) {
		this.battleRoyaleMap[ battleRoyaleId ].matchContents.forEach( ( matchContentElement ) => {
			this.makeSortableTableFromElement( matchContentElement );
		} );
	},

	makeSortableTableFromElement: function( targetElement ) {
		const sortButtons = targetElement
			.querySelectorAll( '[data-js-battle-royale="header-row"] > [data-sort-type]' );

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
			this.battleRoyaleMap[ instanceId ].gamePanels[ navigationTab ]
		)[ currentPanelIndex ];
		const navPanels = this.battleRoyaleMap[ instanceId ].gameTabs[ navigationTab ];
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
			this.handleGameTabChange( instanceId, navigationTab, destinationPanel );
		} );

		return element;
	},

	init: function() {
		Array.from( document.querySelectorAll( '[ data-js-battle-royale-id ]' ) ).forEach( ( battleRoyaleElement ) => {
			this.battleRoyaleInstances[ battleRoyaleElement.dataset.jsBattleRoyaleId ] = battleRoyaleElement;
		} );

		Object.keys( this.battleRoyaleInstances ).forEach( ( battleRoyaleId ) => {
			this.loadedTabs[ battleRoyaleId ] = {};

			// create object based on id
			this.buildBattleRoyaleMap( battleRoyaleId );

			this.attachHandlers( battleRoyaleId );
			this.makeCollapsibles( battleRoyaleId );
			this.makeSortableTable( battleRoyaleId );

			if ( !this.isMobile() ) {
				this.makeSideScrollElements( battleRoyaleId );
				this.makeTableScrollHint( battleRoyaleId );
			}

			// load the first tab for nav tabs and content tabs of all nav tabs
			const instanceElement = this.battleRoyaleInstances[ battleRoyaleId ];
			let firstTab = parseInt( instanceElement.getAttribute( 'data-js-battle-royale-init-tab' ) );
			if ( Number.isNaN( firstTab ) ) {
				firstTab = 0;
			}
			this.handleActiveMatchChange(
				battleRoyaleId, this.battleRoyaleMap[ battleRoyaleId ].matchButtons[ firstTab ]
			);
			this.battleRoyaleMap[ battleRoyaleId ].matchButtons.forEach( ( matchButton ) => {
				// get match id
				const matchId = matchButton.dataset.jsBattleRoyaleMatchid;
				const matchContentId = matchButton.dataset.targetId;
				const gameTabs = this.battleRoyaleMap[ battleRoyaleId ].gameTabs[ matchContentId ];
				this.loadedTabs[ battleRoyaleId ][ matchContentId ] = false;

				if ( matchId && matchContentId && Array.isArray( gameTabs ) && gameTabs.length ) {
					// Set on first panel on init
					this.handleGameTabChange( battleRoyaleId, matchContentId, gameTabs[ 0 ], false );
				}

				this.createBottomNav( battleRoyaleId, matchContentId, 0 );
			} );

			if ( !this.isMobile() ) {
				this.implementScrollendEvent( battleRoyaleId );
				this.implementOnWindowResize( battleRoyaleId );
				this.implementOnElementResize( battleRoyaleId );
				this.implementScrollWheelEvent();
			}
		} );
	}
};
liquipedia.core.modules.push( 'battleRoyale' );
