/*******************************************************************************
 * Template(s): Toggles for templates
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.collapse = {
	init: function() {
		document.querySelectorAll( '#mw-content-text .collapsible' ).forEach( ( table, index ) => {
			if ( table.classList.contains( 'autocollapse' ) && index >= 1 ) {
				table.classList.add( 'collapsed' );
			}
		} );
		liquipedia.collapse.setupCollapsibleButtons();
		liquipedia.collapse.setupGeneralCollapsibleButtons();
		liquipedia.collapse.setupToggleGroups();
		liquipedia.collapse.setupDropdownBox();
		liquipedia.collapse.setupCollapsibleNavFrameButtons();
	},
	makeIcon: function( isShow ) {
		return isShow ? '<span class="far fa-eye"></span>' : '<span class="far fa-eye-slash"></span>';
	},
	makeDesignButton: function( collapsible, isShow ) {
		const title = ( isShow ? 'Show' : 'Hide' );
		const button = document.createElement( 'button' );
		button.classList.add( 'collapseButton', 'btn', 'btn-secondary', 'btn-extrasmall' );
		button.classList.add( isShow ? 'collapseButtonShow' : 'collapseButtonHide' );
		button.setAttribute( 'role', 'button' );
		button.setAttribute( 'aria-label', title );
		button.setAttribute( 'title', title );
		button.setAttribute( 'tabindex', '0' );
		button.innerHTML = this.makeIcon( isShow ) + ' ' + title;
		button.onclick = function( ev ) {
			ev.preventDefault();
			if ( isShow ) {
				collapsible.classList.remove( 'collapsed' );
			} else {
				collapsible.classList.add( 'collapsed' );
			}
		};
		return button;
	},
	setupCollapsibleButtons: function() {
		document.querySelectorAll( '#mw-content-text .collapsible' ).forEach( ( collapsible ) => {
			const row = collapsible.querySelector( 'tr' );
			if ( row !== null ) {
				row.lastElementChild.insertBefore(
					this.makeDesignButton( collapsible, true ),
					row.lastElementChild.firstChild
				);
				row.lastElementChild.insertBefore(
					this.makeDesignButton( collapsible, false ),
					row.lastElementChild.firstChild
				);
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
			button.childNodes.forEach( ( node ) => {
				anchor.append( node );
			} );
			anchor.className = button.className;
			anchor.href = '#';
			button.parentNode.replaceChild( anchor, button );
			return anchor;
		}

		document.querySelectorAll( '#mw-content-text .general-collapsible' ).forEach( ( collapsible ) => {
			const collapseButton = collapsible.querySelector( '.general-collapsible-collapse-button' );
			const expandButton = collapsible.querySelector( '.general-collapsible-expand-button' );

			if ( expandButton ) {
				const anchor = replaceWithAnchor( expandButton );
				anchor.addEventListener( 'click', ( event ) => {
					collapsible.classList.remove( 'collapsed' );
					event.preventDefault();
				} );
			}

			if ( collapseButton ) {
				const anchor = replaceWithAnchor( collapseButton );
				anchor.addEventListener( 'click', ( event ) => {
					collapsible.classList.add( 'collapsed' );
					event.preventDefault();
				} );
			}
		} );
	},
	setupCollapsibleNavFrameButtons: function() {
		document.querySelectorAll( '#mw-content-text .NavFrame' ).forEach( ( navFrame ) => {
			const head = navFrame.querySelector( '.NavHead' );
			if ( head !== null ) {
				head.insertBefore( this.makeDesignButton( navFrame, true ), head.firstChild );
				head.insertBefore( this.makeDesignButton( navFrame, false ), head.firstChild );
			}
		} );
	},
	setupToggleGroups: function() {
		document.querySelectorAll( '#mw-content-text .toggle-group' ).forEach( ( toggleGroup ) => {
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
			button.classList.add( 'btn', 'btn-secondary' );
			if ( toggleGroup.classList.contains( 'toggle-state-hide' ) ) {
				button.innerHTML = this.makeIcon( false ) + ' ' + hideAllText;
			} else {
				button.innerHTML = this.makeIcon( true ) + ' ' + showAllText;
			}
			button.onclick = () => {
				if ( toggleGroup.classList.contains( 'toggle-state-hide' ) ) {
					toggleGroup.classList.remove( 'toggle-state-hide' );
					toggleGroup.classList.add( 'toggle-state-show' );
					button.innerHTML = this.makeIcon( true ) + ' ' + showAllText;
					toggleGroup.querySelectorAll( '.collapsible, .general-collapsible' ).forEach( ( collapsible ) => {
						collapsible.classList.add( 'collapsed' );
					} );
					toggleGroup.querySelectorAll( '.brkts-matchlist-collapsible' ).forEach( ( collapsible ) => {
						collapsible.classList.add( 'brkts-matchlist-collapsed' );
					} );
				} else {
					toggleGroup.classList.remove( 'toggle-state-show' );
					toggleGroup.classList.add( 'toggle-state-hide' );
					button.innerHTML = this.makeIcon( false ) + ' ' + hideAllText;
					toggleGroup.querySelectorAll( '.collapsible, .general-collapsible' ).forEach( ( collapsible ) => {
						collapsible.classList.remove( 'collapsed' );
					} );
					toggleGroup.querySelectorAll( '.brkts-matchlist-collapsible' ).forEach( ( collapsible ) => {
						collapsible.classList.remove( 'brkts-matchlist-collapsed' );
					} );
				}
			};
			toggleGroup.insertBefore( button, toggleGroup.firstChild );
		} );
	},
	setupDropdownBox: function() {
		let toggleActive = false;
		document.querySelector( 'html' ).addEventListener( 'click', ( ev ) => {
			if ( ev.target.closest( '.dropdown-box' ) === null ) {
				if ( toggleActive ) {
					document.querySelectorAll( '.dropdown-box-visible' ).forEach( ( box ) => {
						box.classList.remove( 'dropdown-box-visible' );
					} );
					toggleActive = false;
				}
			}
		} );
		document.querySelectorAll( '#mw-content-text .dropdown-box-wrapper' ).forEach( ( dropdownBox ) => {
			const dropdownButton = dropdownBox.querySelector( '.dropdown-box-button' );
			dropdownButton.onclick = function( ev ) {
				ev.stopPropagation();
				dropdownBox.querySelectorAll( '.dropdown-box' ).forEach( ( box ) => {
					if ( box.classList.contains( 'dropdown-box-visible' ) ) {
						box.classList.remove( 'dropdown-box-visible' );
						toggleActive = false;
					} else {
						box.classList.add( 'dropdown-box-visible' );
						toggleActive = true;
						box.querySelectorAll( '.btn' ).forEach( ( btn ) => {
							btn.addEventListener( 'click', () => {
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
