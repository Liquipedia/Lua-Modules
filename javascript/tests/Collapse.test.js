/**
 * @jest-environment jsdom
 */

const { test, expect, beforeAll, describe } = require( '@jest/globals' );

describe( 'Collapse module', () => {
	beforeAll( () => {
		globalThis.liquipedia = {
			core: {
				modules: []
			}
		};

		// Require the collapse module
		require( '../commons/Collapse.js' );
	} );

	test( 'should register itself as a module', () => {
		expect( globalThis.liquipedia.core.modules ).toContain( 'collapse' );
	} );

	test( 'makeIcon should return correct HTML for show/hide states', () => {
		const showIcon = globalThis.liquipedia.collapse.makeIcon( true );
		const hideIcon = globalThis.liquipedia.collapse.makeIcon( false );

		expect( showIcon ).toBe( '<span class="far fa-eye"></span>' );
		expect( hideIcon ).toBe( '<span class="far fa-eye-slash"></span>' );
	} );

	describe( 'popover collapsibles', () => {
		const render = () => {
			document.body.innerHTML = `
				<div id="mw-content-text">
					<div class="general-collapsible collapsed" data-collapsible-popover="true">
						<div class="header">
							<span class="general-collapsible-expand-button">Show</span>
							<span class="general-collapsible-collapse-button">Hide</span>
						</div>
						<div class="should-collapse">Content</div>
					</div>
				</div>
			`;
			return {
				collapsible: document.querySelector( '.general-collapsible' ),
				area: document.querySelector( '.should-collapse' )
			};
		};

		const dispatchToggle = ( element, newState ) => {
			const event = new Event( 'beforetoggle' );
			event.newState = newState;
			element.dispatchEvent( event );
		};

		const mockSupport = ( isSupported ) => {
			globalThis.liquipedia.collapse.supportsAnchoredPopover = () => isSupported;
		};

		test( 'falls back to inline collapsing without popover support', () => {
			mockSupport( false );
			const { collapsible, area } = render();
			globalThis.liquipedia.collapse.setupGeneralCollapsibleButtons();

			expect( area.hasAttribute( 'popover' ) ).toBe( false );
			document.querySelector( 'button.general-collapsible-expand-button' ).click();
			expect( collapsible.classList.contains( 'collapsed' ) ).toBe( false );
			document.querySelector( 'button.general-collapsible-collapse-button' ).click();
			expect( collapsible.classList.contains( 'collapsed' ) ).toBe( true );
		} );

		test( 'turns the collapse area into an anchored popover', () => {
			mockSupport( true );
			const { collapsible, area } = render();
			globalThis.liquipedia.collapse.setupGeneralCollapsibleButtons();

			expect( area.getAttribute( 'popover' ) ).toBe( 'auto' );
			expect( area.id ).not.toBe( '' );
			const anchorName = area.previousElementSibling.style.getPropertyValue( 'anchor-name' );
			expect( anchorName ).toBe( `--${ area.id }` );
			expect( area.style.getPropertyValue( 'position-anchor' ) ).toBe( anchorName );
			document.querySelectorAll( 'button' ).forEach( ( button ) => {
				expect( button.getAttribute( 'popovertarget' ) ).toBe( area.id );
			} );

			// Button clicks are handled by the popover, not by toggling the class
			document.querySelector( 'button.general-collapsible-expand-button' ).click();
			expect( collapsible.classList.contains( 'collapsed' ) ).toBe( true );

			dispatchToggle( area, 'open' );
			expect( collapsible.classList.contains( 'collapsed' ) ).toBe( false );
			dispatchToggle( area, 'closed' );
			expect( collapsible.classList.contains( 'collapsed' ) ).toBe( true );
		} );

		test( 'is idempotent when initialized again', () => {
			mockSupport( true );
			const { area } = render();
			globalThis.liquipedia.collapse.setupGeneralCollapsibleButtons();
			const id = area.id;
			globalThis.liquipedia.collapse.setupGeneralCollapsibleButtons();

			expect( area.id ).toBe( id );
			document.querySelectorAll( 'button' ).forEach( ( button ) => {
				expect( button.getAttribute( 'popovertarget' ) ).toBe( id );
			} );
		} );
	} );
} );
