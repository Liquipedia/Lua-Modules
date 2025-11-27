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
		liquipedia.collapse.setupHeaderToggleCollapsibles();
		liquipedia.collapse.setupToggleGroups();
		liquipedia.collapse.setupDropdownBox();
		liquipedia.collapse.setupCollapsibleNavFrameButtons();
		liquipedia.collapse.setupSwitchToggleCollapsibles();
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
			if ( row === null ) {
				return;
			}

			if ( row.lastElementChild.querySelector( '.collapseButton' ) ) {
				// Buttons are already set up, nothing to do
				return;
			}

			row.lastElementChild.insertBefore(
				this.makeDesignButton( collapsible, true ),
				row.lastElementChild.firstChild
			);
			row.lastElementChild.insertBefore(
				this.makeDesignButton( collapsible, false ),
				row.lastElementChild.firstChild
			);
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
	setupHeaderToggleCollapsibles: function() {
		const headers = document.querySelectorAll( '[data-header-click-toggles="true"]' );

		headers.forEach( ( header ) => {
			header.addEventListener( 'click', ( event ) => {
				const clickedLink = event.target.closest( 'a' );

				if ( clickedLink ) {
					return;
				}

				const collapsible = header.closest( '.general-collapsible' );
				if ( collapsible ) {
					event.preventDefault();
					collapsible.classList.toggle( 'collapsed' );
				}
			} );
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
			button.classList.add( 'btn', 'btn-secondary', 'btn-small' );
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
					this.updateCollapsibleElements( '.collapsible, .general-collapsible', false, toggleGroup );
				} else {
					toggleGroup.classList.remove( 'toggle-state-show' );
					toggleGroup.classList.add( 'toggle-state-hide' );
					button.innerHTML = this.makeIcon( false ) + ' ' + hideAllText;
					this.updateCollapsibleElements( '.collapsible, .general-collapsible', true, toggleGroup );
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
	},

	setupSwitchToggleCollapsibles: function() {
		const switchToggleElements = document.querySelectorAll( '[data-switch-group]' );
		if ( switchToggleElements.length === 0 ) {
			return;
		}

		const groupToSelectorMap = new Map();

		switchToggleElements.forEach( ( element ) => {
			const switchGroupName = element.getAttribute( 'data-switch-group' );
			const collapsibleSelector = element.getAttribute( 'data-collapsible-selector' );

			if ( collapsibleSelector === undefined ) {
				return;
			}

			groupToSelectorMap.set( switchGroupName, collapsibleSelector );

			liquipedia.switchButtons.getSwitchGroup( switchGroupName ).then( ( switchGroup ) => {
				if ( switchGroup ) {
					this.updateCollapsibleElements( collapsibleSelector, switchGroup.value, document );
				}
			} );
		} );

		document.addEventListener( 'switchButtonChanged', ( event ) => {
			const { name, value } = event.detail.data;

			const selector = groupToSelectorMap.get( name );

			if ( selector ) {
				this.updateCollapsibleElements( selector, value, document );
			}
		} );
	},

	updateCollapsibleElements: function( selector, show, scope ) {
		const root = ( scope instanceof Element ) ? scope : document;
		const elements = root.querySelectorAll( selector );

		elements.forEach( ( element ) => {
			element.classList.toggle( 'collapsed', !show );
		} );
	}
};

liquipedia.core.modules.push( 'collapse' );
