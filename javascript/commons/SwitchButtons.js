/*******************************************************************************
 Template(s): Switch button
 Author(s): Nadox (original)
 *******************************************************************************/

liquipedia.switchButtons = {
	isInitialized: false,
	isBeingInitialized: false,
	baseLocalStorageKey: null,
	triggerEventName: 'switchButtonChanged',
	switchGroups: {},

	init: function () {
		if ( this.isBeingInitialized || this.isInitialized ) {
			return;
		}
		this.isBeingInitialized = true;

		this.baseLocalStorageKey = this.buildLocalStorageKey();
		this.initSwitchElements( 'toggle', '.switch-toggle', 'switch-toggle-active' );
		this.initSwitchElements( 'pill', '.switch-pill', 'switch-pill-active' );

		this.isBeingInitialized = false;
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
			switchGroup.nodes.forEach( ( node ) => node.classList.toggle(
				switchGroup.activeClassName,
				targetValue === node.dataset.switchValue
			) );
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
			node.addEventListener( 'click', () => {
				const newValue = this.getNewValue( node, switchGroup.type, activeClassName );

				if ( switchGroup.value !== newValue ) {
					switchGroup.value = newValue;

					if ( switchGroup.isStoredInLocalStorage ) {
						this.setLocalStorageValue( switchGroup.name, newValue );
					}
					this.updateDOM( switchGroup, newValue );
					this.triggerCustomEvent( node, switchGroup );
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

	// Accessed by other components, thus triggering init if necessary
	getSwitchGroup: function ( groupName ) {
		this.init();
		return this.switchGroups[ groupName ];
	}
};

liquipedia.core.modules.push( 'switchButtons' );
