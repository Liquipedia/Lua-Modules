/*******************************************************************************
 * Template(s): Dropdown
 ******************************************************************************/
liquipedia.dropdown = {
	isInitialized: false,

	getDropdownWidget( target ) {
		return target.closest( '.dropdown-widget' );
	},

	getToggle( dropdownWidget ) {
		return dropdownWidget?.querySelector( '.dropdown-widget__toggle' ) ?? null;
	},

	getMenu( dropdownWidget ) {
		return dropdownWidget?.querySelector( '.dropdown-widget__menu' ) ?? null;
	},

	setOpenState( dropdownWidget, isOpen, options = {} ) {
		const menu = this.getMenu( dropdownWidget );
		const toggle = this.getToggle( dropdownWidget );
		if ( !menu || !toggle ) {
			return;
		}

		const wasOpen = menu.classList.contains( 'show' );
		if ( wasOpen === isOpen ) {
			return;
		}

		const eventPrefix = isOpen ? 'dropdown:beforeopen' : 'dropdown:beforeclose';
		dropdownWidget.dispatchEvent( new CustomEvent( eventPrefix, { bubbles: true } ) );

		menu.classList.toggle( 'show', isOpen );
		toggle.setAttribute( 'aria-expanded', String( isOpen ) );
		menu.setAttribute( 'aria-hidden', String( !isOpen ) );

		dropdownWidget.dispatchEvent( new CustomEvent( isOpen ? 'dropdown:open' : 'dropdown:close', { bubbles: true } ) );

		if ( !isOpen && options.focusToggle ) {
			toggle.focus();
		}
	},

	closeOtherDropdowns( currentDropdownWidget ) {
		document.querySelectorAll( '.dropdown-widget__menu.show' ).forEach( ( menu ) => {
			const dropdownWidget = this.getDropdownWidget( menu );
			if ( !dropdownWidget || dropdownWidget === currentDropdownWidget ) {
				return;
			}

			this.setOpenState( dropdownWidget, false );
		} );
	},

	toggleDropdown( dropdownWidget ) {
		const menu = this.getMenu( dropdownWidget );
		if ( !menu ) {
			return;
		}

		const isOpen = menu.classList.contains( 'show' );
		if ( !isOpen ) {
			this.closeOtherDropdowns( dropdownWidget );
		}

		this.setOpenState( dropdownWidget, !isOpen );
	},

	closeAllDropdowns( options = {} ) {
		document.querySelectorAll( '.dropdown-widget__menu.show' ).forEach( ( menu ) => {
			const dropdownWidget = this.getDropdownWidget( menu );
			if ( dropdownWidget ) {
				this.setOpenState( dropdownWidget, false, options );
			}
		} );
	},

	init: function() {
		if ( this.isInitialized ) {
			return;
		}

		this.isInitialized = true;

		document.addEventListener( 'click', ( e ) => {
			const toggle = e.target.closest( '[data-dropdown-toggle]' );
			if ( toggle ) {
				e.stopPropagation();
				this.toggleDropdown( this.getDropdownWidget( toggle ) );
				return;
			}

			this.closeAllDropdowns();
		} );

		document.addEventListener( 'keydown', ( event ) => {
			const toggle = event.target.closest?.( '[data-dropdown-toggle]' ) ?? null;

			if ( toggle && ( event.key === 'Enter' || event.key === ' ' ) ) {
				event.preventDefault();
				this.toggleDropdown( this.getDropdownWidget( toggle ) );
				return;
			}

			if ( event.key === 'Escape' ) {
				const openMenu = document.querySelector( '.dropdown-widget__menu.show' );
				if ( openMenu ) {
					const dropdownWidget = this.getDropdownWidget( openMenu );
					if ( dropdownWidget ) {
						this.setOpenState( dropdownWidget, false, { focusToggle: true } );
					}
				}
			}
		} );
	}
};

liquipedia.core.modules.push( 'dropdown' );
