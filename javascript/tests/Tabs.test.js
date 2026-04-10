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

	function createStaticTabsMarkup( label, nestedMarkup = '' ) {
		return `
			<div data-analytics-name="Navigation tab">
				<div class="tabs-static">
					<div class="tabs-nav-wrapper">
						<ul class="nav-tabs">
							<li class="active"><a href="/wiki/${ label }">${ label }</a></li>
							<li><a href="/wiki/Other">Other</a></li>
						</ul>
					</div>
					<div class="tabs-static-dropdown">
						<div class="tabs-static-dropdown-toggle" role="button" tabindex="0" aria-expanded="false" aria-haspopup="menu">
							<span class="tabs-static-dropdown-label"></span>
						</div>
						<ul class="tabs-static-dropdown-menu" aria-hidden="true">
							<li class="active"><a href="/wiki/${ label }">${ label }</a></li>
							<li><a href="/wiki/Other">Other</a></li>
						</ul>
					</div>
					<div class="tabs-content">${ nestedMarkup }</div>
				</div>
			</div>
		`;
	}

	describe( 'static tabs', () => {
		test( 'should support keyboard toggling on the dropdown', () => {
			document.body.innerHTML = createStaticTabsMarkup( 'Results' );

			liquipedia.tabs.cleanup();
			liquipedia.tabs.init();

			const toggle = document.querySelector( '.tabs-static-dropdown-toggle' );
			const menu = document.querySelector( '.tabs-static-dropdown-menu' );

			toggle.dispatchEvent( new KeyboardEvent( 'keydown', { key: 'Enter', bubbles: true } ) );
			expect( menu.classList.contains( 'open' ) ).toBe( true );
			expect( toggle.getAttribute( 'aria-expanded' ) ).toBe( 'true' );

			document.dispatchEvent( new KeyboardEvent( 'keydown', { key: 'Escape', bubbles: true } ) );
			expect( menu.classList.contains( 'open' ) ).toBe( false );
			expect( toggle.getAttribute( 'aria-expanded' ) ).toBe( 'false' );
		} );

		test( 'should build merged nested dropdown breadcrumbs and menu', () => {
			const nestedMarkup = createStaticTabsMarkup( 'Standings', createStaticTabsMarkup( 'Group A' ) );
			document.body.innerHTML = createStaticTabsMarkup( 'Results', nestedMarkup );

			liquipedia.tabs.cleanup();
			liquipedia.tabs.init();

			const staticContainers = document.querySelectorAll( '.tabs-static' );
			expect( staticContainers ).toHaveLength( 3 );
			expect( staticContainers[ 1 ].classList.contains( 'tabs-static--group-child' ) ).toBe( true );

			const label = staticContainers[ 0 ].querySelector( '.tabs-static-dropdown-label' );
			expect( label.textContent ).toBe( 'Results>Standings>Group A' );
			expect( label.querySelectorAll( '.tabs-static-dropdown-separator' ) ).toHaveLength( 2 );

			const primaryMenu = staticContainers[ 0 ].querySelector( ':scope > .tabs-static-dropdown > .tabs-static-dropdown-menu' );
			const primaryItems = primaryMenu.children;
			expect( primaryItems ).toHaveLength( 6 );
			expect( staticContainers[ 1 ].querySelector( '.tabs-static-dropdown' ) ).not.toBeNull();
			expect( primaryItems[ 2 ].classList.contains( 'tabs-static-dropdown-item--nested' ) ).toBe( true );
			expect( primaryItems[ 3 ].classList.contains( 'tabs-static-dropdown-item--group-end' ) ).toBe( true );
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
				${ createStaticTabsMarkup( 'Static Root' ) }
			`;

			liquipedia.tabs.cleanup();
			liquipedia.tabs.init();

			window.location.hash = '#tab-2';
			window.dispatchEvent( new HashChangeEvent( 'hashchange' ) );

			expect( document.querySelector( '.tabs-dynamic .tab2' ).classList.contains( 'active' ) ).toBe( true );
			expect( document.querySelector( '.tabs-static .nav-tabs li.active' ).textContent.trim() ).toBe( 'Static Root' );
		} );
	} );
} );
