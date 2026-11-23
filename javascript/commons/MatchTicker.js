class LiquipediaMatchTickerCard {
	/**
	 * @param {HTMLElement} cardElement
	 */
	constructor( cardElement ) {
		this.cardElement = cardElement;
		this.parsedDate = new Date( 1000 * parseInt( this.cardElement.dataset.timestamp, 10 ) );
	}
}

class LiquipediaMatchTicker {
	static async init() {
		await mw.loader.using( 'user.options' );
		document.querySelectorAll( '.match-ticker-carousel' ).forEach( ( tickerCarousel ) => {
			const cards = tickerCarousel.querySelectorAll( '.match-ticker-card' );
		} );
	}
}

liquipedia.matchticker = LiquipediaMatchTicker;
liquipedia.core.modules.push( 'matchticker' );
