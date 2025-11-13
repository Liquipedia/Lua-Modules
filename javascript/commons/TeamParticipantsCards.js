( function() {
	const GROUP_NAME = 'team-cards-show-rosters';

	const updateCards = ( showRosters ) => {
		const teamCards = document.querySelectorAll( '.team-participant-card' );
		teamCards.forEach( ( card ) => {
			if ( showRosters ) {
				card.classList.remove( 'collapsed' );
			} else {
				card.classList.add( 'collapsed' );
			}
		} );
	};

	// Handle switch changes
	document.addEventListener( 'switchButtonChanged', ( e ) => {
		if ( e.detail.data.name === GROUP_NAME ) {
			updateCards( e.detail.data.value );
		}
	} );

	// Handle initial state on page load
	if ( window.liquipedia && window.liquipedia.switchButtons ) {
		liquipedia.switchButtons.getSwitchGroup( GROUP_NAME ).then( ( switchGroup ) => {
			if ( switchGroup ) {
				updateCards( switchGroup.value );
			}
		} );
	}
}() );
