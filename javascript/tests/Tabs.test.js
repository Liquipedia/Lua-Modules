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
			require( '../commons/Dropdown.js' );
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
					<div class="dropdown-widget dropdown-widget--form">
						<div class="dropdown-widget__toggle" data-dropdown-toggle="true" role="button" tabindex="0" aria-expanded="false" aria-haspopup="menu">
							<span class="dropdown-widget__prefix"></span>
							<span class="dropdown-widget__label"></span>
							<span class="dropdown-widget__indicator"></span>
						</div>
						<div class="dropdown-widget__menu" aria-hidden="true">
							<ul>
								<li class="active"><a href="/wiki/${ label }">${ label }</a></li>
								<li><a href="/wiki/Other">Other</a></li>
							</ul>
						</div>
					</div>
					<div class="tabs-content">${ nestedMarkup }</div>
				</div>
			</div>
		`;
	}

	describe( 'static tabs', () => {
		test( 'should support keyboard toggling on the dropdown', () => {
			document.body.innerHTML = createStaticTabsMarkup( 'Results' );

			liquipedia.dropdown.init();
			liquipedia.tabs.cleanup();
			liquipedia.tabs.init();

			const toggle = document.querySelector( '.dropdown-widget__toggle' );
			const menu = document.querySelector( '.dropdown-widget__menu' );

			toggle.dispatchEvent( new KeyboardEvent( 'keydown', { key: 'Enter', bubbles: true } ) );
			expect( menu.classList.contains( 'show' ) ).toBe( true );
			expect( toggle.getAttribute( 'aria-expanded' ) ).toBe( 'true' );

			document.dispatchEvent( new KeyboardEvent( 'keydown', { key: 'Escape', bubbles: true } ) );
			expect( menu.classList.contains( 'show' ) ).toBe( false );
			expect( toggle.getAttribute( 'aria-expanded' ) ).toBe( 'false' );
		} );

		test( 'should build merged nested dropdown breadcrumbs and menu', () => {
			const nestedMarkup = createStaticTabsMarkup( 'Standings', createStaticTabsMarkup( 'Group A' ) );
			document.body.innerHTML = createStaticTabsMarkup( 'Results', nestedMarkup );

			liquipedia.dropdown.init();
			liquipedia.tabs.cleanup();
			liquipedia.tabs.init();

			const staticContainers = document.querySelectorAll( '.tabs-static' );
			expect( staticContainers ).toHaveLength( 3 );

			const label = staticContainers[ 0 ].querySelector( '.dropdown-widget__label' );
			expect( Array.from( label.childNodes ).map( ( node ) => node.textContent ).join( '' ) )
				.toBe( 'ResultsStandingsGroup A' );
			expect( label.querySelectorAll( '.tabs-static-dropdown-separator' ) ).toHaveLength( 2 );

			const primaryMenu = staticContainers[ 0 ].querySelector( ':scope > .dropdown-widget > .dropdown-widget__menu > ul' );
			const primaryItems = primaryMenu.children;
			expect( primaryItems ).toHaveLength( 6 );
			expect( Array.from( primaryItems ).map( ( item ) => item.textContent.trim() ) )
				.toEqual( [ 'Results', 'Standings', 'Group A', 'Other', 'Other', 'Other' ] );
			expect( staticContainers[ 1 ].querySelector( '.dropdown-widget' ) ).not.toBeNull();
			expect( primaryItems[ 2 ].classList.contains( 'tabs-static-dropdown-item--nested' ) ).toBe( true );
			expect( primaryItems[ 3 ].classList.contains( 'tabs-static-dropdown-item--nested' ) ).toBe( true );
			expect( primaryItems[ 3 ].classList.contains( 'tabs-static-dropdown-item--group-end' ) ).toBe( true );
			expect( primaryItems[ 5 ].classList.contains( 'tabs-static-dropdown-item--nested' ) ).toBe( false );
		} );

		test( 'should still group adjacent sibling static rows', () => {
			document.body.innerHTML = `
				${ createStaticTabsMarkup( 'Boston Major' ) }
				${ createStaticTabsMarkup( 'Europe' ) }
			`;

			liquipedia.dropdown.init();
			liquipedia.tabs.cleanup();
			liquipedia.tabs.init();

			const staticContainers = document.querySelectorAll( '.tabs-static' );
			expect( staticContainers[ 1 ].classList.contains( 'tabs-static--group-child' ) ).toBe( true );
		} );

		test( 'should group direct child nested static tabs rendered via tabsN', () => {
			document.body.innerHTML = `
				<div data-analytics-name="Navigation tab">
					<div class="tabs-static">
						<div class="tabs-nav-wrapper">
							<ul class="nav-tabs">
							<li><a href="/wiki/Finals">Finals</a></li>
							<li class="active"><a href="/wiki/Boston">Boston Major</a></li>
						</ul>
					</div>
					<div class="dropdown-widget dropdown-widget--form">
						<div class="dropdown-widget__toggle" data-dropdown-toggle="true" role="button" tabindex="0" aria-expanded="false" aria-haspopup="menu">
							<span class="dropdown-widget__prefix"></span>
							<span class="dropdown-widget__label"></span>
							<span class="dropdown-widget__indicator"></span>
						</div>
						<div class="dropdown-widget__menu" aria-hidden="true">
							<ul>
								<li><a href="/wiki/Finals">Finals</a></li>
								<li class="active"><a href="/wiki/Boston">Boston Major</a></li>
							</ul>
						</div>
					</div>
					<div data-analytics-name="Navigation tab">
						<div class="tabs-static">
								<div class="tabs-nav-wrapper">
									<ul class="nav-tabs">
										<li><a href="/wiki/Boston/Overview">Overview</a></li>
										<li class="active"><a href="/wiki/Boston/Europe">Europe</a></li>
									</ul>
								</div>
								<div class="dropdown-widget dropdown-widget--form">
									<div class="dropdown-widget__toggle" data-dropdown-toggle="true" role="button" tabindex="0" aria-expanded="false" aria-haspopup="menu">
										<span class="dropdown-widget__prefix"></span>
										<span class="dropdown-widget__label"></span>
										<span class="dropdown-widget__indicator"></span>
									</div>
									<div class="dropdown-widget__menu" aria-hidden="true">
										<ul>
											<li><a href="/wiki/Boston/Overview">Overview</a></li>
											<li class="active"><a href="/wiki/Boston/Europe">Europe</a></li>
										</ul>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			`;

			liquipedia.dropdown.init();
			liquipedia.tabs.cleanup();
			liquipedia.tabs.init();

			const staticContainers = document.querySelectorAll( '.tabs-static' );
			expect( staticContainers[ 1 ].classList.contains( 'tabs-static--group-child' ) ).toBe( true );
			expect( staticContainers[ 1 ].querySelector( ':scope > .dropdown-widget' ) ).not.toBeNull();
			expect(
				Array.from( staticContainers[ 0 ].querySelector( '.dropdown-widget__label' ).childNodes )
					.map( ( node ) => node.textContent )
					.join( '' ),
			).toBe( 'Boston MajorEurope' );
		} );

		test( 'should not add a divider to the last dropdown item', () => {
			const nestedMarkup = createStaticTabsMarkup( 'Child Active' );
			document.body.innerHTML = `
				<div data-analytics-name="Navigation tab">
					<div class="tabs-static">
						<div class="tabs-nav-wrapper">
							<ul class="nav-tabs">
							<li><a href="/wiki/Before">Before</a></li>
							<li class="active"><a href="/wiki/Active">Active</a></li>
						</ul>
					</div>
					<div class="dropdown-widget dropdown-widget--form">
						<div class="dropdown-widget__toggle" data-dropdown-toggle="true" role="button" tabindex="0" aria-expanded="false" aria-haspopup="menu">
							<span class="tabs-static-dropdown-label"></span>
						</div>
						<div class="dropdown-widget__menu" aria-hidden="true">
							<ul>
								<li><a href="/wiki/Before">Before</a></li>
								<li class="active"><a href="/wiki/Active">Active</a></li>
							</ul>
						</div>
					</div>
					<div class="tabs-content">${ nestedMarkup }</div>
				</div>
				</div>
			`;

			liquipedia.dropdown.init();
			liquipedia.tabs.cleanup();
			liquipedia.tabs.init();

			const primaryMenu = document.querySelector( '.tabs-static > .dropdown-widget > .dropdown-widget__menu > ul' );
			const primaryItems = primaryMenu.children;
			expect( primaryItems[ primaryItems.length - 1 ].classList.contains( 'tabs-static-dropdown-item--group-end' ) )
				.toBe( false );
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

			liquipedia.dropdown.init();
			liquipedia.tabs.cleanup();
			liquipedia.tabs.init();

			window.location.hash = '#tab-2';
			window.dispatchEvent( new HashChangeEvent( 'hashchange' ) );

			expect( document.querySelector( '.tabs-dynamic .tab2' ).classList.contains( 'active' ) ).toBe( true );
			expect( document.querySelector( '.tabs-static .nav-tabs li.active' ).textContent.trim() ).toBe( 'Static Root' );
		} );
	} );
} );
