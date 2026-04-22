/**
 * @jest-environment jsdom
 */

const { test, expect, beforeAll, beforeEach, describe } = require( '@jest/globals' );

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

	beforeEach( () => {
		document.body.innerHTML = '';
	} );

	function createCardMarkup( collapsed = true, switchActive = true ) {
		return `
			${ switchActive ? '<div class="switch-toggle-active" data-switch-group="team-cards-hover-roster"></div>' : '' }
			<div class="team-participant-card general-collapsible${ collapsed ? ' collapsed' : '' }">
				<div class="team-participant-card__opponent">
					<div class="name"><a href="#">Team Name</a></div>
				</div>
				<div class="should-collapse">roster content</div>
			</div>
		`;
	}

	test( 'should register itself as a module', () => {
		expect( globalThis.liquipedia.core.modules ).toContain( 'teamParticipantCard' );
	} );

	test( 'should add hover-roster-visible on mouseenter when card is collapsed', () => {
		document.body.innerHTML = createCardMarkup( true );
		liquipedia.teamParticipantCard.setupHoverTrigger();

		const card = document.querySelector( '.team-participant-card' );
		const link = document.querySelector( '.team-participant-card__opponent .name a' );

		link.dispatchEvent( new MouseEvent( 'mouseenter' ) );
		expect( card.classList.contains( 'hover-roster-visible' ) ).toBe( true );
	} );

	test( 'should remove hover-roster-visible on mouseleave', () => {
		document.body.innerHTML = createCardMarkup( true );
		liquipedia.teamParticipantCard.setupHoverTrigger();

		const card = document.querySelector( '.team-participant-card' );
		const link = document.querySelector( '.team-participant-card__opponent .name a' );

		link.dispatchEvent( new MouseEvent( 'mouseenter' ) );
		link.dispatchEvent( new MouseEvent( 'mouseleave' ) );
		expect( card.classList.contains( 'hover-roster-visible' ) ).toBe( false );
	} );

	test( 'should not add hover-roster-visible when card is not collapsed', () => {
		document.body.innerHTML = createCardMarkup( false );
		liquipedia.teamParticipantCard.setupHoverTrigger();

		const card = document.querySelector( '.team-participant-card' );
		const link = document.querySelector( '.team-participant-card__opponent .name a' );

		link.dispatchEvent( new MouseEvent( 'mouseenter' ) );
		expect( card.classList.contains( 'hover-roster-visible' ) ).toBe( false );
	} );
} );
