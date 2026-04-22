/*******************************************************************************
 * Template(s): Team Participant Card hover roster
 * Author(s): Liquipedia
 ******************************************************************************/
liquipedia.teamParticipantCard = {
	init: function() {
		if ( !window.matchMedia || !window.matchMedia( '(hover: hover) and (pointer: fine)' ).matches ) {
			return;
		}
		this.setupHoverTrigger();
	},

	setupHoverTrigger: function() {
		document.querySelectorAll( '.team-participant-card' ).forEach( ( card ) => {
			const roster = card.querySelector( '.should-collapse' );
			if ( !roster ) {
				return;
			}

			const nameLinks = card.querySelectorAll( '.team-participant-card__opponent .name a' );

			nameLinks.forEach( ( link ) => {
				link.addEventListener( 'mouseenter', () => {
					if ( !card.classList.contains( 'collapsed' ) ) {
						return;
					}
					card.classList.add( 'hover-roster-visible' );

					requestAnimationFrame( () => {
						if ( !card.classList.contains( 'hover-roster-visible' ) ) {
							return;
						}
						const cardRect = card.getBoundingClientRect();
						const linkRect = link.getBoundingClientRect();
						const remInPx = parseFloat( getComputedStyle( document.documentElement ).fontSize );
						const gap = 0.75 * remInPx;

						const linkCenterX = linkRect.left + linkRect.width / 2 - cardRect.left;
						const rosterWidth = roster.offsetWidth;

						let left = linkCenterX - rosterWidth / 2;
						if ( cardRect.left + left + rosterWidth > window.innerWidth ) {
							left = window.innerWidth - cardRect.left - rosterWidth;
						}
						if ( cardRect.left + left < 0 ) {
							left = -cardRect.left;
						}

						const top = linkRect.bottom - cardRect.top + gap;

						roster.style.left = left + 'px';
						roster.style.top = top + 'px';
					} );
				} );

				link.addEventListener( 'mouseleave', () => {
					card.classList.remove( 'hover-roster-visible' );
					roster.style.left = '';
					roster.style.top = '';
				} );
			} );
		} );
	}
};

liquipedia.core.modules.push( 'teamParticipantCard' );
