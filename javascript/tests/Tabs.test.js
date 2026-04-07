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
} );
