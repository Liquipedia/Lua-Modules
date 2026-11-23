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
	 * @return {boolean}
	 */
	hasStarted( now ) {
		return this.parsedDate < now;
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
	static get LIVE_GROUP_KEY() {
		return 'live';
	}

	static async init() {
		await mw.loader.using( 'user.options' );
		const now = new Date();
		document.querySelectorAll( '.match-ticker-filterable-container .match-ticker-carousel' ).forEach( ( tickerCarousel ) => {
			// Matches in the upcoming list are not finished, so the ones that have already started are ongoing
			const tickerType = tickerCarousel.closest( '[data-match-ticker-type]' )?.dataset.matchTickerType;
			const isUpcoming = tickerType === 'upcoming';
			/** @type {HTMLElement[]} */
			const groupedDisplay = [];
			const cards = Array.from(
				tickerCarousel.querySelectorAll( '.match-ticker-card' ),
				( element ) => new LiquipediaMatchTickerCard( element )
			);

			if ( cards.length === 0 ) {
				return;
			}

			const cardGroups = Map.groupBy( cards, ( card ) => isUpcoming && card.hasStarted( now ) ?
				LiquipediaMatchTicker.LIVE_GROUP_KEY :
				card.toISODateString()
			);

			for ( const [ groupKey, cardGroup ] of cardGroups ) {
				const cardGroupElement = document.createElement( 'div' );
				cardGroupElement.classList.add( 'match-ticker-card-group' );
				cardGroupElement.style.setProperty( '--match-ticker-group-columns', cardGroup.length );
				const title = LiquipediaMatchTicker.createGroupHeader( groupKey, cardGroup[ 0 ], now );
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

	/**
	 * @param {string} groupKey
	 * @param {LiquipediaMatchTickerCard} firstCard
	 * @param {Date} now
	 * @return {HTMLElement}
	 */
	static createGroupHeader( groupKey, firstCard, now ) {
		const header = document.createElement( 'div' );
		header.classList.add( 'match-ticker-card-group__header' );
		const label = document.createElement( 'span' );
		label.classList.add( 'match-ticker-card-group__label' );
		header.append( label );

		if ( groupKey === LiquipediaMatchTicker.LIVE_GROUP_KEY ) {
			header.classList.add( 'match-ticker-card-group__header--live' );
			label.textContent = 'Live now';
			return header;
		}

		label.textContent = firstCard.getRelativeDayLabel( now );
		const dateText = document.createElement( 'time' );
		dateText.classList.add( 'match-ticker-card-group__date' );
		dateText.dateTime = groupKey;
		dateText.textContent = firstCard.format( { month: 'short', day: 'numeric', year: 'numeric' } );
		header.append( dateText );
		return header;
	}
}

liquipedia.matchticker = LiquipediaMatchTicker;
liquipedia.core.modules.push( 'matchticker' );
