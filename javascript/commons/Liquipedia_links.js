/*******************************************************************************
 * Template(s): Liquipedia links
 * Author(s): FO-nTTaX, Elysienna
 ******************************************************************************/
liquipedia.liquipedialinks = {
	init: function() {
		const countOtherWikis = parseInt( document.getElementById( 'ext-wikimenu' ).dataset.countOtherWikis );
		if ( countOtherWikis > 0 ) {
			const badge = document.createElement( 'span' );
			badge.classList.add(
				'badge', 'badge-pill', 'wiki-backgroundcolor-navbar-badge', 'liquipedia-links-badge'
			);
			badge.innerHTML = countOtherWikis;

			const badgeTooltip = document.createElement( 'span' );
			badgeTooltip.classList.add(
				'liquipedia-links-badge--tooltip'
			);

			if ( countOtherWikis > 1 ) {
				badgeTooltip.innerHTML = 'Find me on ' + countOtherWikis + ' other wikis too!';
			} else {
				badgeTooltip.innerHTML = 'Find me on ' + countOtherWikis + ' other wiki too!';
			}

			document.getElementById( 'brand-desktop' ).append( badge, badgeTooltip );
		}
	}
};
liquipedia.core.modules.push( 'liquipedialinks' );
