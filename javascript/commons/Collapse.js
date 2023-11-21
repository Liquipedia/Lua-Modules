/*******************************************************************************
 * Template(s): Toggles for templates
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.collapse = {
	init: function() {
		document.querySelectorAll( '#mw-content-text .collapsible' ).forEach( function( table, index ) {
			if ( table.classList.contains( 'autocollapse' ) && index >= 1 ) {
				table.classList.add( 'collapsed' );
			}
		} );
		liquipedia.collapse.setupCollapsibleMapsButtons();
		liquipedia.collapse.setupCollapsibleButtons();
		liquipedia.collapse.setupGeneralCollapsibleButtons();
		liquipedia.collapse.setupToggleGroups();
		liquipedia.collapse.setupDropdownBox();
		liquipedia.collapse.setupCollapsibleNavFrameButtons();
	},
	setupCollapsibleButtons: function() {
		document.querySelectorAll( '#mw-content-text .collapsible' ).forEach( function( collapsible ) {
			const row = collapsible.querySelector( 'tr' );
			if ( row !== null ) {
				const collapseShowButton = document.createElement( 'span' );
				collapseShowButton.classList.add( 'collapseButton' );
				collapseShowButton.classList.add( 'collapseButtonShow' );
				collapseShowButton.appendChild( document.createTextNode( '[' ) );
				const collapseShowLink = document.createElement( 'a' );
				collapseShowLink.href = '#';
				collapseShowLink.innerHTML = 'show';
				collapseShowLink.onclick = function( ev ) {
					ev.preventDefault();
					collapsible.classList.remove( 'collapsed' );
				};
				collapseShowButton.appendChild( collapseShowLink );
				collapseShowButton.appendChild( document.createTextNode( ']' ) );
				row.lastElementChild.insertBefore( collapseShowButton, row.lastElementChild.firstChild );
				const collapseHideButton = document.createElement( 'span' );
				collapseHideButton.classList.add( 'collapseButton' );
				collapseHideButton.classList.add( 'collapseButtonHide' );
				collapseHideButton.appendChild( document.createTextNode( '[' ) );
				const collapseHideLink = document.createElement( 'a' );
				collapseHideLink.href = '#';
				collapseHideLink.innerHTML = 'hide';
				collapseHideLink.onclick = function( ev ) {
					ev.preventDefault();
					collapsible.classList.add( 'collapsed' );
				};
				collapseHideButton.appendChild( collapseHideLink );
				collapseHideButton.appendChild( document.createTextNode( ']' ) );
				row.lastElementChild.insertBefore( collapseHideButton, row.lastElementChild.firstChild );
			}
		} );
	},

	// general-collapsible is a generalization of .collapsible that works for
	// any layout, not just tables. It requires that the collapsible
	// component supply its own expand/collapse buttons.
	//
	// Note that unlike .collapsible, the button is the anchor itself, instead
	// of a wrapper around the anchor.
	setupGeneralCollapsibleButtons: function() {

		// Replaces the button (usually a <span>) with <a href="#">...</a>.
		// For xss safety, only the child nodes and class name are copied over.
		function replaceWithAnchor( button ) {
			const anchor = document.createElement( 'a' );
			button.childNodes.forEach( function ( node ) {
				anchor.append( node );
			} );
			anchor.className = button.className;
			anchor.href = '#';
			button.parentNode.replaceChild( anchor, button );
			return anchor;
		}

		document.querySelectorAll( '#mw-content-text .general-collapsible' ).forEach( function( collapsible ) {
			const collapseButton = collapsible.querySelector( '.general-collapsible-collapse-button' );
			const expandButton = collapsible.querySelector( '.general-collapsible-expand-button' );

			if ( expandButton ) {
				const anchor = replaceWithAnchor( expandButton );
				anchor.addEventListener( 'click', function( event ) {
					collapsible.classList.remove( 'collapsed' );
					event.preventDefault();
				} );
			}

			if ( collapseButton ) {
				const anchor = replaceWithAnchor( collapseButton );
				anchor.addEventListener( 'click', function( event ) {
					collapsible.classList.add( 'collapsed' );
					event.preventDefault();
				} );
			}
		} );
	},
	setupCollapsibleMapsButtons: function() {
		document.querySelectorAll( '#mw-content-text .collapsible' ).forEach( function( collapsible ) {
			const row = collapsible.querySelector( 'tr' );
			if ( row !== null && collapsible.querySelector( '.maprow' ) !== null ) {
				const collapseShowButton = document.createElement( 'span' );
				collapseShowButton.classList.add( 'collapseButton' );
				collapseShowButton.classList.add( 'collapseButtonMapsShow' );
				collapseShowButton.appendChild( document.createTextNode( '[' ) );
				const collapseShowLink = document.createElement( 'a' );
				collapseShowLink.href = '#';
				collapseShowLink.innerHTML = '+maps';
				collapseShowLink.onclick = function( ev ) {
					ev.preventDefault();
					collapsible.classList.add( 'uncollapsed-maps' );
				};
				collapseShowButton.appendChild( collapseShowLink );
				collapseShowButton.appendChild( document.createTextNode( ']' ) );
				row.lastElementChild.insertBefore( collapseShowButton, row.lastElementChild.firstChild );
				const collapseHideButton = document.createElement( 'span' );
				collapseHideButton.classList.add( 'collapseButton' );
				collapseHideButton.classList.add( 'collapseButtonMapsHide' );
				collapseHideButton.appendChild( document.createTextNode( '[' ) );
				const collapseHideLink = document.createElement( 'a' );
				collapseHideLink.href = '#';
				collapseHideLink.innerHTML = '-maps';
				collapseHideLink.onclick = function( ev ) {
					ev.preventDefault();
					collapsible.classList.remove( 'uncollapsed-maps' );
				};
				collapseHideButton.appendChild( collapseHideLink );
				collapseHideButton.appendChild( document.createTextNode( ']' ) );
				row.lastElementChild.insertBefore( collapseHideButton, row.lastElementChild.firstChild );
			}
		} );
	},
	setupCollapsibleNavFrameButtons: function() {
		document.querySelectorAll( '#mw-content-text .NavFrame' ).forEach( function( navFrame ) {
			const head = navFrame.querySelector( '.NavHead' );
			if ( head !== null ) {
				const collapseShowButton = document.createElement( 'span' );
				collapseShowButton.classList.add( 'collapseButton' );
				collapseShowButton.classList.add( 'collapseButtonShow' );
				collapseShowButton.appendChild( document.createTextNode( '[' ) );
				const collapseShowLink = document.createElement( 'a' );
				collapseShowLink.href = '#';
				collapseShowLink.innerHTML = 'show';
				collapseShowLink.onclick = function( ev ) {
					ev.preventDefault();
					navFrame.classList.remove( 'collapsed' );
				};
				collapseShowButton.appendChild( collapseShowLink );
				collapseShowButton.appendChild( document.createTextNode( ']' ) );
				head.insertBefore( collapseShowButton, head.firstChild );
				const collapseHideButton = document.createElement( 'span' );
				collapseHideButton.classList.add( 'collapseButton' );
				collapseHideButton.classList.add( 'collapseButtonHide' );
				collapseHideButton.appendChild( document.createTextNode( '[' ) );
				const collapseHideLink = document.createElement( 'a' );
				collapseHideLink.href = '#';
				collapseHideLink.innerHTML = 'hide';
				collapseHideLink.onclick = function( ev ) {
					ev.preventDefault();
					navFrame.classList.add( 'collapsed' );
				};
				collapseHideButton.appendChild( collapseHideLink );
				collapseHideButton.appendChild( document.createTextNode( ']' ) );
				head.insertBefore( collapseHideButton, head.firstChild );
			}
		} );
	},
	setupToggleGroups: function() {
		document.querySelectorAll( '#mw-content-text .toggle-group' ).forEach( function( toggleGroup ) {
			let showAllText;
			if ( toggleGroup.dataset.showAllText !== undefined ) {
				showAllText = toggleGroup.dataset.showAllText;
			} else {
				showAllText = 'Show all';
			}
			let hideAllText;
			if ( toggleGroup.dataset.hideAllText !== undefined ) {
				hideAllText = toggleGroup.dataset.hideAllText;
			} else {
				hideAllText = 'Hide all';
			}
			const button = document.createElement( 'button' );
			if ( toggleGroup.classList.contains( 'toggle-state-hide' ) ) {
				button.innerHTML = hideAllText;
			} else {
				button.innerHTML = showAllText;
			}
			button.onclick = function() {
				if ( toggleGroup.classList.contains( 'toggle-state-hide' ) ) {
					toggleGroup.classList.remove( 'toggle-state-hide' );
					toggleGroup.classList.add( 'toggle-state-show' );
					this.innerHTML = showAllText;
					toggleGroup.querySelectorAll( '.collapsible, .general-collapsible' ).forEach( function( collapsible ) {
						collapsible.classList.add( 'collapsed' );
					} );
					toggleGroup.querySelectorAll( '.brkts-matchlist-collapsible' ).forEach( function( collapsible ) {
						collapsible.classList.add( 'brkts-matchlist-collapsed' );
					} );
				} else {
					toggleGroup.classList.remove( 'toggle-state-show' );
					toggleGroup.classList.add( 'toggle-state-hide' );
					this.innerHTML = hideAllText;
					toggleGroup.querySelectorAll( '.collapsible, .general-collapsible' ).forEach( function( collapsible ) {
						collapsible.classList.remove( 'collapsed' );
					} );
					toggleGroup.querySelectorAll( '.brkts-matchlist-collapsible' ).forEach( function( collapsible ) {
						collapsible.classList.remove( 'brkts-matchlist-collapsed' );
					} );
				}
			};
			toggleGroup.insertBefore( button, toggleGroup.firstChild );
		} );
	},
	setupDropdownBox: function() {
		let toggleActive = false;
		document.querySelector( 'html' ).addEventListener( 'click', function( ev ) {
			if ( ev.target.closest( '.dropdown-box' ) === null ) {
				if ( toggleActive ) {
					document.querySelectorAll( '.dropdown-box-visible' ).forEach( function( box ) {
						box.classList.remove( 'dropdown-box-visible' );
					} );
					toggleActive = false;
				}
			}
		} );
		document.querySelectorAll( '#mw-content-text .dropdown-box-wrapper' ).forEach( function( dropdownBox ) {
			const dropdownButton = dropdownBox.querySelector( '.dropdown-box-button' );
			dropdownButton.onclick = function( ev ) {
				ev.stopPropagation();
				dropdownBox.querySelectorAll( '.dropdown-box' ).forEach( function ( box ) {
					if ( box.classList.contains( 'dropdown-box-visible' ) ) {
						box.classList.remove( 'dropdown-box-visible' );
						toggleActive = false;
					} else {
						box.classList.add( 'dropdown-box-visible' );
						toggleActive = true;
						box.querySelectorAll( '.btn' ).forEach( function( btn ) {
							btn.addEventListener( 'click', function() {
								dropdownButton.innerHTML = btn.textContent + ' <span class="caret"></span>';
								box.classList.remove( 'dropdown-box-visible' );
								toggleActive = false;
							} );
						} );
					}
				} );
			};
		} );
	}
};
liquipedia.core.modules.push( 'collapse' );
