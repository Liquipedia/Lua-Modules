/*******************************************************************************
 * Template(s): Team Participant Card hover roster
 * Author(s): Liquipedia
 ******************************************************************************/
liquipedia.teamParticipantCard = {
	init: function() {
		if ( !window.matchMedia || !window.matchMedia( '(hover: hover) and (pointer: fine)' ).matches ) {
			return;
		}
		this.setupEdgeAvoidance();
	},

	setupEdgeAvoidance: function() {
		document.querySelectorAll( '.team-participant-card' ).forEach( ( card ) => {
			const roster = card.querySelector( '.should-collapse' );
			const header = card.querySelector( '.team-participant-card__header' );
			if ( !roster || !header ) {
				return;
			}

			header.addEventListener( 'mouseenter', () => {
				if ( !card.classList.contains( 'collapsed' ) ) {
					return;
				}
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

			card.addEventListener( 'mouseleave', () => {
				roster.style.left = '';
				roster.style.right = '';
			} );
		} );
	}
};

liquipedia.core.modules.push( 'teamParticipantCard' );
