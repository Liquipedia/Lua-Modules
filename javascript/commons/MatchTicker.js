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
		return this.parsedDate.getFullYear();
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
		return `${ String( this.getYear() ).padStart( 4, '0' ) }-${ String( this.getMonth() + 1 ).padStart( 2, '0' ) }-${ String( this.getDate() ).padStart( 2, '0' ) }`;
	}

	/**
	 * @param {Intl.DateTimeFormatOptions} options
	 * @return {string}
	 */
	format( options ) {
		return this.parsedDate.toLocaleDateString( 'en-US', {
			...options,
			timeZone: this.#useUTC() ? 'UTC' : undefined
		} );
	}

	/**
	 * Number of calendar days from today to the match day, in the same timezone as the other getters
	 *
	 * @param {Date} now
	 * @return {number}
	 */
	getDayOffset( now ) {
		const today = this.#useUTC() ?
			Date.UTC( now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() ) :
			Date.UTC( now.getFullYear(), now.getMonth(), now.getDate() );
		const matchDay = Date.UTC( this.getYear(), this.getMonth(), this.getDate() );
		return Math.round( ( matchDay - today ) / 86400000 );
	}

	/**
	 * @param {Date} now
	 * @return {string}
	 */
	getRelativeDayLabel( now ) {
		switch ( this.getDayOffset( now ) ) {
			case -1:
				return 'Yesterday';
			case 0:
				return 'Today';
			case 1:
				return 'Tomorrow';
			default:
				return this.format( { weekday: 'long' } );
		}
	}
}

class LiquipediaMatchTicker {
	static async init() {
		await mw.loader.using( 'user.options' );
		const now = new Date();
		document.querySelectorAll( '.match-ticker-filterable-container .match-ticker-carousel' ).forEach( ( tickerCarousel ) => {
			/** @type {HTMLElement[]} */
			const groupedDisplay = [];
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
				cardGroupElement.classList.add( 'match-ticker-card-group' );
				cardGroupElement.style.setProperty( '--match-ticker-group-columns', cardGroup.length );
				const firstCard = cardGroup[ 0 ];
				const label = document.createElement( 'span' );
				label.classList.add( 'match-ticker-card-group__label' );
				label.textContent = firstCard.getRelativeDayLabel( now );
				const dateText = document.createElement( 'time' );
				dateText.classList.add( 'match-ticker-card-group__date' );
				dateText.dateTime = date;
				dateText.textContent = firstCard.format( { month: 'short', day: 'numeric', year: 'numeric' } );
				const title = document.createElement( 'div' );
				title.classList.add( 'match-ticker-card-group__header' );
				title.append( label, dateText );
				const cardContainer = document.createElement( 'div' );
				cardContainer.classList.add( 'match-ticker-card-group__body' );

				cardGroupElement.append( title, cardContainer );

				for ( const card of cardGroup ) {
					cardContainer.append( card.cardElement.parentElement );
				}
				groupedDisplay.push( cardGroupElement );
			}

			tickerCarousel.replaceChildren( ...groupedDisplay );
		} );
	}
}

liquipedia.matchticker = LiquipediaMatchTicker;
liquipedia.core.modules.push( 'matchticker' );
