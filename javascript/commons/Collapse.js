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
		liquipedia.collapse.setupClickableRegionCollapsibles();
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
		button.classList.add( 'collapseButton', 'button', 'button--secondary', 'button--extrasmall' );
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
	setupGeneralCollapsibleButtons: function() {
		// Replaces the element (a <div>, as the MW parser does not allow <button>)
		// with a real <button>.
		// For xss safety, only the child nodes and class name are copied over.
		function replaceWithButton( element ) {
			const button = document.createElement( 'button' );
			button.append( ...element.childNodes );
			button.className = element.className;
			button.type = 'button';
			element.parentNode.replaceChild( button, element );
			return button;
		}

		const supportsAnchoredPopover = this.supportsAnchoredPopover();

		document.querySelectorAll( '#mw-content-text .general-collapsible' ).forEach( ( collapsible ) => {
			const collapseButton = collapsible.querySelector( '.general-collapsible-collapse-button' );
			const expandButton = collapsible.querySelector( '.general-collapsible-expand-button' );

			const newExpandButton = expandButton ? replaceWithButton( expandButton ) : null;
			const newCollapseButton = collapseButton ? replaceWithButton( collapseButton ) : null;

			if ( supportsAnchoredPopover && collapsible.hasAttribute( 'data-collapsible-popover' ) ) {
				this.setupPopoverCollapsible( collapsible, [ newExpandButton, newCollapseButton ] );
				return;
			}

			newExpandButton?.addEventListener( 'click', () => {
				collapsible.classList.remove( 'collapsed' );
			} );

			newCollapseButton?.addEventListener( 'click', () => {
				collapsible.classList.add( 'collapsed' );
			} );
		} );
	},

	popoverCount: 0,

	// Tracks element instances rather than using a DOM attribute as marker, as attributes survive
	// when the HTML is serialized and restored (e.g. FilterButtons' cache) while listeners do not.
	initializedPopovers: new WeakSet(),

	supportsAnchoredPopover: function() {
		return Object.prototype.hasOwnProperty.call( HTMLElement.prototype, 'popover' ) &&
			CSS.supports( 'position-area: block-end' ) &&
			CSS.supports( 'width: anchor-size(width)' );
	},

	/**
	 * Turns the collapse area of a general-collapsible into a popover that is anchored below
	 * the collapsible's header. Only used when the browser natively supports both popovers and
	 * anchor positioning; otherwise the collapsible keeps expanding inline.
	 *
	 * @param {HTMLElement} collapsible
	 * @param {(HTMLButtonElement|null)[]} toggleButtons
	 * @return {void}
	 */
	setupPopoverCollapsible: function( collapsible, toggleButtons ) {
		const area = collapsible.querySelector( ':scope > .should-collapse' );
		const anchor = area?.previousElementSibling;
		if ( !area || !anchor ) {
			return;
		}

		// init() may run more than once (e.g. after FilterButtons reloads content),
		// so the popover itself is only set up once per element.
		if ( !this.initializedPopovers.has( area ) ) {
			this.initializedPopovers.add( area );
			const name = `general-collapsible-popover-${ ++this.popoverCount }`;
			if ( !area.id ) {
				area.id = name;
			}
			area.setAttribute( 'popover', 'auto' );
			anchor.style.setProperty( 'anchor-name', `--${ name }` );
			area.style.setProperty( 'position-anchor', `--${ name }` );

			// Keep the toggle buttons in sync, including when the popover is light dismissed.
			// beforetoggle fires synchronously, so `.collapsed` never hides an open popover.
			area.addEventListener( 'beforetoggle', ( event ) => {
				collapsible.classList.toggle( 'collapsed', event.newState !== 'open' );
			} );
			collapsible.classList.add( 'collapsed' );
		}

		// Button replacement drops all attributes, so this has to be reapplied every time.
		// Making the buttons invokers also exempts them from light dismiss.
		toggleButtons.forEach( ( button ) => {
			button?.setAttribute( 'popovertarget', area.id );
		} );
	},
	setupClickableRegionCollapsibles: function() {
		const regions = document.querySelectorAll( '[data-collapsible-click-region]' );

		regions.forEach( ( region ) => {
			// Get exclusion selector from attribute, default to interactive elements
			// (links and buttons, which includes the general-collapsible toggles).
			// Can pass empty string for "no exclusions" (everything toggles collapse)
			const exclusionSelector = region.getAttribute( 'data-collapsible-exclude' ) || 'a, button';

			const toggleCollapsible = ( event ) => {
				if ( exclusionSelector ) {
					const clickedExcluded = event.target.closest( exclusionSelector );

					if ( clickedExcluded ) {
						return;
					}
				}

				const collapsible = region.closest( '.general-collapsible' );
				if ( collapsible ) {
					event.preventDefault();
					collapsible.classList.toggle( 'collapsed' );
					if ( region.hasAttribute( 'aria-expanded' ) ) {
						const isExpanded = !collapsible.classList.contains( 'collapsed' );
						region.setAttribute( 'aria-expanded', String( isExpanded ) );
					}
				}
			};

			region.setAttribute( 'tabindex', '0' );
			// role="button" makes child elements presentational, so only set it
			// on regions without interactive children (e.g. links)
			if ( !exclusionSelector || region.querySelector( exclusionSelector ) === null ) {
				const collapsible = region.closest( '.general-collapsible' );
				const isExpanded = collapsible !== null && !collapsible.classList.contains( 'collapsed' );
				region.setAttribute( 'role', 'button' );
				region.setAttribute( 'aria-expanded', String( isExpanded ) );
			}

			region.addEventListener( 'click', toggleCollapsible );
			region.addEventListener( 'keydown', ( event ) => {
				if ( event.key === 'Enter' || event.key === ' ' ) {
					toggleCollapsible( event );
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
			button.classList.add( 'button', 'button--secondary', 'button--small' );
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
						box.querySelectorAll( '.button' ).forEach( ( btn ) => {
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
