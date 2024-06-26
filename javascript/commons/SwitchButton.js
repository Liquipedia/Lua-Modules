/*******************************************************************************
 Template(s): Switch button
 Author(s): Nadox (original)
 *******************************************************************************/

liquipedia.switchButton = {
	init: function () {
		this.initSwitchToggles();
		this.initSwitchPills();
	},
	initSwitchToggles: function () {
		const switchActiveClassName = 'switch-toggle-active';
		const switchToggles = document.querySelectorAll( '.switch-toggle' );

		switchToggles.forEach( function ( toggle ) {
			toggle.addEventListener( 'click', function () {
				toggle.classList.toggle( switchActiveClassName );
				const isChecked = toggle.classList.contains( switchActiveClassName );
				const triggerEvent = toggle.dataset.triggerEvent;

				if ( triggerEvent ) {
					const customEvent = new CustomEvent( 'switchToggleTriggered', {
						detail: {
							event: triggerEvent,
							value: isChecked
						}
					} );
					document.dispatchEvent( customEvent );
				}
			} );
		} );
	},
	initSwitchPills: function () {
		const switchActiveClassName = 'swtich-pill-active';
		const switchPills = document.querySelectorAll( '.switch-pill-option' );

		switchPills.forEach( function ( pill ) {
			pill.addEventListener( 'click', function () {
				switchPills.forEach( ( element ) => element.classList.remove( switchActiveClassName ) );
				pill.classList.add( switchActiveClassName );
				const triggerEvent = pill.dataset.triggerEvent;
				const triggerValue = pill.dataset.triggerValue ?? null;

				if ( triggerEvent ) {
					const customEvent = new CustomEvent( 'switchPillTriggered', {
						detail: {
							event: triggerEvent,
							value: triggerValue
						}
					} );
					document.dispatchEvent( customEvent );
				}
			} );
		} );
	},
	triggerCustomEvent: function ( eventName, eventTarget, eventValue ) {
		const customEvent = new CustomEvent( eventName, {
			detail: {
				event: eventTarget,
				value: eventValue
			}
		} );
		document.dispatchEvent( customEvent );
	}
};

liquipedia.core.modules.push( 'switchButton' );
