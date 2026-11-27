/**
 * @jest-environment jsdom
 */

const { test, expect, beforeAll, beforeEach, afterEach, describe, jest: jestGlobals } = require( '@jest/globals' );

describe( 'Storage helper', () => {
	beforeAll( () => {
		globalThis.liquipedia = {
			core: {
				modules: []
			}
		};
		require( '../commons/Storage.js' );
	} );

	beforeEach( () => {
		window.localStorage.clear();
	} );

	afterEach( () => {
		jestGlobals.restoreAllMocks();
	} );

	test( 'reads, writes and removes strings', () => {
		const storage = globalThis.liquipedia.storage;
		expect( storage.get( 'key' ) ).toBeNull();
		storage.set( 'key', 'value' );
		expect( storage.get( 'key' ) ).toBe( 'value' );
		storage.remove( 'key' );
		expect( storage.get( 'key' ) ).toBeNull();
	} );

	test( 'round-trips JSON and falls back on missing or invalid values', () => {
		const storage = globalThis.liquipedia.storage;
		expect( storage.getJson( 'json', { fallback: true } ) ).toEqual( { fallback: true } );
		storage.setJson( 'json', { a: [ 1, 2 ] } );
		expect( storage.getJson( 'json', {} ) ).toEqual( { a: [ 1, 2 ] } );
		window.localStorage.setItem( 'json', '{invalid' );
		expect( storage.getJson( 'json', [] ) ).toEqual( [] );
	} );

	test( 'does not throw when storage is blocked', () => {
		const storage = globalThis.liquipedia.storage;
		const blocked = () => {
			throw new Error( 'SecurityError' );
		};
		jestGlobals.spyOn( Storage.prototype, 'getItem' ).mockImplementation( blocked );
		jestGlobals.spyOn( Storage.prototype, 'setItem' ).mockImplementation( blocked );
		jestGlobals.spyOn( Storage.prototype, 'removeItem' ).mockImplementation( blocked );

		expect( storage.get( 'key' ) ).toBeNull();
		expect( storage.getJson( 'key', 'fallback' ) ).toBe( 'fallback' );
		expect( () => storage.set( 'key', 'value' ) ).not.toThrow();
		expect( () => storage.setJson( 'key', {} ) ).not.toThrow();
		expect( () => storage.remove( 'key' ) ).not.toThrow();
	} );
} );
