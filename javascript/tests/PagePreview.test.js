/**
 * @jest-environment jsdom
 */
const { test, expect, beforeEach, describe } = require( '@jest/globals' );

function mockMatchMedia( matches ) {
	window.matchMedia = () => ( { matches } );
}

function loadModule() {
	jest.resetModules();
	globalThis.liquipedia = { core: { modules: [] } };
	require( '../commons/PagePreview.js' );
	return globalThis.liquipedia.pagePreview;
}

function setIsland( obj ) {
	const el = document.createElement( 'div' );
	el.id = 'page-preview-data';
	el.style.display = 'none';
	el.setAttribute( 'data-preview', JSON.stringify( obj ) );
	document.body.appendChild( el );
}

describe( 'PagePreview module', () => {
	beforeEach( () => {
		document.body.innerHTML = '';
	} );

	test( 'registers itself as a module', () => {
		mockMatchMedia( true );
		loadModule();
		expect( globalThis.liquipedia.core.modules ).toContain( 'pagePreview' );
	} );

	test( 'loads the island into the data Map on init', () => {
		mockMatchMedia( true );
		setIsland( { Supr: { name: 'supr', type: 'player' } } );
		const mod = loadModule();
		mod.init();
		expect( mod.data.size ).toBe( 1 );
		expect( mod.data.get( 'Supr' ).name ).toBe( 'supr' );
	} );

	test( 'no-op on coarse pointer (does not load data)', () => {
		mockMatchMedia( false );
		setIsland( { Supr: { name: 'supr' } } );
		const mod = loadModule();
		mod.init();
		expect( mod.data.size ).toBe( 0 );
	} );

	test( 'tolerates a missing island', () => {
		mockMatchMedia( true );
		const mod = loadModule();
		expect( () => mod.init() ).not.toThrow();
		expect( mod.data.size ).toBe( 0 );
	} );

	describe( 'hover behaviour', () => {
		function setup( data ) {
			mockMatchMedia( true );
			document.body.innerHTML =
				'<div id="mw-content-text"><a class="link-preview" data-preview-page="Supr" href="/Supr">supr</a></div>';
			setIsland( data );
			const mod = loadModule();
			mod.init();
			return mod;
		}

		test( 'shows a card after the hover-intent delay, built from data (no network)', () => {
			jest.useFakeTimers();
			const fetchSpy = jest.fn();
			global.fetch = fetchSpy;
			const mod = setup( { Supr: { name: 'supr', realName: 'Seth Hoffman', team: 'Soniqs', type: 'player' } } );
			const link = document.querySelector( '.link-preview' );

			link.dispatchEvent( new MouseEvent( 'mouseover', { bubbles: true } ) );
			expect( document.querySelector( '.page-preview-card' ) ).toBeNull();

			jest.advanceTimersByTime( 150 );
			const card = document.querySelector( '.page-preview-card' );
			expect( card ).not.toBeNull();
			expect( card.style.display ).toBe( 'block' );
			// nickname is not repeated (it is the link text); real name and fields are shown
			expect( card.textContent ).not.toContain( 'supr' );
			expect( card.textContent ).toContain( 'Seth Hoffman' );
			expect( card.textContent ).toContain( 'Soniqs' );
			expect( fetchSpy ).not.toHaveBeenCalled();
			jest.useRealTimers();
		} );

		test( 'does not show if the cursor leaves before the delay elapses', () => {
			jest.useFakeTimers();
			const mod = setup( { Supr: { name: 'supr' } } );
			const link = document.querySelector( '.link-preview' );
			link.dispatchEvent( new MouseEvent( 'mouseover', { bubbles: true } ) );
			link.dispatchEvent( new MouseEvent( 'mouseout', { bubbles: true } ) );
			jest.advanceTimersByTime( 300 );
			const card = document.querySelector( '.page-preview-card' );
			expect( card === null || card.style.display === 'none' ).toBe( true );
			jest.useRealTimers();
		} );

		test( 'escapes HTML in card fields', () => {
			jest.useFakeTimers();
			const mod = setup( { Supr: { realName: '<img src=x onerror=alert(1)>', type: 'player' } } );
			document.querySelector( '.link-preview' ).dispatchEvent( new MouseEvent( 'mouseover', { bubbles: true } ) );
			jest.advanceTimersByTime( 150 );
			const card = document.querySelector( '.page-preview-card' );
			expect( card.querySelector( 'img.injected' ) ).toBeNull();
			expect( card.innerHTML ).toContain( '&lt;img' );
			jest.useRealTimers();
		} );

		test( 'does not trigger when hovering the wrapper box outside the link text', () => {
			jest.useFakeTimers();
			mockMatchMedia( true );
			document.body.innerHTML =
				'<div id="mw-content-text"><span class="link-preview" data-preview-page="Supr">' +
				'<a href="/Supr">supr</a><span class="pad">padding</span></span></div>';
			setIsland( { Supr: { name: 'supr', type: 'player' } } );
			const mod = loadModule();
			mod.init();

			document.querySelector( '.pad' ).dispatchEvent( new MouseEvent( 'mouseover', { bubbles: true } ) );
			jest.advanceTimersByTime( 150 );
			expect( document.querySelector( '.page-preview-card' ) ).toBeNull();

			document.querySelector( 'a' ).dispatchEvent( new MouseEvent( 'mouseover', { bubbles: true } ) );
			jest.advanceTimersByTime( 150 );
			expect( document.querySelector( '.page-preview-card' ) ).not.toBeNull();
			jest.useRealTimers();
		} );

		test( 'hides when the cursor moves from the link onto the card (card is not sticky)', () => {
			jest.useFakeTimers();
			const mod = setup( { Supr: { name: 'supr', type: 'player' } } );
			const link = document.querySelector( '.link-preview' );
			link.dispatchEvent( new MouseEvent( 'mouseover', { bubbles: true } ) );
			jest.advanceTimersByTime( 150 );
			const card = document.querySelector( '.page-preview-card' );
			expect( card.style.display ).toBe( 'block' );

			// leave the link heading straight for the card
			link.dispatchEvent( new MouseEvent( 'mouseout', { bubbles: true, relatedTarget: card } ) );
			card.dispatchEvent( new MouseEvent( 'mouseover', { bubbles: true } ) );
			jest.advanceTimersByTime( 100 );
			expect( card.style.display ).toBe( 'none' );
			jest.useRealTimers();
		} );

		test( 'renders wiki-specific extra fields, escaped', () => {
			jest.useFakeTimers();
			const mod = setup( { Supr: {
				name: 'supr',
				type: 'player',
				extra: [ { label: 'Region', value: 'Europe' }, { label: 'X', value: '<b>y</b>' } ]
			} } );
			document.querySelector( '.link-preview' ).dispatchEvent( new MouseEvent( 'mouseover', { bubbles: true } ) );
			jest.advanceTimersByTime( 150 );
			const card = document.querySelector( '.page-preview-card' );
			const keys = [ ...card.querySelectorAll( '.table2__table th' ) ].map( ( n ) => n.textContent );
			const values = [ ...card.querySelectorAll( '.table2__table td' ) ].map( ( n ) => n.textContent );
			expect( keys ).toContain( 'Region' );
			expect( values ).toContain( 'Europe' );
			expect( card.querySelector( 'b' ) ).toBeNull();
			expect( card.innerHTML ).toContain( '&lt;b&gt;y&lt;/b&gt;' );
			jest.useRealTimers();
		} );

		test( 'renders fields as a striped Table2', () => {
			jest.useFakeTimers();
			const mod = setup( { Supr: {
				name: 'supr', type: 'player', flag: 'United States', status: 'Active', team: 'Soniqs'
			} } );
			document.querySelector( '.link-preview' ).dispatchEvent( new MouseEvent( 'mouseover', { bubbles: true } ) );
			jest.advanceTimersByTime( 150 );
			const bodyRows = document.querySelectorAll( '.table2 .table2__table tr.table2__row--body' );
			expect( bodyRows ).toHaveLength( 3 );
			// matches Table2.js striping: first body row not even, second even, third not
			expect( bodyRows[ 0 ].classList.contains( 'table2__row--even' ) ).toBe( false );
			expect( bodyRows[ 1 ].classList.contains( 'table2__row--even' ) ).toBe( true );
			expect( bodyRows[ 2 ].classList.contains( 'table2__row--even' ) ).toBe( false );
			jest.useRealTimers();
		} );

		test( 'destroy removes the card and clears timers', () => {
			const mod = setup( { Supr: { name: 'supr' } } );
			mod.show( document.querySelector( '.link-preview' ) );
			expect( document.querySelector( '.page-preview-card' ) ).not.toBeNull();
			mod.destroy();
			expect( document.querySelector( '.page-preview-card' ) ).toBeNull();
		} );
	} );
} );
