class LiquipediaMatchTickerCard {
	/**
	 * @param {HTMLElement} cardElement
	 */
	constructor( cardElement ) {
		this.cardElement = cardElement;
		this.parsedDate = new Date( 1000 * parseInt( this.cardElement.dataset.matchTimestamp, 10 ) );
	}

	/**
	 * @return {boolean}
	 */
	#useUTC() {
		return mw.user.options.get( 'teamliquidintegration-disable-countdown-timezone-adjust' );
	}

	getYear() {
		if ( this.#useUTC() ) {
			return this.parsedDate.getUTCFullYear();
		}
		return this.parsedDate.getUTCFullYear();
	}

	getMonth() {
		if ( this.#useUTC() ) {
			return this.parsedDate.getUTCMonth();
		}
		return this.parsedDate.getMonth();
	}

	getDate() {
		if ( this.#useUTC() ) {
			return this.parsedDate.getUTCDate();
		}
		return this.parsedDate.getDate();
	}

	toISODateString() {
		return `${ String( this.getYear() ).padStart( 4, '0' ) }-${ String( this.getMonth() + 1 ).padStart( 2, '0' ) }-${ String( this.getDate() ).padStart( 4, '0' ) }`;
	}
}

class LiquipediaMatchTicker {
	static async init() {
		await mw.loader.using( 'user.options' );
		/** @type {HTMLElement[]} */
		const groupedDisplay = [];
		document.querySelectorAll( '.match-ticker-filterable-container .match-ticker-carousel' ).forEach( ( tickerCarousel ) => {
			const cards = Array.from(
				tickerCarousel.querySelectorAll( '.match-ticker-card' ),
				( element ) => new LiquipediaMatchTickerCard( element )
			);

			if ( cards.length === 0 ) {
				return;
			}

			const cardGroups = Map.groupBy( cards, ( card ) => card.toISODateString() );

			for ( const [ date, cardGroup ] of cardGroups ) {
				const cardGroupElement = document.createElement( 'div' );
				cardGroup.classList.add( '.match-ticker-card-group' );
				const title = document.createElement( 'div' );
				title.classList.add( '.match-ticker-card-header' );
				title.innerText = date;
				const cardContainer = document.createElement( 'div' );
				cardContainer.classList.add( '.match-ticker-card-header' );

				cardGroupElement.append( title, cardContainer );

				for ( const card of cardGroup ) {
					cardContainer.append( card.cardElement );
				}
				groupedDisplay.push( cardContainer );
			}

			tickerCarousel.replaceChildren( ...groupedDisplay );
		} );
	}
}

liquipedia.matchticker = LiquipediaMatchTicker;
liquipedia.core.modules.push( 'matchticker' );
