/**
 * @jest-environment jsdom
 */

const { test, expect, beforeAll, beforeEach, describe } = require( '@jest/globals' );

	describe( 'Dropdown module', () => {
		beforeAll( () => {
			globalThis.liquipedia = {
				core: { modules: [] }
			};

			require( '../commons/Dropdown.js' );
		} );

		beforeEach( () => {
			document.body.innerHTML = '';
			liquipedia.dropdown.init();
		} );

	function createDropdownMarkup( label = 'Menu' ) {
		return `
			<div class="dropdown-widget dropdown-widget--form">
				<div class="dropdown-widget__toggle" data-dropdown-toggle="true" role="button" tabindex="0" aria-expanded="false" aria-haspopup="menu">
					<span>${ label }</span>
				</div>
				<div class="dropdown-widget__menu" aria-hidden="true">
					<ul>
						<li>Item</li>
					</ul>
				</div>
			</div>
		`;
	}

	test( 'should register itself as a module', () => {
		expect( globalThis.liquipedia.core.modules ).toContain( 'dropdown' );
	} );

	test( 'should toggle the dropdown on click and sync aria state', () => {
		document.body.innerHTML = createDropdownMarkup();

		const toggle = document.querySelector( '.dropdown-widget__toggle' );
		const menu = document.querySelector( '.dropdown-widget__menu' );

		toggle.dispatchEvent( new MouseEvent( 'click', { bubbles: true } ) );
		expect( menu.classList.contains( 'show' ) ).toBe( true );
		expect( toggle.getAttribute( 'aria-expanded' ) ).toBe( 'true' );
		expect( menu.getAttribute( 'aria-hidden' ) ).toBe( 'false' );

		toggle.dispatchEvent( new MouseEvent( 'click', { bubbles: true } ) );
		expect( menu.classList.contains( 'show' ) ).toBe( false );
		expect( toggle.getAttribute( 'aria-expanded' ) ).toBe( 'false' );
		expect( menu.getAttribute( 'aria-hidden' ) ).toBe( 'true' );
	} );

	test( 'should close other dropdowns when opening a new one', () => {
		document.body.innerHTML = `${ createDropdownMarkup( 'One' ) }${ createDropdownMarkup( 'Two' ) }`;

		const toggles = document.querySelectorAll( '.dropdown-widget__toggle' );
		const menus = document.querySelectorAll( '.dropdown-widget__menu' );

		toggles[ 0 ].dispatchEvent( new MouseEvent( 'click', { bubbles: true } ) );
		expect( menus[ 0 ].classList.contains( 'show' ) ).toBe( true );

		toggles[ 1 ].dispatchEvent( new MouseEvent( 'click', { bubbles: true } ) );
		expect( menus[ 0 ].classList.contains( 'show' ) ).toBe( false );
		expect( menus[ 1 ].classList.contains( 'show' ) ).toBe( true );
	} );

	test( 'should support keyboard toggle and escape close', () => {
		document.body.innerHTML = createDropdownMarkup();

		const toggle = document.querySelector( '.dropdown-widget__toggle' );
		const menu = document.querySelector( '.dropdown-widget__menu' );

		toggle.dispatchEvent( new KeyboardEvent( 'keydown', { key: 'Enter', bubbles: true } ) );
		expect( menu.classList.contains( 'show' ) ).toBe( true );

		document.dispatchEvent( new KeyboardEvent( 'keydown', { key: 'Escape', bubbles: true } ) );
		expect( menu.classList.contains( 'show' ) ).toBe( false );
		expect( document.activeElement ).toBe( toggle );
	} );

	test( 'should dispatch lifecycle events when opening and closing', () => {
		document.body.innerHTML = createDropdownMarkup();

		const dropdown = document.querySelector( '.dropdown-widget' );
		const toggle = document.querySelector( '.dropdown-widget__toggle' );
		const events = [];

		dropdown.addEventListener( 'dropdown:beforeopen', () => events.push( 'beforeopen' ) );
		dropdown.addEventListener( 'dropdown:open', () => events.push( 'open' ) );
		dropdown.addEventListener( 'dropdown:beforeclose', () => events.push( 'beforeclose' ) );
		dropdown.addEventListener( 'dropdown:close', () => events.push( 'close' ) );

		toggle.dispatchEvent( new MouseEvent( 'click', { bubbles: true } ) );
		toggle.dispatchEvent( new MouseEvent( 'click', { bubbles: true } ) );

		expect( events ).toEqual( [ 'beforeopen', 'open', 'beforeclose', 'close' ] );
	} );
} );
