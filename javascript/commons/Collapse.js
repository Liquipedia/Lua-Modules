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
	textShow: '<i class="fas fa-eye"></i> Show',
	textHide: '<i class="fas fa-eye-slash"></i> Hide',
	makeShowButton: function( collapsible ) {
		return liquipedia.collapse.makeButton(
			liquipedia.collapse.textShow,
			'collapseButtonShow',
			collapsible
		);
	},
	makeHideButton: function( collapsible ) {
		return liquipedia.collapse.makeButton(
			liquipedia.collapse.textHide,
			'collapseButtonHide',
			collapsible
		);
	},
	makeButton: function( text, wrapperClass, collapsible ) {
		const buttonWrapper = document.createElement( 'span' );
		buttonWrapper.classList.add( 'collapseButton' );
		buttonWrapper.classList.add( wrapperClass );
		const button = document.createElement( 'button' );
		button.classList.add( 'btn' );
		button.classList.add( 'btn-secondary' );
		button.classList.add( 'btn-xsmall' );
		button.type = 'button';
		button.innerHTML = text;
		button.onclick = function( ev ) {
			ev.preventDefault();
			if ( wrapperClass === 'collapseButtonShow' ) {
				collapsible.classList.remove( 'collapsed' );
			} else {
				collapsible.classList.add( 'collapsed' );
			}
		};
		buttonWrapper.appendChild( button );
		return buttonWrapper;
	},
	setupCollapsibleButtons: function() {
		document.querySelectorAll( '#mw-content-text .collapsible' ).forEach( ( collapsible ) => {
			const row = collapsible.querySelector( 'tr' );
			if ( row !== null ) {
				row.lastElementChild.insertBefore(
					liquipedia.collapse.makeShowButton( collapsible ),
					row.lastElementChild.firstChild
				);
				row.lastElementChild.insertBefore(
					liquipedia.collapse.makeHideButton( collapsible ),
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
				head.insertBefore(
					liquipedia.collapse.makeShowButton( navFrame ),
					head.firstChild
				);
				head.insertBefore(
					liquipedia.collapse.makeHideButton( navFrame ),
					head.firstChild
				);
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
					toggleGroup.querySelectorAll( '.collapsible, .general-collapsible' ).forEach( ( collapsible ) => {
						collapsible.classList.add( 'collapsed' );
					} );
					toggleGroup.querySelectorAll( '.brkts-matchlist-collapsible' ).forEach( ( collapsible ) => {
						collapsible.classList.add( 'brkts-matchlist-collapsed' );
					} );
				} else {
					toggleGroup.classList.remove( 'toggle-state-show' );
					toggleGroup.classList.add( 'toggle-state-hide' );
					this.innerHTML = hideAllText;
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
