/**
 * @jest-environment jsdom
 */

const { test, expect, beforeAll, describe } = require( '@jest/globals' );

describe( 'TeamParticipantCard module', () => {
	beforeAll( () => {
		globalThis.liquipedia = {
			core: {
				modules: []
			}
		};

		globalThis.window.matchMedia = () => ( { matches: false } );

		require( '../commons/TeamParticipantCard.js' );
	} );

	test( 'should register itself as a module', () => {
		expect( globalThis.liquipedia.core.modules ).toContain( 'teamParticipantCard' );
	} );

	test( 'init should not throw when matchMedia returns false', () => {
		expect( () => {
			globalThis.liquipedia.teamParticipantCard.init();
		} ).not.toThrow();
	} );

	test( 'init should not throw when matchMedia is unavailable', () => {
		const original = globalThis.window.matchMedia;
		globalThis.window.matchMedia = undefined;

		expect( () => {
			globalThis.liquipedia.teamParticipantCard.init();
		} ).not.toThrow();

		globalThis.window.matchMedia = original;
	} );
} );
