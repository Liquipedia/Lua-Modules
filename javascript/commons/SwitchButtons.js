/*******************************************************************************
 Template(s): Switch button
 Author(s): Nadox (original)
 *******************************************************************************/
/**
 * Description:
 * This module provides different types of switch buttons, which can be used to toggle between different states.
 * As of right now, two types of switch buttons are supported:
 * - Toggle: A single button that can be toggled on and off.
 * - Pill: A set of buttons where only one can be active at a time.
 *
 * Both types of switch buttons can be stored in the local storage, so that the state is remembered between page loads.
 *
 * Example usage (toggle):
 * <div class="switch-toggle-container">
 *   <div class="switch-toggle" data-switch-group="countdown" data-store-value="true">
 *      <div class="switch-toggle-slider"></div>
 *   </div>
 *   <div>Show Countdown</div>
 * </div>
 *
 * Example usage (pill):
 * <div class="switch-pill-container">
 *   <div class="switch-pill" data-switch-group="matchType" data-store-value="true">
 *       <div class="switch-pill-option switch-pill-active toggle-area-button" data-switch-value="upcoming">
 *          Upcoming
 *       </div>
 *       <div class="switch-pill-option toggle-area-button" data-switch-value="completed">
 *          Completed
 *       </div>
 *   </div>
 * </div>
 *
 * HTML Attributes:
 * - data-switch-group (required): The name of the switch group. Elements with the same switch group name are connected.
 * - data-store-value (optional): If set to true, the state of the switch button will be stored in the local storage.
 * - data-switch-value (only for pill): The value that the switch button will have when it is active.
 *
 * Events:
 * The switch button will trigger a custom event 'switchButtonChanged' when the state is changed.
 *
 * Properties:
 * The switch button can be easily accessed and manipulated by other components using the getSwitchGroup method.
 *
 * Usage Methods:
 * setCountdownVisibility(isVisible): Controls the visibility of the countdown toggle (true to show, false to hide).
 *
 * SwitchGroup object contains the following properties:
 * - type: The type of the switch group (toggle or pill).
 * - name: The name of the switch group.
 * - activeClassName: The class name that is added to the active switch button.
 * - nodes: An array of the switch button nodes.
 * - isStoredInLocalStorage: Whether the state of the switch button is stored in the local storage.
 * - value: The current value of the switch button (null if not set).
 */

liquipedia.switchButtons = {
	baseLocalStorageKey: null,
	triggerEventName: 'switchButtonChanged',
	switchGroups: {},
	isInitialized: false,

	init: function () {
		this.baseLocalStorageKey = this.buildLocalStorageKey();
		this.initSwitchElements( 'toggle', '.switch-toggle', 'switch-toggle-active' );
		this.initSwitchElements( 'pill', '.switch-pill', 'switch-pill-active' );
		this.isInitialized = true;
	},

	initSwitchElements: function ( type, selector, activeClassName ) {
		const elements = document.querySelectorAll( selector );

		elements.forEach( ( element ) => {
			const groupName = element.dataset.switchGroup;
			if ( groupName ) {
				const switchGroup = this.getOrCreateSwitchGroup( type, groupName, element, activeClassName );
				this.setupSwitchGroupValueAndDOM( switchGroup );
				this.attachEventListener( switchGroup, activeClassName );
			}
		} );
	},

	setCountdownVisibility: function(isVisible) {
		const switchGroup = this.switchGroups['countdown'];

		if (switchGroup && switchGroup.nodes.length > 0) {
			const container = switchGroup.nodes[0].closest('[data-component="switch-toggle-container"]');
			if (container) {
				container.classList[isVisible ? 'remove' : 'add']('d-none');
			}
		}
	},

	getOrCreateSwitchGroup: function ( type, groupName, element, activeClassName ) {
		if ( !this.switchGroups[ groupName ] ) {
			const switchGroup = {
				type,
				name: groupName,
				activeClassName,
				nodes: [],
				isStoredInLocalStorage: element.dataset.storeValue === 'true',
				value: null // Default value
			};

			if ( type === 'toggle' ) {
				switchGroup.nodes.push( element );
			} else {
				element.querySelectorAll( '.switch-pill-option' ).forEach( ( optionNode ) => {
					switchGroup.nodes.push( optionNode );
				} );
			}

			this.switchGroups[ groupName ] = switchGroup;
		}

		return this.switchGroups[ groupName ];
	},

	setupSwitchGroupValueAndDOM: function ( switchGroup ) {
		const localStorageValue = this.getLocalStorageValue( switchGroup );

		if ( localStorageValue !== null ) {
			switchGroup.value = localStorageValue;
			this.updateDOM( switchGroup, localStorageValue );
		} else {
			switchGroup.value = this.getValueFromDOM( switchGroup );
		}
	},

	updateDOM: function ( switchGroup, targetValue ) {
		if ( switchGroup.type === 'toggle' ) {
			switchGroup.nodes.forEach( ( node ) => node.classList.toggle(
				switchGroup.activeClassName,
				targetValue
			) );
		} else {
			switchGroup.nodes.forEach( ( node ) => {
				const isActive = targetValue === node.dataset.switchValue;
				node.classList.toggle( switchGroup.activeClassName, isActive );
				if ( isActive ) {
					node.dispatchEvent( new Event( 'click' ) );
				}
			} );
		}
	},

	getValueFromDOM: function ( switchGroup, activeClassName ) {
		if ( switchGroup.type === 'toggle' ) {
			return switchGroup.nodes[ 0 ]?.classList.contains( activeClassName ) ?? false;
		} else {
			switchGroup.nodes.forEach( ( pillNode ) => {
				if ( pillNode.classList.contains( activeClassName ) ) {
					return pillNode.dataset.switchValue;
				}
			} );
		}
	},

	attachEventListener: function ( switchGroup, activeClassName ) {
		switchGroup.nodes.forEach( ( node ) => {
			if ( switchGroup.name === 'matchFiler' && switchGroup.value === 'completed' ) {
				this.setCountdownVisibility(false);
			}

			node.addEventListener( 'click', () => {
				const newValue = this.getNewValue( node, switchGroup.type, activeClassName );

				if ( switchGroup.value !== newValue ) {
					switchGroup.value = newValue;

					if ( switchGroup.isStoredInLocalStorage ) {
						this.setLocalStorageValue( switchGroup.name, newValue );
					}
					this.updateDOM( switchGroup, newValue );
					this.triggerCustomEvent( node, switchGroup );

					// Handle countdown toggle visibility when matchFiler group changes
					if (switchGroup.name === 'matchFiler') {
						this.setCountdownVisibility(newValue !== 'completed');
					}
				}
			} );
		} );
	},

	getNewValue: function ( element, type, activeClassName ) {
		if ( type === 'toggle' ) {
			return !element.classList.contains( activeClassName );
		} else {
			return element.dataset.switchValue;
		}
	},

	buildLocalStorageKey: function () {
		const base = 'LiquipediaSwitchButtons';
		const scriptPath = mw.config.get( 'wgScriptPath' ).replace( /[\W]/g, '' );
		const pageName = mw.config.get( 'wgPageName' );
		return `${ base }-${ scriptPath }-${ pageName }`;
	},

	getLocalStorageValue: function ( switchGroup ) {
		const groupName = switchGroup.name;
		const localStorageKey = `${ this.baseLocalStorageKey }_${ groupName }`;
		const storageValue = window.localStorage.getItem( localStorageKey );

		if ( switchGroup.type === 'toggle' ) {
			return storageValue === 'true';
		} else {
			return storageValue;
		}
	},

	setLocalStorageValue: function ( groupName, value ) {
		const localStorageKey = `${ this.baseLocalStorageKey }_${ groupName }`;
		window.localStorage.setItem( localStorageKey, value );
	},

	triggerCustomEvent: function ( node, data ) {
		const customEvent = new CustomEvent( this.triggerEventName, { detail: { data } } );
		node.dispatchEvent( customEvent );
	},

	/*
	 * Get the switch group object by name.
	 * This function is asynchronous, because the switch buttons are initialized asynchronously.
	 * Waits up to 1 second for the switch buttons to be initialized, otherwise returns null.
	 */
	getSwitchGroup: async function ( groupName ) {
		if ( this.isInitialized ) {
			return this.switchGroups[ groupName ];
		}

		return new Promise( ( resolve ) => {
			let interval = null;

			const timeout = setTimeout( () => {
				clearInterval( interval );
				resolve( null );
			}, 2000 );

			interval = setInterval( () => {
				if ( this.isInitialized ) {
					clearInterval( interval );
					clearTimeout( timeout );
					resolve( this.switchGroups[ groupName ] );
				}
			}, 100 );
		} );
	}
};

liquipedia.core.modules.push( 'switchButtons' );
