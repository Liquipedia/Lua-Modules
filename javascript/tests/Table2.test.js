/**
 * @jest-environment jsdom
 */
/* global jest */

const { test, expect, beforeAll, describe } = require( '@jest/globals' );

describe( 'Table2 module', () => {
	beforeAll( () => {
		globalThis.liquipedia = {
			core: {
				modules: []
			}
		};

		globalThis.mw = {
			loader: {
				using: jest.fn( () => Promise.resolve() )
			}
		};

		require( '../commons/Table2.js' );
	} );

	test( 'should register itself as a module', () => {
		expect( globalThis.liquipedia.core.modules ).toContain( 'table2' );
	} );

	test( 'should initialize table2 instance', () => {
		expect( globalThis.liquipedia.table2 ).toBeTruthy();
	} );

	test( 'should have init method', () => {
		expect( typeof globalThis.liquipedia.table2.init ).toBe( 'function' );
	} );

	test( 'should assign data-group-id to body rows during striping', () => {
		document.body.innerHTML = `
			<div class="table2">
				<table class="table2__table">
					<tbody>
						<tr class="table2__row--body"></tr>
						<tr class="table2__row--body"></tr>
						<tr class="table2__row--body"></tr>
					</tbody>
				</table>
			</div>
		`;

		globalThis.liquipedia.table2.init();

		const rows = document.querySelectorAll( '.table2 .table2__table tbody tr.table2__row--body' );
		expect( rows.length ).toBe( 3 );

		rows.forEach( ( row ) => {
			expect( row.getAttribute( 'data-group-id' ) ).toBeTruthy();
		} );
	} );

	test( 'should apply even class to alternating rows', () => {
		document.body.innerHTML = `
			<div class="table2">
				<table class="table2__table">
					<tbody>
						<tr class="table2__row--body"></tr>
						<tr class="table2__row--body"></tr>
						<tr class="table2__row--body"></tr>
						<tr class="table2__row--body"></tr>
					</tbody>
				</table>
			</div>
		`;

		globalThis.liquipedia.table2.init();

		const rows = document.querySelectorAll( '.table2 .table2__table tbody tr.table2__row--body' );

		expect( rows[ 0 ].classList.contains( 'table2__row--even' ) ).toBe( false );
		expect( rows[ 1 ].classList.contains( 'table2__row--even' ) ).toBe( true );
		expect( rows[ 2 ].classList.contains( 'table2__row--even' ) ).toBe( false );
		expect( rows[ 3 ].classList.contains( 'table2__row--even' ) ).toBe( true );
	} );

	test( 'should ignore standalone tables without .table2 wrapper', () => {
		document.body.innerHTML = `
			<table class="table2__table">
				<tbody>
					<tr><td>Standalone table row</td></tr>
				</tbody>
			</table>
		`;

		globalThis.liquipedia.table2.init();

		const row = document.querySelector( '.table2__table tbody tr' );
		expect( row.getAttribute( 'data-group-id' ) ).toBeNull();
	} );
} );
