/**
 * @file This module provides functionality for collapsible panel boxes.
 * @author Elysienna (Laura van Helvoort)
 */

/**
 * @namespace liquipedia.panelBoxCollapsible
 */
liquipedia.panelBoxCollapsible = {

	/**
	 * LOCAL_STORAGE_KEY {string} - The key used to store the array of collapsed panel box IDs in local storage.
	 * CLASS_COLLAPSED {string} - The class added to a panel box when it is collapsed.
	 * DATA_ATTR_PANEL_BOX_ID {string} - The data attribute used to store the ID of a panel box.
	 */
	LOCAL_STORAGE_KEY: 'panelBoxCollapsed',
	CLASS_COLLAPSED: 'is--collapsed',
	DATA_ATTR_PANEL_BOX_ID: 'data-panel-box-id',

	init: function() {
		const panelBoxes = document.querySelectorAll( '[data-component="panel-box"]' );
		panelBoxes.forEach( ( panelBox ) => this.handlePanelBox( panelBox ) );
	},

	/**
	 * Handles a panel box element by adding an event listener to its collapsible button and checking if
	 * it should be collapsed.
	 * @param {Element} panelBox - The panel box element to handle.
	 */
	handlePanelBox: function( panelBox ) {
		const closedPanelIDsArray = this.getFromLocalStorage();
		const id = panelBox.getAttribute( this.DATA_ATTR_PANEL_BOX_ID );

		/* If the panel box ID is in the array of collapsed panel box IDs, add the collapsed class. */
		if ( closedPanelIDsArray.includes( id ) ) {
			this.toggleCollapsedClass( panelBox );
		}

		const button = panelBox.querySelector( '[data-component="panel-box-collapsible-button"]' );
		button.addEventListener( 'click', () => {
			this.handleClick( panelBox, id );
		} );
	},

	/**
	 * Retrieves the array of collapsed panel box IDs from local storage.
	 * @return {Array} The array of collapsed panel box IDs.
	 */
	getFromLocalStorage: function() {
		const items = window.localStorage.getItem( this.LOCAL_STORAGE_KEY );
		return items ? JSON.parse( items ) : [ ];
	},

	/**
	 * Adds a panel box ID to the array of collapsed panel box IDs in local storage.
	 * @param {string} id - The ID of the panel box to add.
	 */
	setToLocalStorage: function( id ) {
		const items = this.getFromLocalStorage();
		if ( !items.includes( id ) ) {
			items.push( id );
			localStorage.setItem( this.LOCAL_STORAGE_KEY, JSON.stringify( items ) );
		}
	},

	/**
	 * Removes a panel box ID from the array of collapsed panel box IDs in local storage.
	 * @param {string} id - The ID of the panel box to remove.
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
	 * Checks if a panel box ID is in the array of collapsed panel box IDs in local storage.
	 * @param {string} id - The ID of the panel box to check.
	 * @return {boolean} True if the ID is in the array, false otherwise.
	 */
	isInLocalStorage: function( id ) {
		const items = this.getFromLocalStorage();
		return items.includes( id );
	},

	/**
	 * Adds or removes the collapsed class to a panel box element.
	 * @param {Element} element - The panel box element to add or remove the class to.
	 */
	toggleCollapsedClass: function( element ) {
		if ( !element.classList.contains( this.CLASS_COLLAPSED ) ) {
			element.classList.add( this.CLASS_COLLAPSED );
		} else {
			element.classList.remove( this.CLASS_COLLAPSED );
		}
	},

	/**
	 * Handles a click event on a panel box, collapsing the panel box and adding its ID to local storage if necessary.
	 * @param {Element} element - The panel box element that was clicked.
	 * @param {string} id - The ID of the panel box that was clicked.
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
