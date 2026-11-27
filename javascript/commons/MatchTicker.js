class LiquipediaMatchTickerCard {
	/**
	 * Offset in milliseconds of the timezone dates are shown in, or null for the local timezone
	 *
	 * @type {number?}
	 */
	#timezoneOffset;

	/**
	 * @param {HTMLElement} cardElement
	 * @param {boolean} useMatchTimezone whether dates are shown in the timezone of the match instead of the local one
	 */
	constructor( cardElement, useMatchTimezone ) {
		this.cardElement = cardElement;
		this.#timezoneOffset = useMatchTimezone ?
			1000 * ( parseInt( this.cardElement.dataset.matchTimezoneOffset, 10 ) || 0 ) :
			null;
		this.parsedDate = new Date( 1000 * parseInt( this.cardElement.dataset.matchTimestamp, 10 ) );
	}

	/**
	 * Shift the given moment so that its UTC fields read as the wall-clock time in the timezone of the match
	 *
	 * @param {Date} date
	 * @return {Date}
	 */
	#toMatchTimezone( date ) {
		return new Date( date.getTime() + this.#timezoneOffset );
	}

	/**
	 * Calendar date of the given moment, in the timezone of the match or the local timezone
	 *
	 * @param {Date} date
	 * @return {{year: number, month: number, day: number}}
	 */
	#getCalendarDate( date ) {
		if ( this.#timezoneOffset !== null ) {
			const shifted = this.#toMatchTimezone( date );
			return { year: shifted.getUTCFullYear(), month: shifted.getUTCMonth(), day: shifted.getUTCDate() };
		}
		return { year: date.getFullYear(), month: date.getMonth(), day: date.getDate() };
	}

	toISODateString() {
		const { year, month, day } = this.#getCalendarDate( this.parsedDate );
		return [
			String( year ).padStart( 4, '0' ),
			String( month + 1 ).padStart( 2, '0' ),
			String( day ).padStart( 2, '0' )
		].join( '-' );
	}

	/**
	 * @param {Intl.DateTimeFormatOptions} options
	 * @return {string}
	 */
	formatDate( options ) {
		if ( this.#timezoneOffset === null ) {
			return this.parsedDate.toLocaleDateString( 'en-US', options );
		}
		const shifted = this.#toMatchTimezone( this.parsedDate );
		return shifted.toLocaleDateString( 'en-US', { ...options, timeZone: 'UTC' } );
	}

	/**
	 * Number of calendar days from today to the match day
	 *
	 * @param {Date} now
	 * @return {number}
	 */
	getDayOffset( now ) {
		const toDayValue = ( { year, month, day } ) => Date.UTC( year, month, day );
		const today = toDayValue( this.#getCalendarDate( now ) );
		const matchDay = toDayValue( this.#getCalendarDate( this.parsedDate ) );
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
				return this.formatDate( { weekday: 'long' } );
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
		// With timezone adjustment disabled, countdowns keep showing the date in the timezone of the match
		const useMatchTimezone = Boolean(
			mw.user.options.get( 'teamliquidintegration-disable-countdown-timezone-adjust' )
		);
		document.querySelectorAll( [
			'.match-ticker-filterable-container .match-ticker-carousel',
			'.match-ticker-horizontal-container .match-ticker-carousel'
		].join( ',' ) ).forEach( ( tickerCarousel ) => {
			// Matches in the upcoming list are not finished, so the ones that have already started are ongoing
			const tickerType = tickerCarousel.closest( '[data-match-ticker-type]' )?.dataset.matchTickerType;
			const isUpcoming = tickerType === 'upcoming';
			/** @type {HTMLElement[]} */
			const groupElements = [];
			const cards = Array.from(
				tickerCarousel.querySelectorAll( '.match-ticker-card' ),
				( element ) => new LiquipediaMatchTickerCard( element, useMatchTimezone )
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
				const header = LiquipediaMatchTicker.createGroupHeader( groupKey, cardGroup[ 0 ], now );
				const cardContainer = document.createElement( 'div' );
				cardContainer.classList.add( 'match-ticker-card-group__body' );

				cardGroupElement.append( header, cardContainer );

				for ( const card of cardGroup ) {
					// Move the carousel item, which carries the scroll snapping and width
					cardContainer.append( card.cardElement.closest( '.carousel-item' ) );
				}
				groupElements.push( cardGroupElement );
			}

			// Items without a match, like the link to all matches, stay after the groups
			const otherItems = Array.from( tickerCarousel.children )
				.filter( ( item ) => !item.querySelector( '.match-ticker-card' ) );
			tickerCarousel.replaceChildren( ...groupElements, ...otherItems );
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
		// The header spans the whole group, so its content is wrapped to stay in view while scrolling
		const title = document.createElement( 'div' );
		title.classList.add( 'match-ticker-card-group__title' );
		const label = document.createElement( 'span' );
		label.classList.add( 'match-ticker-card-group__label' );
		title.append( label );
		header.append( title );

		if ( groupKey === LiquipediaMatchTicker.LIVE_GROUP_KEY ) {
			header.classList.add( 'match-ticker-card-group__header--live' );
			label.textContent = 'Live now';
			return header;
		}

		label.textContent = firstCard.getRelativeDayLabel( now );
		const dateText = document.createElement( 'time' );
		dateText.classList.add( 'match-ticker-card-group__date' );
		dateText.dateTime = groupKey;
		dateText.textContent = firstCard.formatDate( { month: 'short', day: 'numeric', year: 'numeric' } );
		title.append( dateText );
		return header;
	}
}

liquipedia.matchticker = LiquipediaMatchTicker;
liquipedia.core.modules.push( 'matchticker' );
