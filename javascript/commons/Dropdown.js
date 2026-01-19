/*******************************************************************************
 * Template(s): Dropdown
 * Author(s): Liquipedia
 ******************************************************************************/
liquipedia.dropdown = {
	init: function() {
		document.addEventListener( 'click', ( e ) => {
			const isDropdownButton =
				e.target.matches( '[data-dropdown-toggle]' ) ||
				e.target.closest( '[data-dropdown-toggle]' );
			const dropdownWidget = isDropdownButton ? isDropdownButton.closest( '.dropdown-widget' ) : null;
			let currentMenu;

			if ( dropdownWidget ) {
				currentMenu = dropdownWidget.querySelector( '.dropdown-widget__menu' );
				currentMenu.classList.toggle( 'show' );
			}

			document.querySelectorAll( '.dropdown-widget__menu.show' ).forEach( ( menu ) => {
				if ( menu !== currentMenu ) {
					menu.classList.remove( 'show' );
				}
			} );
		} );
	}
};

liquipedia.core.modules.push( 'dropdown' );
