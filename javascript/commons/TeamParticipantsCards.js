/*******************************************************************************
 * Description: This script manages the team participants cards, specifically
 *              controlling whether rosters are shown or hidden based on user
 *              preferences.
 ******************************************************************************/

// Constants
const GROUP_NAME = 'team-cards-show-rosters';

liquipedia.teamParticipantsCards = {
	updateCards: function( showRosters ) {
		const teamCards = document.querySelectorAll( '.team-participant-card' );
		teamCards.forEach( ( card ) => {
			if ( showRosters ) {
				card.classList.remove( 'collapsed' );
			} else {
				card.classList.add( 'collapsed' );
			}
		} );
	},

	init: function() {
		// Listen for changes to the specific switch button with team-cards-show-rosters group
		document.addEventListener( 'switchButtonChanged', ( e ) => {
			if ( e.detail.data.name === GROUP_NAME ) {
				liquipedia.teamParticipantsCards.updateCards( e.detail.data.value );
			}
		} );

		// Initialize cards state based on current switch value
		liquipedia.switchButtons.getSwitchGroup( GROUP_NAME ).then( ( switchGroup ) => {
			if ( switchGroup ) {
				liquipedia.teamParticipantsCards.updateCards( switchGroup.value );
			}
		} );
	}
};

liquipedia.core.modules.push( 'teamParticipantsCards' );
