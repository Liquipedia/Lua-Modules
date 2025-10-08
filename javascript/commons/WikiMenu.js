/*******************************************************************************
 * Template(s): Wiki menu
 * Author(s):
 ******************************************************************************/
liquipedia.wikimenu = {
	init: function() {
		const links = document.querySelectorAll( '[data-wiki-menu="link"]' );

		links.forEach( ( link ) => {
			const eventProperties = {
				wiki: link.closest( '[data-wiki-id]' ).dataset.wikiId,
				'page url': window.location.href,
				position: 'wiki menu',
				destination: link.href,
				'trending page': false,
				'trending position': null
			};

			link.addEventListener( 'click', () => {
				window.amplitude.track( 'Wiki switched', eventProperties );
			} );
		} );
	}
};
liquipedia.core.modules.push( 'wikimenu' );
