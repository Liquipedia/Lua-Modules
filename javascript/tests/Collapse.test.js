/**
 * @jest-environment jsdom
 */

const { test, expect, beforeAll, beforeEach, describe } = require( '@jest/globals' );

describe( 'Collapse module', () => {
	beforeAll( () => {
		globalThis.liquipedia = {
			core: {
				modules: []
			}
		};

		require( '../commons/Storage.js' );
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

		test( 'sets up again after the HTML is serialized and restored', () => {
			mockSupport( true );
			render();
			globalThis.liquipedia.collapse.setupGeneralCollapsibleButtons();

			// FilterButtons caches innerHTML after init and restores it later
			const container = document.getElementById( 'mw-content-text' );
			container.innerHTML = container.innerHTML; // eslint-disable-line no-self-assign
			globalThis.liquipedia.collapse.setupGeneralCollapsibleButtons();

			const collapsible = document.querySelector( '.general-collapsible' );
			const area = document.querySelector( '.should-collapse' );
			document.querySelectorAll( 'button' ).forEach( ( button ) => {
				expect( button.getAttribute( 'popovertarget' ) ).toBe( area.id );
			} );
			dispatchToggle( area, 'open' );
			expect( collapsible.classList.contains( 'collapsed' ) ).toBe( false );
			dispatchToggle( area, 'closed' );
			expect( collapsible.classList.contains( 'collapsed' ) ).toBe( true );
		} );
	} );

	describe( 'persistent collapsibles', () => {
		const render = ( collapsed ) => {
			const classes = collapsed ? 'general-collapsible collapsed' : 'general-collapsible';
			document.body.innerHTML = `
				<div id="mw-content-text">
					<div class="${ classes }" data-collapsible-storage-key="test">
						<span class="general-collapsible-expand-button">Show</span>
						<span class="general-collapsible-collapse-button">Hide</span>
						<div class="should-collapse">Content</div>
					</div>
				</div>
			`;
			return document.querySelector( '.general-collapsible' );
		};

		beforeEach( () => {
			window.localStorage.clear();
		} );

		test( 'keeps the server state when nothing is stored', () => {
			const collapsible = render( true );
			globalThis.liquipedia.collapse.setupPersistentCollapsibles();
			expect( collapsible.classList.contains( 'collapsed' ) ).toBe( true );
		} );

		test( 'restores the stored state', () => {
			window.localStorage.setItem( 'collapsible-test', 'expanded' );
			const collapsible = render( true );
			globalThis.liquipedia.collapse.setupPersistentCollapsibles();
			expect( collapsible.classList.contains( 'collapsed' ) ).toBe( false );
		} );

		test( 'ignores popover collapsibles', async () => {
			window.localStorage.setItem( 'collapsible-test', 'expanded' );
			const collapsible = render( true );
			collapsible.setAttribute( 'data-collapsible-popover', 'true' );
			globalThis.liquipedia.collapse.setupPersistentCollapsibles();
			expect( collapsible.classList.contains( 'collapsed' ) ).toBe( true );
			collapsible.classList.remove( 'collapsed' );
			await Promise.resolve();
			expect( window.localStorage.getItem( 'collapsible-test' ) ).toBe( 'expanded' );
			collapsible.classList.add( 'collapsed' );
			await Promise.resolve();
			expect( window.localStorage.getItem( 'collapsible-test' ) ).toBe( 'expanded' );
		} );

		test( 'stores the state when toggled', async () => {
			const collapsible = render( false );
			globalThis.liquipedia.collapse.setupPersistentCollapsibles();
			collapsible.classList.add( 'collapsed' );
			await Promise.resolve();
			expect( window.localStorage.getItem( 'collapsible-test' ) ).toBe( 'collapsed' );
		} );
	} );
} );
