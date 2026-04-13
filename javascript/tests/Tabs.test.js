/**
 * @jest-environment jsdom
 */

const { test, expect, beforeAll, beforeEach, describe } = require( '@jest/globals' );

describe( 'Tabs module', () => {
	beforeAll( () => {
		globalThis.liquipedia = {
			core: { modules: [] },
			tracker: { track: () => {} }
		};
		require( '../commons/Dropdown.js' );
		require( '../commons/Tabs.js' );
	} );

	beforeEach( () => {
		document.body.innerHTML = '';
		window.location.hash = '';
	} );

	function createTabList( items ) {
		return `
			<div class="tabs-nav-wrapper">
				<ul class="nav-tabs">
					${ items.map( ( item ) => `
						<li${ item.active ? ' class="active"' : '' }>
							<a${ item.isNew ? ' class="new"' : '' } href="${ item.href || '#' }">${ item.label }</a>
						</li>
					` ).join( '' ) }
				</ul>
			</div>
		`;
	}

	function createStaticTabsMarkup( items, nestedMarkup = '', includeContent = true ) {
		return `
			<div data-analytics-name="Navigation tab">
				<div class="tabs-static">
					${ createTabList( items ) }
					${ includeContent ? `<div class="tabs-content">${ nestedMarkup }</div>` : nestedMarkup }
				</div>
			</div>
		`;
	}

	function initializeTabs() {
		liquipedia.dropdown.init();
		liquipedia.tabs.cleanup();
		liquipedia.tabs.init();
	}

	test( 'should register itself as a module', () => {
		expect( globalThis.liquipedia.core.modules ).toContain( 'tabs' );
	} );

	describe( 'static tabs', () => {
		test( 'should create the mobile dropdown shell during init', () => {
			document.body.innerHTML = createStaticTabsMarkup( [
				{ label: 'Results', href: '/wiki/Results', active: true },
				{ label: 'Other', href: '/wiki/Other' }
			] );

			expect( document.querySelector( '.tabs-static > .dropdown-widget' ) ).toBeNull();

			initializeTabs();

			const staticContainer = document.querySelector( '.tabs-static' );
			expect( staticContainer.getAttribute( 'data-mobile-dropdown-ready' ) ).toBe( 'true' );
			expect( staticContainer.querySelector( ':scope > .dropdown-widget' ) ).not.toBeNull();
		} );

		test( 'should support keyboard toggling on the dropdown', () => {
			document.body.innerHTML = createStaticTabsMarkup( [
				{ label: 'Results', href: '/wiki/Results', active: true },
				{ label: 'Other', href: '/wiki/Other' }
			] );

			initializeTabs();

			const toggle = document.querySelector( '.dropdown-widget__toggle' );
			const menu = document.querySelector( '.dropdown-widget__menu' );

			toggle.dispatchEvent( new KeyboardEvent( 'keydown', { key: 'Enter', bubbles: true } ) );
			expect( menu.classList.contains( 'show' ) ).toBe( true );
			expect( toggle.getAttribute( 'aria-expanded' ) ).toBe( 'true' );

			document.dispatchEvent( new KeyboardEvent( 'keydown', { key: 'Escape', bubbles: true } ) );
			expect( menu.classList.contains( 'show' ) ).toBe( false );
			expect( toggle.getAttribute( 'aria-expanded' ) ).toBe( 'false' );
		} );

		test( 'should build breadcrumb and nested mobile menu from grouped static tabs', () => {
			const nestedMarkup = createStaticTabsMarkup( [
				{ label: 'Standings', href: '/wiki/Standings', active: true },
				{ label: 'Other', href: '/wiki/Standings/Other' }
			], createStaticTabsMarkup( [
				{ label: 'Group A', href: '/wiki/Group_A', active: true },
				{ label: 'Other', href: '/wiki/Group_A/Other' }
			] ) );
			document.body.innerHTML = createStaticTabsMarkup( [
				{ label: 'Results', href: '/wiki/Results', active: true },
				{ label: 'Other', href: '/wiki/Results/Other' }
			], nestedMarkup );

			initializeTabs();

			const primary = document.querySelector( '.tabs-static' );
			const label = primary.querySelector( '.dropdown-widget__label' );
			expect( Array.from( label.childNodes ).map( ( node ) => node.textContent ).join( '' ) )
				.toBe( 'ResultsStandingsGroup A' );
			expect( label.querySelectorAll( 'i' ) ).toHaveLength( 2 );

			const mobileMenu = primary.querySelector( '.dropdown-widget__menu > ul' );
			const topLevelItems = Array.from( mobileMenu.children );
			expect( topLevelItems ).toHaveLength( 2 );
			expect( topLevelItems[ 0 ].textContent.replace( /\s+/g, ' ' ).trim() )
				.toBe( 'Results Standings Group A Other Other' );
			expect( topLevelItems[ 1 ].textContent.trim() ).toBe( 'Other' );

			const firstNested = topLevelItems[ 0 ].querySelector( 'ul' );
			expect( firstNested ).not.toBeNull();
			expect( Array.from( firstNested.children ).map( ( item ) => item.textContent.replace( /\s+/g, ' ' ).trim() ) )
				.toEqual( [ 'Standings Group A Other', 'Other' ] );

			const secondNested = firstNested.children[ 0 ].querySelector( 'ul' );
			expect( Array.from( secondNested.children ).map( ( item ) => item.textContent.trim() ) )
				.toEqual( [ 'Group A', 'Other' ] );
		} );

		test( 'should group adjacent sibling static rows into the same mobile menu', () => {
			document.body.innerHTML = `
				${ createStaticTabsMarkup( [
					{ label: 'Boston Major', href: '/wiki/Boston', active: true },
					{ label: 'Other', href: '/wiki/Boston/Other' }
				], '', false ) }
				${ createStaticTabsMarkup( [
					{ label: 'Europe', href: '/wiki/Europe', active: true },
					{ label: 'Other', href: '/wiki/Europe/Other' }
				], '', false ) }
			`;

			initializeTabs();

			const dropdowns = document.querySelectorAll( '.tabs-static > .dropdown-widget' );
			expect( dropdowns ).toHaveLength( 1 );
			expect( dropdowns[ 0 ].querySelector( '.dropdown-widget__menu > ul > li > ul' ) ).not.toBeNull();
		} );

		test( 'should group direct child nested static tabs rendered via tabsN', () => {
			document.body.innerHTML = createStaticTabsMarkup( [
				{ label: 'Finals', href: '/wiki/Finals' },
				{ label: 'Boston Major', href: '/wiki/Boston', active: true }
			], createStaticTabsMarkup( [
				{ label: 'Overview', href: '/wiki/Boston/Overview' },
				{ label: 'Europe', href: '/wiki/Boston/Europe', active: true }
			], '', false ), false );

			initializeTabs();

			const primary = document.querySelector( '.tabs-static' );
			expect(
				Array.from( primary.querySelector( '.dropdown-widget__label' ).childNodes )
					.map( ( node ) => node.textContent )
					.join( '' ),
			).toBe( 'Boston MajorEurope' );

			const nestedMenu = primary.querySelector( '.dropdown-widget__menu > ul > li.active > ul' );
			expect( Array.from( nestedMenu.children ).map( ( item ) => item.textContent.trim() ) )
				.toEqual( [ 'Overview', 'Europe' ] );
		} );
	} );

	describe( 'dynamic tabs', () => {
		test( 'should only activate dynamic containers on hash routing', () => {
			document.body.innerHTML = `
				<div class="tabs-dynamic">
					<div class="tabs-nav-wrapper">
						<div class="tabs-scroll-arrow-wrapper tabs-scroll-arrow-wrapper--left"></div>
						<ul class="nav-tabs">
							<li class="tab1 active"><a href="#">Tab 1</a></li>
							<li class="tab2"><a href="#">Tab 2</a></li>
						</ul>
						<div class="tabs-scroll-arrow-wrapper tabs-scroll-arrow-wrapper--right"></div>
					</div>
					<div class="tabs-content">
						<div class="content1 active"></div>
						<div class="content2"></div>
					</div>
				</div>
				${ createStaticTabsMarkup( [
					{ label: 'Static Root', href: '/wiki/Static_Root', active: true },
					{ label: 'Other', href: '/wiki/Other' }
				] ) }
			`;

			initializeTabs();

			window.location.hash = '#tab-2';
			window.dispatchEvent( new HashChangeEvent( 'hashchange' ) );

			expect( document.querySelector( '.tabs-dynamic .tab2' ).classList.contains( 'active' ) ).toBe( true );
			expect( document.querySelector( '.tabs-static .nav-tabs li.active' ).textContent.trim() ).toBe( 'Static Root' );
		} );
	} );
} );
