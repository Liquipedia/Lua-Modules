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
} );
