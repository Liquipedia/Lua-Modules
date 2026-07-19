/**
 * @file This module provides functionality for collapsible panel boxes.
 * @author Elysienna (Laura van Helvoort)
 *
 * To query all panel boxes, a data-component attribute with the value "panel-box" is set in the HTML.
 * It is done by data attribute to ensure that the script is not dependent on the class name.
 * To further specify the panel box, a unique data attribute ID (data-panel-box-id) is set on the HTML of the panel
 * box to help track if the panel is collapsed. If the panel is collapsed, the data-panel-box-id is added to the
 * array of the local storage key.
 * On init, it will check if the local storage contains panel box ids and applies the collapsed class to the element.
 * It will then add a click event to the button to toggle the collapsed class and add or remove the panel box id in
 * local storage.
 */

/**
 * @namespace liquipedia.panelBoxCollapsible
 */
liquipedia.panelBoxCollapsible = {

	/**
	 * LOCAL_STORAGE_KEY {string} - This key used to store the array of collapsed panel box IDs in local storage.
	 * CLASS_COLLAPSED {string} - The class added to a panel box when it is collapsed.
	 * DATA_ATTR_PANEL_BOX_ID {string} - Data attribute used to store the ID of a panel box.
	 */
	LOCAL_STORAGE_KEY: 'panelBoxCollapsed',
	CLASS_COLLAPSED: 'is--collapsed',
	DATA_ATTR_PANEL_BOX_ID: 'data-panel-box-id',

	init: function() {
		const panelBoxes = document.querySelectorAll( '[data-component="panel-box"]' );
		panelBoxes.forEach( ( panelBox ) => this.handlePanelBox( panelBox ) );
	},

	/**
	 * @param {Element} panelBox - Panel box element to handle.
	 */
	handlePanelBox: function( panelBox ) {
		const closedPanelIDsArray = this.getFromLocalStorage();
		const id = panelBox.getAttribute( this.DATA_ATTR_PANEL_BOX_ID );

		/* If the panel box ID is in the array of collapsed panel box IDs, add the collapsed class. */
		if ( closedPanelIDsArray.includes( id ) ) {
			this.toggleCollapsedClass( panelBox );
		}

		const button = panelBox.querySelector( '[data-component="panel-box-collapsible-button"]' );
		if ( button ) {
			button.addEventListener( 'click', () => {
				this.handleClick( panelBox, id );
			} );
		}
	},

	/**
	 * @return {Array} Array of collapsed panel box IDs.
	 */
	getFromLocalStorage: function() {
		const items = window.localStorage.getItem( this.LOCAL_STORAGE_KEY );
		try {
			return items ? JSON.parse( items ) : [];
		} catch {
			return [ ];
		}
	},

	/**
	 * @param {string} id - Panel box ID.
	 */
	setToLocalStorage: function( id ) {
		const items = this.getFromLocalStorage();
		if ( !items.includes( id ) ) {
			items.push( id );
			localStorage.setItem( this.LOCAL_STORAGE_KEY, JSON.stringify( items ) );
		}
	},

	/**
	 * @param {string} id - Panel box ID.
	 */
	removeFromLocalStorage: function( id ) {
		const items = this.getFromLocalStorage();
		const index = items.indexOf( id );
		if ( index > -1 ) {
			items.splice( index, 1 );
			localStorage.setItem( this.LOCAL_STORAGE_KEY, JSON.stringify( items ) );
		}
	},

	/**
	 * @param {string} id - Panel box ID.
	 * @return {boolean} True if the ID is in the array, false otherwise.
	 */
	isInLocalStorage: function( id ) {
		const items = this.getFromLocalStorage();
		return items.includes( id );
	},

	/**
	 * @param {Element} element - Panel box element.
	 */
	toggleCollapsedClass: function( element ) {
		if ( !element.classList.contains( this.CLASS_COLLAPSED ) ) {
			element.classList.add( this.CLASS_COLLAPSED );
		} else {
			element.classList.remove( this.CLASS_COLLAPSED );
		}
	},

	/**
	 * @param {Element} element - Panel box element.
	 * @param {string} id - ID of the panel box that was clicked.
	 */
	handleClick: function( element, id ) {
		this.toggleCollapsedClass( element );
		if ( this.isInLocalStorage( id ) ) {
			this.removeFromLocalStorage( id );
		} else {
			this.setToLocalStorage( id );
		}
	}
};
liquipedia.core.modules.push( 'panelBoxCollapsible' );
