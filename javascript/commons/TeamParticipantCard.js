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
					roster.style.left = '';
					roster.style.right = '';

					requestAnimationFrame( () => {
						const rect = roster.getBoundingClientRect();
						if ( rect.right > window.innerWidth ) {
							roster.style.left = 'auto';
							roster.style.right = '0';
						}
					} );
				} );

				link.addEventListener( 'mouseleave', () => {
					card.classList.remove( 'hover-roster-visible' );
					roster.style.left = '';
					roster.style.right = '';
				} );
			} );
		} );
	}
};

liquipedia.core.modules.push( 'teamParticipantCard' );
