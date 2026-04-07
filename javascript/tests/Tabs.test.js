/**
 * @jest-environment jsdom
 */

const { test, expect, beforeAll, describe } = require( '@jest/globals' );

describe( 'Tabs module', () => {
	beforeAll( () => {
		globalThis.liquipedia = {
			core: { modules: [] },
			tracker: { track: () => {} }
		};
		require( '../commons/Tabs.js' );
	} );

	test( 'should register itself as a module', () => {
		expect( globalThis.liquipedia.core.modules ).toContain( 'tabs' );
	} );

	describe( 'TabContainer protected methods', () => {
		test( 'should expose _setupContentHandlers as a method', () => {
			const container = document.createElement( 'div' );
			container.className = 'tabs-dynamic';
			const ul = document.createElement( 'ul' );
			ul.className = 'nav-tabs';
			container.appendChild( ul );
			document.body.appendChild( container );

			const tc = new globalThis.TabContainer( container );
			expect( typeof tc._setupContentHandlers ).toBe( 'function' );
			expect( typeof tc._setupScrollHandlers ).toBe( 'function' );
		} );
	} );

	describe( 'StaticTabContainer', () => {
		test( 'should initialize for .tabs-static elements', () => {
			const container = document.createElement( 'div' );
			container.className = 'tabs-static';
			const navWrapper = document.createElement( 'div' );
			navWrapper.className = 'tabs-nav-wrapper';
			const ul = document.createElement( 'ul' );
			ul.className = 'nav-tabs';
			navWrapper.appendChild( ul );
			container.appendChild( navWrapper );
			document.body.appendChild( container );

			const sc = new globalThis.StaticTabContainer( container );
			expect( sc.navTabs ).not.toBeNull();
		} );

		test( 'should toggle open class on dropdown menu when toggle is clicked', () => {
			const container = document.createElement( 'div' );
			container.className = 'tabs-static';
			const navWrapper = document.createElement( 'div' );
			navWrapper.className = 'tabs-nav-wrapper';
			const ul = document.createElement( 'ul' );
			ul.className = 'nav-tabs';
			const li = document.createElement( 'li' );
			li.className = 'active';
			li.textContent = 'Tab1';
			ul.appendChild( li );
			navWrapper.appendChild( ul );

			const dropdownDiv = document.createElement( 'div' );
			dropdownDiv.className = 'tabs-static-dropdown';
			const toggle = document.createElement( 'div' );
			toggle.className = 'tabs-static-dropdown-toggle';
			const label = document.createElement( 'span' );
			label.className = 'tabs-static-dropdown-label';
			toggle.appendChild( label );
			const menu = document.createElement( 'ul' );
			menu.className = 'tabs-static-dropdown-menu';
			dropdownDiv.appendChild( toggle );
			dropdownDiv.appendChild( menu );
			container.appendChild( navWrapper );
			container.appendChild( dropdownDiv );
			document.body.appendChild( container );

			new globalThis.StaticTabContainer( container );
			toggle.click();
			expect( menu.classList.contains( 'open' ) ).toBe( true );
			toggle.click();
			expect( menu.classList.contains( 'open' ) ).toBe( false );
		} );

		test( 'should build breadcrumb from active tab name', () => {
			const container = document.createElement( 'div' );
			container.className = 'tabs-static';
			const navWrapper = document.createElement( 'div' );
			navWrapper.className = 'tabs-nav-wrapper';
			const ul = document.createElement( 'ul' );
			ul.className = 'nav-tabs';
			const li = document.createElement( 'li' );
			li.className = 'active';
			li.textContent = 'Results';
			ul.appendChild( li );
			navWrapper.appendChild( ul );

			const dropdownDiv = document.createElement( 'div' );
			dropdownDiv.className = 'tabs-static-dropdown';
			const toggle = document.createElement( 'div' );
			toggle.className = 'tabs-static-dropdown-toggle';
			const label = document.createElement( 'span' );
			label.className = 'tabs-static-dropdown-label';
			toggle.appendChild( label );
			const menu = document.createElement( 'ul' );
			menu.className = 'tabs-static-dropdown-menu';
			dropdownDiv.appendChild( toggle );
			dropdownDiv.appendChild( menu );
			container.appendChild( navWrapper );
			container.appendChild( dropdownDiv );
			document.body.appendChild( container );

			new globalThis.StaticTabContainer( container );
			expect( label.textContent ).toBe( 'Results' );
		} );
	} );
} );
