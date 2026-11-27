/**
 * @jest-environment jsdom
 */

const { test, expect, beforeAll, beforeEach, afterEach, describe, jest: jestGlobal } = require( '@jest/globals' );

describe( 'FilterButtons popover', () => {
	let filterButtons;
	let FilterButtonsPopover;
	let apiGet;

	beforeAll( () => {
		apiGet = jestGlobal.fn( () => Promise.resolve( { parse: { text: { '*': 'expanded' } } } ) );
		globalThis.liquipedia = {
			core: { modules: [] },
			tracker: { track: () => {} },
			countdown: { init: () => {} },
			collapse: { init: () => {} },
			switchButtons: { init: () => {} },
			carousel: { init: () => {} },
			matchticker: { init: () => {} }
		};
		globalThis.mw = {
			config: { get: ( key ) => ( key === 'wgScriptPath' ? '/test' : 'Main_Page' ) },
			loader: { using: () => Promise.resolve() },
			Api: function() {
				this.get = apiGet;
			}
		};

		require( '../commons/Storage.js' );
		require( '../commons/FilterButtons.js' );
		filterButtons = globalThis.liquipedia.filterButtons;
		FilterButtonsPopover = globalThis.liquipedia.filterButtonsPopover;
	} );

	const item = ( value, isDefault ) => `<div data-filter-on="${ value }" data-filter-default="${ isDefault }"
		role="checkbox">${ value }</div>`;

	const render = ( extraHtml = '' ) => {
		document.body.innerHTML = `
			<div data-filter-popover>
				<div class="filter-popover__toggle" data-filter-popover-toggle>
					Filter<span data-filter-popover-count></span>
				</div>
				<div class="filter-popover__panel">
					<span data-filter-popover-category-count="mt-tier"></span>
					<span data-filter-popover-toggle-all="mt-tier"
						data-label-clear="Clear" data-label-select-all="Select all"></span>
					<div data-filter data-filter-staged data-filter-group="mt-tier">
						${ item( '1', true ) }${ item( '2', true ) }${ item( '3', false ) }
					</div>
					<span data-filter-popover-category-count="mt-region"></span>
					<span data-filter-popover-toggle-all="mt-region"
						data-label-clear="Clear" data-label-select-all="Select all"></span>
					<div data-filter data-filter-staged data-filter-group="mt-region">
						${ item( 'KR', true ) }${ item( 'CN', true ) }
					</div>
					<div data-filter-popover-action="reset">Reset</div>
					<div data-filter-popover-action="cancel">Cancel</div>
					<div data-filter-popover-action="apply">Apply</div>
				</div>
			</div>
			<div data-filter-expansion-template="Ticker" data-filter-groups="mt-tier,mt-region">default</div>
			${ extraHtml }
		`;
		filterButtons.init();
	};

	const query = ( selector ) => document.querySelector( selector );
	const click = ( selector ) => query( selector ).click();
	const checkedState = ( group, value ) => {
		const checkbox = query( `[data-filter-group="${ group }"] > [data-filter-on="${ value }"]` );
		return checkbox.getAttribute( 'aria-checked' );
	};
	const toggleCountText = () => query( '[data-filter-popover-count]' ).textContent;
	const tierStates = () => filterButtons.filterGroups[ 'mt-tier' ].filterStates;
	const regionStates = () => filterButtons.filterGroups[ 'mt-region' ].filterStates;
	const open = () => click( '.filter-popover__toggle' );

	beforeEach( () => {
		filterButtons.filterGroups = {};
		filterButtons.templateExpansions = [];
		filterButtons.hideableGroups = [];
		filterButtons.filterCounters = {};
		filterButtons.popovers = [];
		FilterButtonsPopover.supportsPopover = () => false;
		FilterButtonsPopover.supportsAnchorPositioning = () => false;
		window.localStorage.clear();
		apiGet.mockClear();
	} );

	test( 'replaces the toggle with a button and shows the default state', () => {
		render();

		const toggle = query( '.filter-popover__toggle' );
		expect( toggle.tagName ).toBe( 'BUTTON' );
		expect( toggle.getAttribute( 'aria-expanded' ) ).toBe( 'false' );

		expect( checkedState( 'mt-tier', '1' ) ).toBe( 'true' );
		expect( checkedState( 'mt-tier', '3' ) ).toBe( 'false' );
		// Every region is active by default, i.e. unrestricted, which is shown as nothing checked
		expect( checkedState( 'mt-region', 'KR' ) ).toBe( 'false' );
		expect( query( '[data-filter-popover-category-count="mt-tier"]' ).textContent ).toBe( '2' );
		expect( query( '[data-filter-popover-toggle-all="mt-tier"]' ).textContent ).toBe( 'Clear' );
		expect( query( '[data-filter-popover-toggle-all="mt-region"]' ).textContent ).toBe( 'Select all' );
		expect( toggleCountText() ).toBe( ' (2)' );
	} );

	test( 'only applies checked filters once confirmed', () => {
		render();
		open();
		expect( query( '[data-filter-popover]' ).classList.contains( 'filter-popover--open' ) ).toBe( true );

		click( '[data-filter-group="mt-tier"] > [data-filter-on="3"]' );
		expect( checkedState( 'mt-tier', '3' ) ).toBe( 'true' );
		expect( tierStates()[ '3' ] ).toBe( false );
		expect( toggleCountText() ).toBe( ' (2)' );

		click( '[data-filter-popover-action="apply"]' );
		expect( tierStates() ).toEqual( { 1: true, 2: true, 3: true } );
		expect( query( '[data-filter-popover]' ).classList.contains( 'filter-popover--open' ) ).toBe( false );
		// All tiers are active now, so there is no restriction left
		expect( toggleCountText() ).toBe( '' );
		expect( globalThis.liquipedia.storage.getJson( filterButtons.localStorageKey )[ 'mt-tier' ].filterStates )
			.toEqual( { 1: true, 2: true, 3: true } );
	} );

	test( 'discards pending changes on cancel', () => {
		render();
		open();
		click( '[data-filter-group="mt-tier"] > [data-filter-on="1"]' );
		click( '[data-filter-popover-action="cancel"]' );

		expect( tierStates()[ '1' ] ).toBe( true );
		open();
		expect( checkedState( 'mt-tier', '1' ) ).toBe( 'true' );
	} );

	test( 'discards pending changes when closed by clicking outside', () => {
		render();
		open();
		click( '[data-filter-group="mt-tier"] > [data-filter-on="1"]' );
		document.body.click();

		expect( query( '[data-filter-popover]' ).classList.contains( 'filter-popover--open' ) ).toBe( false );
		expect( checkedState( 'mt-tier', '1' ) ).toBe( 'true' );
	} );

	test( 'applies a group with nothing checked as unrestricted', () => {
		render();
		open();
		click( '[data-filter-group="mt-region"] > [data-filter-on="CN"]' );
		click( '[data-filter-popover-action="apply"]' );
		expect( regionStates() ).toEqual( { KR: false, CN: true } );
		expect( toggleCountText() ).toBe( ' (3)' );

		open();
		click( '[data-filter-group="mt-region"] > [data-filter-on="CN"]' );
		click( '[data-filter-popover-action="apply"]' );
		expect( regionStates() ).toEqual( { KR: true, CN: true } );
	} );

	test( 'clears or checks a whole group', () => {
		render();
		open();
		click( '[data-filter-popover-toggle-all="mt-tier"]' );
		expect( [ '1', '2', '3' ].map( ( value ) => checkedState( 'mt-tier', value ) ) )
			.toEqual( [ 'false', 'false', 'false' ] );
		expect( query( '[data-filter-popover-toggle-all="mt-tier"]' ).textContent ).toBe( 'Select all' );
		expect( query( '[data-filter-popover-category-count="mt-tier"]' ).classList )
			.toContain( 'filter-popover__category-count--empty' );

		click( '[data-filter-popover-toggle-all="mt-tier"]' );
		expect( [ '1', '2', '3' ].map( ( value ) => checkedState( 'mt-tier', value ) ) )
			.toEqual( [ 'true', 'true', 'true' ] );
	} );

	test( 'resets to the default filters', () => {
		render();
		open();
		click( '[data-filter-group="mt-tier"] > [data-filter-on="1"]' );
		click( '[data-filter-group="mt-region"] > [data-filter-on="KR"]' );
		click( '[data-filter-popover-action="reset"]' );

		expect( checkedState( 'mt-tier', '1' ) ).toBe( 'true' );
		expect( checkedState( 'mt-region', 'KR' ) ).toBe( 'false' );
	} );

	test( 'keeps regular filter buttons applying immediately next to a popover', () => {
		render( `
			<div class="filter-buttons" data-filter data-filter-group="tournaments-tier">
				<span class="filter-button" data-filter-on="all">All</span>
				<span class="filter-button filter-button--active" data-filter-on="1">S</span>
				<span class="filter-button" data-filter-on="2">A</span>
			</div>
			<div data-filter-group="tournaments-tier" data-filter-category="2">A-Tier tournament</div>
		` );

		const tournament = query( '[data-filter-category="2"]' );
		expect( tournament.classList ).toContain( 'filter-category--hidden' );
		click( '.filter-buttons [data-filter-on="2"]' );
		expect( filterButtons.filterGroups[ 'tournaments-tier' ].filterStates[ '2' ] ).toBe( true );
		expect( tournament.classList ).not.toContain( 'filter-category--hidden' );
		expect( query( '.filter-buttons [data-filter-on="all"]' ).classList ).toContain( 'filter-button--active' );
		// The popover groups are unaffected
		expect( tierStates() ).toEqual( { 1: true, 2: true, 3: false } );
	} );

	test( 'toggles checkboxes with the keyboard', () => {
		render();
		open();
		const checkbox = query( '[data-filter-group="mt-tier"] > [data-filter-on="3"]' );
		expect( checkbox.getAttribute( 'tabindex' ) ).toBe( '0' );
		checkbox.dispatchEvent( new KeyboardEvent( 'keydown', { key: ' ', bubbles: true } ) );
		expect( checkedState( 'mt-tier', '3' ) ).toBe( 'true' );
		checkbox.dispatchEvent( new KeyboardEvent( 'keydown', { key: 'Enter', bubbles: true } ) );
		expect( checkedState( 'mt-tier', '3' ) ).toBe( 'false' );
	} );

	test( 'returns focus to the toggle when closed from within the panel', () => {
		render();
		const toggle = query( '.filter-popover__toggle' );
		const pressKey = ( element, key ) => element.dispatchEvent(
			new KeyboardEvent( 'keydown', { key, bubbles: true } )
		);
		const focusInPanel = ( selector ) => {
			const element = query( selector );
			element.tabIndex = 0;
			element.focus();
			expect( document.activeElement ).toBe( element );
			return element;
		};

		[ 'apply', 'cancel' ].forEach( ( action ) => {
			open();
			pressKey( focusInPanel( `[data-filter-popover-action="${ action }"]` ), 'Enter' );
			expect( query( '[data-filter-popover]' ).classList.contains( 'filter-popover--open' ) ).toBe( false );
			expect( document.activeElement ).toBe( toggle );
		} );

		open();
		pressKey( focusInPanel( '[data-filter-group="mt-tier"] > [data-filter-on="3"]' ), 'Escape' );
		expect( query( '[data-filter-popover]' ).classList.contains( 'filter-popover--open' ) ).toBe( false );
		expect( document.activeElement ).toBe( toggle );
	} );

	test( 'passes the applied filters to the template expansion', async () => {
		render();
		open();
		click( '[data-filter-group="mt-region"] > [data-filter-on="CN"]' );
		click( '[data-filter-popover-action="apply"]' );
		// The API is only requested after the MediaWiki modules have loaded
		await new Promise( ( resolve ) => {
			setTimeout( resolve, 0 );
		} );

		expect( apiGet ).toHaveBeenCalledTimes( 1 );
		expect( apiGet.mock.calls[ 0 ][ 0 ].text ).toBe( '{{Ticker|mt-tier=1,2|mt-region=CN}}' );
	} );

	describe( 'with native popover support', () => {
		const dispatchToggle = ( element, newState ) => {
			const event = new Event( 'beforetoggle' );
			event.newState = newState;
			element.dispatchEvent( event );
		};

		beforeEach( () => {
			FilterButtonsPopover.supportsPopover = () => true;
			FilterButtonsPopover.supportsAnchorPositioning = () => true;
			HTMLElement.prototype.showPopover = function() {
				dispatchToggle( this, 'open' );
			};
			HTMLElement.prototype.hidePopover = function() {
				dispatchToggle( this, 'closed' );
			};
		} );

		afterEach( () => {
			delete HTMLElement.prototype.showPopover;
			delete HTMLElement.prototype.hidePopover;
		} );

		test( 'sets up an anchored popover invoked by the toggle', () => {
			render();
			const panel = query( '.filter-popover__panel' );
			const toggle = query( '.filter-popover__toggle' );

			expect( panel.getAttribute( 'popover' ) ).toBe( 'auto' );
			expect( toggle.getAttribute( 'popovertarget' ) ).toBe( panel.id );
			expect( toggle.style.getPropertyValue( 'anchor-name' ) )
				.toBe( panel.style.getPropertyValue( 'position-anchor' ) );
			expect( query( '[data-filter-popover]' ).classList ).toContain( 'filter-popover--anchored' );
		} );

		test( 'discards pending changes on light dismiss and closes after applying', () => {
			render();
			const panel = query( '.filter-popover__panel' );
			const toggle = query( '.filter-popover__toggle' );

			dispatchToggle( panel, 'open' );
			expect( toggle.getAttribute( 'aria-expanded' ) ).toBe( 'true' );
			click( '[data-filter-group="mt-tier"] > [data-filter-on="1"]' );
			dispatchToggle( panel, 'closed' );
			expect( checkedState( 'mt-tier', '1' ) ).toBe( 'true' );

			dispatchToggle( panel, 'open' );
			click( '[data-filter-group="mt-tier"] > [data-filter-on="1"]' );
			click( '[data-filter-popover-action="apply"]' );
			expect( tierStates()[ '1' ] ).toBe( false );
			expect( toggle.getAttribute( 'aria-expanded' ) ).toBe( 'false' );
		} );
	} );
} );
