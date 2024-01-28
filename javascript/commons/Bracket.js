/*******************************************************************************
 * Template(s): Popups and highlighting for all Brackets
 * Author(s): FO-nTTaX, Elysienna
 ******************************************************************************/
liquipedia.bracket = {
	init: function() {
		liquipedia.bracket.popup.init();
		liquipedia.bracket.highlighting.init();
	},
	highlighting: {
		standardIcons: [
			'Arena_of_ValorLogo_std.png', // Arena of Valor
			'Battleritelogo_std.png', // Battlerite
			'Brawl_Starslogo_std.png', // Brawl Stars
			'Crossfire_logo_std.png', // Crossfire
			'Csgologo_std.png', // CS:GO
			'Csslogo_std.png', // CS:Source
			'Cstrikelogo_std.png', // CS:1.6
			'Dotalogo_std.png', // Dota 2
			'Fistlogo_std.png', // Fighting Games
			'Hotslogo_std.png', // Heroes of the Storm
			'Logo_filler_std.png', // Blank file, SC, SC2
			'LoL_Logo_std.png', // League of Legends
			'Overwatchlogo_std.png', // Overwatch
			'Quakechampionslogo_std.png', // Quake
			'Diabotical_std.png', // Diabotical
			'R6_old_logo_std.png', // Rainbow 6
			'R6Slogo_std.png', // Rainbow 6
			'Rllogo_std.png', // Rocketleague
			'SC2logo_std.png', // StarCraft II
			'TeamFortresslogo_std.png', // TeamFortress
			'Tmlogo_std.png', // TrackMania
			'VALORANT_std.png', // VALORANT
			'Warcraft_std.png', // Warcraft
			'WoWlogo_std.png' // World of Warcraft
		],
		filteredSelectors: [
			'BYE',
			'TBD',
			'TBA',
			'',
			'LOGO_FILLER_STD.PNG'
		],
		init: function() {
			liquipedia.bracket.highlighting.createBinds();
			liquipedia.bracket.highlighting.createHoverCache();
			document.querySelectorAll( 'tr.match-row' ).forEach( function( element ) {
				element.addEventListener( 'mouseover', function() {
					this.classList.add( 'bracket-hover' );
				} );
				element.addEventListener( 'mouseleave', function() {
					this.classList.remove( 'bracket-hover' );
				} );
			} );
			document.querySelectorAll( '.bracket-team-top, .bracket-team-bottom, .bracket-team-middle, .bracket-team-inner, .bracket-player-top, .bracket-player-bottom, .bracket-player-middle, .bracket-player-inner, .matchlistslot, .matchslot, .grouptableslot' ).forEach( function( element ) {
				element.addEventListener( 'mouseover', function() {
					if ( liquipedia.bracket.highlighting.filteredSelectors.indexOf( element.dataset.highlightingkey ) === -1 ) {
						liquipedia.bracket.highlighting.hoverCache[ element.dataset.highlightingkey ].forEach( function( node ) {
							node.classList.add( 'bracket-hover' );
							if ( typeof node.dataset.backgroundColorHover !== 'undefined' ) {
								node.style.backgroundColor = node.dataset.backgroundColorHover;
							}
						} );
					}
				} );
				element.addEventListener( 'mouseleave', function() {
					liquipedia.bracket.highlighting.hoverCache[ element.dataset.highlightingkey ].forEach( function( node ) {
						node.classList.remove( 'bracket-hover' );
						if ( typeof node.dataset.backgroundColor !== 'undefined' ) {
							node.style.backgroundColor = node.dataset.backgroundColor;
						}
					} );
				} );
			} );
		},
		getImageSelector: function( url ) {
			const urlparts = url.split( '/' );
			let value = urlparts[ urlparts.length - 1 ];
			value.replace( '-icon', '_std' );
			if ( value.indexOf( '-' ) !== -1 ) {
				value = value.replace( '-logo', '' ).replace( '-std', '' );
				value = value.split( '-' );
				value = value[ value.length - 1 ];
			}
			return value;
		},
		getTextSelector: function( node ) {
			const clonedNode = node.cloneNode( true );
			const children = clonedNode.querySelectorAll( 'div.bracket-score, div.team-template-team-bracket' );
			children.forEach( function( child ) {
				clonedNode.removeChild( child );
			} );
			let value = clonedNode.innerHTML;
			value = value.replace( /<.*?>/g, '' );
			value = value.replace( /&nbsp;/g, '' );
			value = value.trim();
			return value;
		},
		binds: { },
		createBinds: function() {
			const bindingtemplates = document.querySelectorAll( '.bind-highlighting' );
			bindingtemplates.forEach( function( element ) {
				const from = element.querySelector( '.bind-highlighting-from' );
				const to = element.querySelector( '.bind-highlighting-to' );
				const fromteamicon = from.querySelector( '.team-template-image img' );
				let fromselector;
				if ( fromteamicon === null ) {
					// Player highlighting
					fromselector = liquipedia.bracket.highlighting.getTextSelector( from );
				} else {
					// Team highlighting
					fromselector = liquipedia.bracket.highlighting.getImageSelector( fromteamicon.src );
					if ( liquipedia.bracket.highlighting.standardIcons.indexOf( fromselector ) !== -1 ) {
						fromselector = liquipedia.bracket.highlighting.getTextSelector( from );
					}
				}
				const toteamicon = to.querySelector( '.team-template-image img' );
				let toselector;
				if ( toteamicon === null ) {
					// Player highlighting
					toselector = liquipedia.bracket.highlighting.getTextSelector( to );
				} else {
					// Team highlighting
					toselector = liquipedia.bracket.highlighting.getImageSelector( toteamicon.src );
					if ( liquipedia.bracket.highlighting.standardIcons.indexOf( toselector ) !== -1 ) {
						toselector = liquipedia.bracket.highlighting.getTextSelector( to );
					}
				}
				liquipedia.bracket.highlighting.binds[ fromselector ] = toselector;
			} );
		},
		hoverCache: { },
		createHoverCache: function() {
			document.querySelectorAll( '.bracket-team-top, .bracket-team-bottom, .bracket-team-middle, .bracket-team-inner, .bracket-player-top, .bracket-player-bottom, .bracket-player-middle, .bracket-player-inner, .matchlistslot, .matchslot, .grouptableslot' ).forEach( function( element ) {
				const teamicon = element.querySelector( '.team-template-image img' );
				let selector;
				if ( teamicon === null ) {
					// Player highlighting
					selector = liquipedia.bracket.highlighting.getTextSelector( element );
					const backgroundcolor = element.style.backgroundColor;
					switch ( backgroundcolor ) {
						case 'rgb(242, 184, 184)':
							// Zerg/Orc
							element.dataset.backgroundColor = backgroundcolor;
							element.dataset.backgroundColorHover = 'rgb(250, 217, 217)';
							break;
						case 'rgb(184, 242, 184)':
							// Protoss/Nightelf
							element.dataset.backgroundColor = backgroundcolor;
							element.dataset.backgroundColorHover = 'rgb(217, 250, 217)';
							break;
						case 'rgb(184, 184, 242)':
							// Terran/Human
							element.dataset.backgroundColor = backgroundcolor;
							element.dataset.backgroundColorHover = 'rgb(217, 217, 250)';
							break;
						case 'rgb(242, 184, 242)':
							// Undead
							element.dataset.backgroundColor = backgroundcolor;
							element.dataset.backgroundColorHover = 'rgb(250, 217, 250)';
							break;
						case 'rgb(242, 242, 184)':
							// Random
							element.dataset.backgroundColor = backgroundcolor;
							element.dataset.backgroundColorHover = 'rgb(250, 250, 217)';
							break;
					}
				} else {
					// Team highlighting
					selector = liquipedia.bracket.highlighting.getImageSelector( teamicon.src );
					if ( liquipedia.bracket.highlighting.standardIcons.indexOf( selector ) !== -1 ) {
						selector = liquipedia.bracket.highlighting.getTextSelector( element );
					}
				}
				if ( selector in liquipedia.bracket.highlighting.binds ) {
					selector = liquipedia.bracket.highlighting.binds[ selector ];
				}
				if ( !Array.isArray( liquipedia.bracket.highlighting.hoverCache[ selector ] ) ) {
					liquipedia.bracket.highlighting.hoverCache[ selector ] = [ ];
				}
				liquipedia.bracket.highlighting.hoverCache[ selector ].push( element );
				element.dataset.highlightingkey = selector;
			} );
		}
	},
	popup: {
		init: function() {
			liquipedia.bracket.popup.createIcons();
			liquipedia.bracket.popup.createToggles();
			liquipedia.bracket.popup.createEventListeners();
		},
		popupBox: null,
		createIcons: function() {
			document.querySelectorAll( '.bracket-game' ).forEach( function( element ) {
				const popupwrapper = element.querySelector( '.bracket-popup-wrapper' );
				if ( popupwrapper !== null ) {
					const icon = document.createElement( 'div' );
					icon.classList.add( 'icon' );
					icon.style.top = ( parseInt( window.getComputedStyle( element.querySelector( ':first-child' ) ).height ) - 6 ) + 'px';
					const score = element.querySelector( '.bracket-score' );
					if ( score !== null ) {
						icon.style.right = ( parseInt( window.getComputedStyle( score ).width ) - 5 ) + 'px';
					} else {
						icon.style.right = '16px';
					}
					element.appendChild( icon );
					element.querySelectorAll( '.bracket-team-top, .bracket-team-bottom, .bracket-player-top, .bracket-player-bottom' ).forEach( function( node ) {
						node.style.cursor = 'pointer';
						node.title = 'Click for further information';
					} );
				}
			} );
			document.querySelectorAll( '.match-row' ).forEach( function( element ) {
				const popupwrapper = element.querySelector( '.bracket-popup-wrapper' );
				if ( popupwrapper !== null ) {
					const icon = document.createElement( 'div' );
					icon.style.position = 'relative';
					const iconinner = document.createElement( 'div' );
					iconinner.classList.add( 'match-row-icon' );
					icon.appendChild( iconinner );
					let iconHolder;
					let i = 0;
					element.childNodes.forEach( function( node ) {
						if ( typeof node.tagName !== 'undefined' && node.tagName.toLowerCase() === 'td' ) {
							i++;
							if ( i === 3 ) {
								iconHolder = node;
							}
						}
					} );
					iconHolder.insertBefore( icon, iconHolder.firstChild );
					element.querySelectorAll( '.matchlistslot' ).forEach( function( node ) {
						node.style.cursor = 'pointer';
						node.title = 'Click for further information';
						node.querySelectorAll( 'a' ).forEach( function( link ) {
							link.href = '#';
							link.classList.remove( 'new' );
						} );
					} );
				}
			} );
			document.querySelectorAll( '.table-battleroyale-results-round' ).forEach( function( element ) {
				const popupwrapper = element.querySelector( '.bracket-popup-wrapper' );
				if ( popupwrapper !== null ) {
					const icon = document.createElement( 'div' );
					icon.style.position = 'relative';
					const iconinner = document.createElement( 'div' );
					iconinner.classList.add( 'icon' );
					icon.appendChild( iconinner );
					element.appendChild( icon );
				}
			} );
		},
		createToggles: function() {
			document.querySelector( 'html' ).addEventListener( 'click', function( ev ) {
				if ( ev.target.closest( '.bracket-popup-wrapper' ) === null ) {
					if ( liquipedia.bracket.popup.popupBox !== null ) {
						liquipedia.bracket.popup.popupBox.querySelector( '.bracket-popup-wrapper' ).style.display = 'none';
						liquipedia.tracker.track( 'Bracket popup closed' );
						liquipedia.bracket.popup.popupBox = null;
					}
				}
			} );
			document.querySelectorAll( '.bracket-popup-wrapper' ).forEach( function( el ) {
				el.addEventListener( 'click', function( ev ) {
					ev.stopPropagation();
				} );
			} );
			document.querySelectorAll( '.bracket-team-top, .bracket-team-bottom, .bracket-team-inner, .bracket-player-top, .bracket-player-bottom, .bracket-player-inner, .bracket-game .icon' ).forEach( function( element ) {
				element.addEventListener( 'click', function( event ) {
					const newPopupWrapper = element.closest( '.bracket-game' );
					if ( liquipedia.bracket.popup.popupBox !== null ) {
						liquipedia.bracket.popup.popupBox.querySelector( '.bracket-popup-wrapper' ).style.display = 'none';
						liquipedia.tracker.track( 'Bracket popup closed' );
						if ( newPopupWrapper.isSameNode( liquipedia.bracket.popup.popupBox ) ) {
							liquipedia.bracket.popup.popupBox = null;
							return;
						}
					}
					const newPopup = newPopupWrapper.querySelector( '.bracket-popup-wrapper' );
					if ( newPopup !== null ) {
						newPopup.style.marginLeft = '';
						newPopup.style.display = 'block';
						liquipedia.bracket.popup.popupBox = newPopupWrapper;
						liquipedia.tracker.track( 'Bracket popup opened' );
					}
					liquipedia.bracket.popup.positionBracketPopup();
					event.stopPropagation();
				} );
			} );
			document.querySelectorAll( '.match-row' ).forEach( function( element ) {
				element.addEventListener( 'click', function( event ) {
					const newPopupWrapper = element;
					if ( liquipedia.bracket.popup.popupBox !== null ) {
						liquipedia.bracket.popup.popupBox.querySelector( '.bracket-popup-wrapper' ).style.display = 'none';
						liquipedia.tracker.track( 'Bracket popup closed' );
						if ( newPopupWrapper.isSameNode( liquipedia.bracket.popup.popupBox ) ) {
							liquipedia.bracket.popup.popupBox = null;
							return;
						}
					}
					const newPopup = newPopupWrapper.querySelector( '.bracket-popup-wrapper' );
					if ( newPopup !== null ) {
						newPopup.style.marginLeft = '';
						newPopup.style.display = 'block';
						liquipedia.bracket.popup.popupBox = newPopupWrapper;
						liquipedia.tracker.track( 'Bracket popup opened' );
					}
					liquipedia.bracket.popup.positionGroupTablePopup();
					event.stopPropagation();
				} );
			} );
			document.querySelectorAll( '.table-battleroyale-results-round' ).forEach( function( element ) {
				element.addEventListener( 'click', function( event ) {
					const newPopupWrapper = element;
					if ( liquipedia.bracket.popup.popupBox !== null ) {
						liquipedia.bracket.popup.popupBox.querySelector( '.bracket-popup-wrapper' ).style.display = 'none';
						liquipedia.tracker.track( 'Bracket popup closed' );
						if ( newPopupWrapper.isSameNode( liquipedia.bracket.popup.popupBox ) ) {
							liquipedia.bracket.popup.popupBox = null;
							return;
						}
					}
					const newPopup = newPopupWrapper.querySelector( '.bracket-popup-wrapper' );
					if ( newPopup !== null ) {
						newPopup.style.marginLeft = '';
						newPopup.style.display = 'block';
						liquipedia.bracket.popup.popupBox = newPopupWrapper;
						liquipedia.tracker.track( 'Bracket popup opened' );
					}
					event.stopPropagation();
				} );
			} );
		},
		positionBracketPopup: function() {
			if ( liquipedia.bracket.popup.popupBox !== null && liquipedia.bracket.popup.popupBox.querySelector( '.icon' ) !== null ) {
				const popupBox = liquipedia.bracket.popup.popupBox;
				const popup = popupBox.querySelector( '.bracket-popup-wrapper' );
				const windowWidth = parseInt( window.getComputedStyle( document.querySelector( 'html' ) ).width );
				if ( !window.matchMedia( '(max-width: 767px)' ).matches ) {
					popup.classList.remove( 'bracket-popup-mobile' );
					// const detailsHeight = parseInt( window.getComputedStyle( popup ).height );
					const detailsWidth = parseInt( window.getComputedStyle( popup ).width );
					const popupBoxPosition = popupBox.getBoundingClientRect();
					const spaceOnTheRight = windowWidth - ( popupBoxPosition.right + detailsWidth );
					// const icon = popupBox.querySelector( '.icon' );

					const bracketWrapper = popup.closest( '.bracket-wrapper' );
					const topPosition = ( popupBox.offsetHeight / 2 ) - ( popup.offsetHeight / 2 );
					// const popupBoxY = document.documentElement.scrollTop + popupBoxPosition.top;
					popup.style.top = topPosition + 'px';
					popup.style.bottom = '';

					const wrapperTop = bracketWrapper.getBoundingClientRect().top;
					const pBoxTop = popupBox.getBoundingClientRect().top;
					const popupTop = popup.getBoundingClientRect().top;
					const posDiff = pBoxTop - wrapperTop;
					const hasXScrollbar = bracketWrapper.scrollWidth > bracketWrapper.clientWidth;
					const scrollBarHeight = hasXScrollbar ?
						bracketWrapper.offsetHeight - bracketWrapper.clientHeight :
						0;

					// Add min-height to bracket-wrapper if the popup is higher than the bracket-wrapper
					if ( bracketWrapper.offsetHeight <= popup.offsetHeight + 1 ) {
						bracketWrapper.style.minHeight = popup.offsetHeight + 1 + 'px';
					} else {
						bracketWrapper.style.minHeight = '';
					}

					if ( ( posDiff ) < ( topPosition * -1 ) ) {
						// Positioned above the wrapper, move it down
						popup.style.top = ( posDiff * -1 ) + 'px';
					}
					const contentHeight = ( popupTop - wrapperTop ) + popup.offsetHeight;
					if ( contentHeight > ( bracketWrapper.offsetHeight - scrollBarHeight ) ) {
						// Positioned too low, creating overflow, move it up
						const overflow = contentHeight - bracketWrapper.offsetHeight + scrollBarHeight;
						const newposition = topPosition - ( overflow ) - 1; // -1 for rounding errors
						popup.style.top = newposition + 'px';
					}

					if ( spaceOnTheRight > 0 ) {
						popup.style.left = popupBoxPosition.width + 'px';
					} else {
						if ( popupBoxPosition.left - detailsWidth > 0 ) {
							popup.style.left = '-' + popup.clientWidth + 'px';
						} else {
							popup.style.left = popupBoxPosition.width + 'px';
						}
					}
				} else {
					popup.classList.add( 'bracket-popup-mobile' );
					popup.style.top = '';
					popup.style.left = '';
				}
			}
		},
		positionGroupTablePopup: function() {
			if ( liquipedia.bracket.popup.popupBox !== null && liquipedia.bracket.popup.popupBox.querySelector( '.match-row-icon' ) !== null ) {
				const popupBox = liquipedia.bracket.popup.popupBox;
				const popup = popupBox.querySelector( '.bracket-popup-wrapper' );
				const windowWidth = parseInt( window.getComputedStyle( document.querySelector( 'html' ) ).width );
				const mainContentCol = document.querySelector( '.main-content-column' );
				if ( windowWidth > 600 ) {
					popup.classList.remove( 'bracket-popup-mobile' );
					const detailsWidth = parseInt( window.getComputedStyle( popup ).width );
					const popupBoxPosition = popupBox.getBoundingClientRect();
					// popup.style.top = ( popupBoxPosition.top + popupBoxPosition.height ) + 'px';
					popup.style.top = document.documentElement.scrollTop + ( popupBoxPosition.bottom - mainContentCol.offsetTop ) + 'px';
					// var left = popupBoxPosition.left + popupBoxPosition.width / 2 - detailsWidth / 2;
					let left = popupBoxPosition.left - mainContentCol.getBoundingClientRect().left + ( popupBoxPosition.width / 2 - detailsWidth / 2 );
					if ( left < 10 ) {
						left = 10;
					}
					popup.style.left = left + 'px';
				} else {
					popup.classList.add( 'bracket-popup-mobile' );
					popup.style.top = '';
					popup.style.left = '';
				}
			}
		},
		createEventListeners: function() {
			if ( document.querySelector( '.bracket .bracket-popup-wrapper' ) !== null ) {
				window.addEventListener( 'scroll', liquipedia.bracket.popup.positionBracketPopup );
				const bruinenBracketScroll = document.querySelector( 'body.logged-in .scroll-logged-in, body.logged-out .scroll-logged-out' );
				if ( bruinenBracketScroll !== null ) {
					bruinenBracketScroll.addEventListener( 'scroll', liquipedia.bracket.popup.positionBracketPopup );
				}
				window.addEventListener( 'resize', liquipedia.bracket.popup.positionBracketPopup );
				document.querySelectorAll( '.bracket-wrapper' ).forEach( function( element ) {
					element.addEventListener( 'scroll', liquipedia.bracket.popup.positionBracketPopup );
				} );
			}
			if ( document.querySelector( '.matchlist .bracket-popup-wrapper' ) !== null ) {
				window.addEventListener( 'scroll', liquipedia.bracket.popup.positionGroupTablePopup );
				const bruinenGroupScroll = document.querySelector( 'body.logged-in .scroll-logged-in, body.logged-out .scroll-logged-out' );
				if ( bruinenGroupScroll !== null ) {
					bruinenGroupScroll.addEventListener( 'scroll', liquipedia.bracket.popup.positionGroupTablePopup );
				}
				window.addEventListener( 'resize', liquipedia.bracket.popup.positionGroupTablePopup );
			}
		}
	}
};
liquipedia.core.modules.push( 'bracket' );
