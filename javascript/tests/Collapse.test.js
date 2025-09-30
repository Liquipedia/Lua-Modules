/**
 * global global
 * @jest-environment jsdom
 */

const { test, expect, beforeAll, describe } = require( '@jest/globals' );

describe( 'Collapse module', () => {
	beforeAll( () => {
		// Initialize the global liquipedia object exactly as it appears in the main file
		global.liquipedia = {
			core: {
				modules: []
			}
		};

		// Require the collapse module
		require( '../commons/Collapse.js' );
	} );

	test( 'should register itself as a module', () => {
		expect( global.liquipedia.core.modules ).toContain( 'collapse' );
	} );

	test( 'makeIcon should return correct HTML for show/hide states', () => {
		const showIcon = global.liquipedia.collapse.makeIcon( true );
		const hideIcon = global.liquipedia.collapse.makeIcon( false );

		expect( showIcon ).toBe( '<span class="far fa-eye"></span>' );
		expect( hideIcon ).toBe( '<span class="far fa-eye-slash"></span>' );
	} );
} );
