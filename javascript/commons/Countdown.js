/*******************************************************************************
 * Template(s): Countdowns
 * Author(s): FO-nTTaX, Machunki
 ******************************************************************************/
liquipedia.countdown = {
	timerHiddenClass: 'timer--hidden',
	timeoutFunctions: null,
	timerObjectNodes: null,
	lastCountdownId: null,
	// Last HTML written to each countdown element, so unchanged ticks skip the DOM write
	renderedCountdowns: new WeakMap(),
	init: async function () {
		// Cancels last countdown loop if it exists to prevent multiple countdowns running at the same time
		if ( liquipedia.countdown.timeoutFunctions && liquipedia.countdown.lastCountdownId ) {
			liquipedia.countdown.timeoutFunctions.clear( liquipedia.countdown.lastCountdownId );
		}

		liquipedia.countdown.timerObjectNodes = document.querySelectorAll( '.timer-object' );
		if ( liquipedia.countdown.timerObjectNodes.length > 0 ) {
			await mw.loader.using( 'user.options' );
			liquipedia.countdown.timerObjectNodes.forEach( ( timerObjectNode ) => {
				const dateObject = liquipedia.countdown.parseTimerObjectNodeToDateObj( timerObjectNode );
				const format = timerObjectNode.dataset.format || 'full';
				let dateChild;
				if ( timerObjectNode.firstChild instanceof HTMLSpanElement ) {
					dateChild = timerObjectNode.firstChild;
				} else {
					dateChild = document.createElement( 'span' );
					if (
						mw.user.options.get( 'teamliquidintegration-disable-countdown-timezone-adjust' ) ||
						typeof dateObject !== 'object'
					) {
						dateChild.innerHTML = timerObjectNode.innerHTML;
					} else {
						dateChild.innerHTML = liquipedia.countdown.getCorrectTimeZoneString( dateObject, format );
					}
					dateChild.classList.add( 'timer-object-date' );
				}
				timerObjectNode.innerHTML = '';
				timerObjectNode.appendChild( dateChild );
				let separatorChild;
				if ( timerObjectNode.dataset.separator !== undefined ) {
					separatorChild = document.createElement( 'span' );
					separatorChild.textContent = timerObjectNode.dataset.separator;
				} else {
					separatorChild = document.createElement( 'br' );
				}
				separatorChild.classList.add( 'timer-object-separator' );
				timerObjectNode.appendChild( separatorChild );
				const countdownChild = document.createElement( 'span' );
				countdownChild.classList.add( 'timer-object-countdown' );
				timerObjectNode.appendChild( countdownChild );
			} );

			await liquipedia.countdown.setupCountdownsIfSwitchToggleExists();

			// Only run when the window is actually in the front,
			// not in background tabs (on browsers that support it)
			const moduleRequire = await mw.loader.using( 'mediawiki.visibleTimeout' );
			liquipedia.countdown.timeoutFunctions = moduleRequire( 'mediawiki.visibleTimeout' );
			liquipedia.countdown.runCountdown();
		}
	},
	setupCountdownsIfSwitchToggleExists: async function () {
		const switchToggleGroup = await liquipedia.switchButtons.getSwitchGroup( 'countdown' );
		if ( !switchToggleGroup || switchToggleGroup.type !== 'toggle' || switchToggleGroup.value === null ) {
			return;
		}

		// Default state
		liquipedia.countdown.toggleCountdowns( switchToggleGroup.value );

		// Reacting state switch
		switchToggleGroup.nodes.forEach( ( switchNode ) => {
			switchNode.addEventListener( liquipedia.switchButtons.triggerEventName, ( event ) => {
				liquipedia.countdown.toggleCountdowns( event.detail.data.value );
			} );
		} );
	},
	toggleCountdowns: function ( isCountdownToggled ) {
		// Get all countdown toggle containers, if no container exists fall back to the body
		let containers = document.querySelectorAll( '[data-switch-group-container="countdown"]' );
		if ( containers.length === 0 ) {
			containers = document.querySelectorAll( 'body' );
		}
		containers.forEach( ( container ) => {
			// Find countdown nodes live so we don't run into issues with injected timer nodes
			const timerObjectNodes = container.querySelectorAll( '.timer-object' );
			timerObjectNodes.forEach( ( timerObjectNode ) => {
				const dateElement = timerObjectNode.querySelector( '.timer-object-date' );
				const countdownElement = timerObjectNode.querySelector( '.timer-object-countdown' );
				if ( dateElement ) {
					dateElement.classList.toggle( this.timerHiddenClass, isCountdownToggled );
				}
				if ( countdownElement ) {
					countdownElement.classList.toggle( this.timerHiddenClass, !isCountdownToggled );
				}
			} );
		} );
	},
	parseTimerObjectNodeToDateObj: function ( timerObjectNode ) {
		if ( timerObjectNode.dataset.timestamp === 'error' ) {
			return false;
		}
		return new Date( 1000 * parseInt( timerObjectNode.dataset.timestamp, 10 ) );
	},
	runCountdown: function () {
		liquipedia.countdown.timerObjectNodes.forEach( ( timerObjectNode ) => {
			liquipedia.countdown.setCountdownString( timerObjectNode );
		} );

		liquipedia.countdown.lastCountdownId = liquipedia.countdown.timeoutFunctions.set(
			liquipedia.countdown.runCountdown,
			1000
		);
	},
	setCountdownString: function ( timerObjectNode ) {
		const countdownElem = timerObjectNode.querySelector( '.timer-object-countdown' );
		let datestr = '';

		if ( timerObjectNode.dataset.timestamp !== 'error' ) {
			const { text, className } = this.getCountdownStringAndClassName( timerObjectNode );
			datestr = text;

			if ( className !== '' ) {
				countdownElem.classList.add( className );
			}
		}

		let html = `<span class="timer-object-countdown-time">${ datestr }</span>`;
		if ( datestr.length > 0 && timerObjectNode.dataset.hasstreams === 'true' ) {
			html += ' - ';
		}
		if ( this.renderedCountdowns.get( countdownElem ) !== html ) {
			countdownElem.innerHTML = html;
			this.renderedCountdowns.set( countdownElem, html );
		}
	},
	getCountdownStringAndClassName: function ( timerObjectNode ) {
		const differenceInSeconds =
			Math.floor( parseInt( timerObjectNode.dataset.timestamp, 10 ) - ( Date.now() / 1000 ) );

		if ( differenceInSeconds > 0 ) {
			return {
				text: this.formatTimeDifference( differenceInSeconds ),
				className: ''
			};
		}

		if ( differenceInSeconds <= -43200 || timerObjectNode.dataset.finished === 'finished' ) {
			return {
				text: '',
				className: ''
			};
		}

		return {
			text: timerObjectNode.dataset.countdownEndText ?? 'LIVE',
			className: 'timer-object-countdown-live'
		};
	},
	formatTimeDifference: function ( differenceInSeconds ) {
		const weeks = Math.floor( differenceInSeconds / 604800 );
		const days = Math.floor( ( differenceInSeconds % 604800 ) / 86400 );
		const hours = Math.floor( ( differenceInSeconds % 86400 ) / 3600 );
		const minutes = Math.floor( ( differenceInSeconds % 3600 ) / 60 );
		const seconds = Math.floor( differenceInSeconds % 60 );

		if ( differenceInSeconds >= 604800 ) {
			return `${ weeks }w ${ days }d`;
		} else if ( differenceInSeconds >= 86400 ) {
			return `${ days }d ${ hours }h ${ minutes }m`;
		} else if ( differenceInSeconds >= 3600 ) {
			return `${ hours }h ${ minutes }m ${ seconds }s`;
		} else if ( differenceInSeconds >= 60 ) {
			return `${ minutes }m ${ seconds }s`;
		} else {
			return `${ seconds }s`;
		}
	},
	timeZoneAbbr: new Map( [
		[ 'Acre Time', 'ACT' ],
		[ 'Afghanistan Time', 'AFT' ],
		[ 'Alaska Daylight Time', 'AKDT' ],
		[ 'Alaska Standard Time', 'AKST' ],
		[ 'Alberta Time', 'ABT' ],
		[ 'Amazon Time', 'AMT' ],
		[ 'Arabic Standard Time', 'AST' ],
		[ 'Argentina Standard Time', 'ART' ],
		[ 'Armenia Time', 'AMT' ],
		[ 'Atlantic Daylight Time', 'ADT' ],
		[ 'Atlantic Standard Time', 'AST' ],
		[ 'Australian Central Daylight Time', 'ACDT' ],
		[ 'Australian Central Standard Time', 'ACST' ],
		[ 'Australian Central Western Standard Time', 'ACWST' ],
		[ 'Australian Eastern Daylight Time', 'AEDT' ],
		[ 'Australian Eastern Standard Time', 'AEST' ],
		[ 'Australian Western Standard Time', 'AWST' ],
		[ 'Aqtobe Time', 'AQTT' ],
		[ 'Azerbaijan Summer Time', 'AZST' ],
		[ 'Azerbaijan Time', 'AZT' ],
		[ 'Azores Summer Time', 'AZOST' ],
		[ 'Azores Standard Time', '' ],
		[ 'Bangladesh Standard Time', 'BST' ],
		[ 'Bhutan Time', 'BTT' ],
		[ 'Bolivia Time', 'BOT' ],
		[ 'Brasilia Standard Time', 'BRT' ],
		[ 'Brasilia Summer Time', 'BRST' ],
		[ 'British Summer Time', 'BST' ],
		[ 'Brunei Darussalam Time', 'BNT' ],
		[ 'Cape Verde Standard Time', 'CVT' ],
		[ 'Center Indonesia Time', 'WITA' ],
		[ 'Central Africa Time', 'CAT' ],
		[ 'Central Daylight Time', 'CDT' ],
		[ 'Central European Summer Time', 'CEST' ],
		[ 'Central European Standard Time', 'CET' ],
		[ 'Central Standard Time', 'CT' ],
		[ 'Chatham Standard Time', 'CHAST' ],
		[ 'Chile Standard Time', 'CLT' ],
		[ 'China Standard Time', 'CST' ],
		[ 'Colombia Standard Time', 'COT' ],
		[ 'Cuba Daylight Time', 'CDT' ],
		[ 'Cuba Standard Time', 'CST' ],
		[ 'East Africa Time', 'EAT' ],
		[ 'East Kazakhstan Time', 'ALMT' ],
		[ 'Easter Island Standard Time', 'EAST' ],
		[ 'Eastern Daylight Time', 'EDT' ],
		[ 'Eastern European Standard Time', 'EET' ],
		[ 'Eastern European Summer Time', 'EEST' ],
		[ 'Eastern Standard Time', 'EST' ],
		[ 'Ecuador Time', 'ECT' ],
		[ 'Fiji Standard Time', 'FJST' ],
		[ 'French Guiana Time', 'GFT' ],
		[ 'Georgia Standard Time', 'GET' ],
		[ 'Greenwich Mean Time', 'GMT' ],
		[ 'Gulf Standard Time', 'GST' ],
		[ 'Guyana Time', 'GYT' ],
		[ 'Hawaii-Aleutian Daylight Time', 'HDT' ],
		[ 'Hawaii-Aleutian Standard Time', 'HST' ],
		[ 'Hong Kong Standard Time', 'HKT' ],
		[ 'Hovd Standard Time', 'HOVST' ],
		[ 'India Standard Time', 'IST' ],
		[ 'Indochina Time', 'ICT' ],
		[ 'Iran Daylight Time', 'IRDT' ],
		[ 'Iran Standard Time', 'IRST' ],
		[ 'Irkutsk Standard Time', 'IRKST' ],
		[ 'Israel Daylight Time', 'IDT' ],
		[ 'Israel Standard Time', 'IST' ],
		[ 'Japan Standard Time', 'JST' ],
		[ 'Korean Standard Time', 'KST' ],
		[ 'Krasnoyarsk Standard Time', 'KRAST' ],
		[ 'Line Islands Time', 'LINT' ],
		[ 'Lord Howe Standard Time', 'LHST' ],
		[ 'Magadan Standard Time', 'MAGT' ],
		[ 'Malaysia Time', 'MYT' ],
		[ 'Marquesas Time', 'MART' ],
		[ 'Mauritius Standard Time', 'MUT' ],
		[ 'Mexican Pacific Standard Time', 'PST' ],
		[ 'Moscow Standard Time', 'MSK' ],
		[ 'Mountain Daylight Time', 'MDT' ],
		[ 'Mountain Standard Time', 'MST' ],
		[ 'Myanmar Time', 'MMT' ],
		[ 'Nepal Time', 'NPT' ],
		[ 'New Zealand Daylight Time', 'NZDT' ],
		[ 'New Zealand Standard Time', 'NZST' ],
		[ 'Newfoundland Daylight Time', 'NDT' ],
		[ 'Newfoundland Standard Time', 'NST' ],
		[ 'Norfolk Island Time', 'NFT' ],
		[ 'Novosibirsk Standard Time', 'NOVST' ],
		[ 'Omsk Standard Time', 'OMST' ],
		[ 'Pacific Daylight Time', 'PDT' ],
		[ 'Pacific Standard Time', 'PST' ],
		[ 'Pacific Time', 'PCT' ],
		[ 'Pakistan Standard Time', 'PKT' ],
		[ 'Papua New Guinea Time', 'PGT' ],
		[ 'Paraguay Standard Time', 'PYST' ],
		[ 'Petropavlovsk-Kamchatski Standard Time', 'PETT' ],
		[ 'Philippine Standard Time', 'PHT' ],
		[ 'Pyongyang Time', 'PYT' ],
		[ 'Sakhalin Standard Time', 'SAKT' ],
		[ 'Samara Standard Time', 'SAMT' ],
		[ 'Singapore Standard Time', 'SGT' ],
		[ 'Solomon Islands Time', 'SBT' ],
		[ 'South Africa Standard Time', 'SAST' ],
		[ 'St. Pierre & Miquelon Daylight Time', 'PMDT' ],
		[ 'St. Pierre & Miquelon Standard Time', 'PMST' ],
		[ 'Taipei Standard Time', 'TST' ],
		[ 'Tonga Standard Time', 'TOT' ],
		[ 'Turkey Time', 'TRT' ],
		[ 'Ulaanbaatar Standard Time', 'ULAST' ],
		[ 'Uruguay Standard Time', 'UYT' ],
		[ 'Uzbekistan Standard Time', 'UZT' ],
		[ 'Venezuelan Standard Time', 'VET' ],
		[ 'Vladivostok Standard Time', 'VLAT' ],
		[ 'West Africa Standard Time', 'WAST' ],
		[ 'West Greenland Summer Time', 'WGST' ],
		[ 'West Greenland Standard Time', 'WGT' ],
		[ 'Western European Summer Time', 'WEST' ],
		[ 'Western Indonesia Time', 'WIB' ],
		[ 'Yakutsk Standard Time', 'YAKT' ],
		[ 'Yekaterinburg Standard Time', 'YEKT' ]
	] ),
	// Month numbers are 0-based (as returned by Date#getMonth). The date is pinned to UTC so the
	// user's time zone can never shift it into an adjacent month.
	getMonthNameFromMonthNumber: function ( newFutureMonth ) {
		return new Intl.DateTimeFormat( 'en', { month: 'long', timeZone: 'UTC' } )
			.format( Date.UTC( 2000, newFutureMonth, 1 ) );
	},
	getMonthNameShortFromMonthNumber: function ( newFutureMonth ) {
		return new Intl.DateTimeFormat( 'en', { month: 'short', timeZone: 'UTC' } )
			.format( Date.UTC( 2000, newFutureMonth, 1 ) );
	},
	getTimeZoneNameLong: function ( dateObject ) {
		return new Intl.DateTimeFormat( 'en', { timeZoneName: 'long' } )
			.formatToParts( dateObject )
			.find( ( part ) => part.type === 'timeZoneName' )?.value;
	},
	getCorrectTimeZoneString: function ( dateObject, format = 'full' ) {
		const userTime = {
			dateObjectYear: dateObject.getFullYear(),
			dateObjectMonth: dateObject.getMonth(),
			dateObjectDay: dateObject.getDate(),
			dateObjectHours: dateObject.getHours(),
			dateObjectMinutes: dateObject.getMinutes(),

			timeZoneName: liquipedia.countdown.getTimeZoneNameLong( dateObject )
		};

		// getTimezoneOffset() is UTC minus local time in minutes (e.g. -330 for UTC+5:30), so negate it.
		// Hours and minutes are derived from the total offset to keep half/quarter-hour zones correct.
		const offsetInMinutes = -dateObject.getTimezoneOffset();
		const absoluteOffsetInMinutes = Math.abs( offsetInMinutes );
		const offsetSign = offsetInMinutes < 0 ? '-' : '+';
		const offsetHoursWithSign = offsetSign + Math.floor( absoluteOffsetInMinutes / 60 );
		const offsetMinutesStr = String( absoluteOffsetInMinutes % 60 ).padStart( 2, '0' );
		const offsetMinutesAsString = absoluteOffsetInMinutes % 60 !== 0 ? ':' + offsetMinutesStr : '';

		let finalTimeZoneName;
		let finalTimeZoneAbbr;
		if ( !liquipedia.countdown.timeZoneAbbr.has( userTime.timeZoneName ) ) {
			finalTimeZoneName = 'UTC' + offsetHoursWithSign + ':' + offsetMinutesStr;
			finalTimeZoneAbbr = 'UTC' + offsetHoursWithSign + offsetMinutesAsString;
		} else {
			finalTimeZoneAbbr = liquipedia.countdown.timeZoneAbbr.get( userTime.timeZoneName );
			finalTimeZoneName = userTime.timeZoneName + ' (UTC' + offsetHoursWithSign + offsetMinutesAsString + ')';
		}

		const hours = String( userTime.dateObjectHours ).padStart( 2, '0' );
		const minutes = String( userTime.dateObjectMinutes ).padStart( 2, '0' );
		const time = `${ hours }:${ minutes }`;

		let strLocalTime1;
		if ( format === 'compact' ) {
			const monthName = liquipedia.countdown.getMonthNameShortFromMonthNumber( userTime.dateObjectMonth );
			if ( new Date().getFullYear() === userTime.dateObjectYear ) {
				strLocalTime1 = `${ monthName } ${ userTime.dateObjectDay } - ${ time }`;
			} else {
				strLocalTime1 = `${ monthName } ${ userTime.dateObjectDay }, ${ userTime.dateObjectYear } - ${ time }`;
			}
		} else {
			const monthName = liquipedia.countdown.getMonthNameFromMonthNumber( userTime.dateObjectMonth );
			strLocalTime1 = `${ monthName } ${ userTime.dateObjectDay }, ${ userTime.dateObjectYear } - ${ time }`;
		}

		const strLocalTime2 = ` <abbr data-tz="${ offsetHoursWithSign }:${ offsetMinutesStr }"`;
		const strLocalTime3 = ` title="${ finalTimeZoneName }">${ finalTimeZoneAbbr }</abbr>`;
		const dateObjectString = strLocalTime1 + strLocalTime2 + strLocalTime3;
		return dateObjectString;
	}
};
liquipedia.core.modules.push( 'countdown' );
