/*******************************************************************************
 * Template(s): Countdowns
 * Author(s): FO-nTTaX, Machunki
 ******************************************************************************/
liquipedia.countdown = {
	init: function() {
		liquipedia.countdown.timerObjectNodes = document.querySelectorAll( '.timer-object' );
		if ( liquipedia.countdown.timerObjectNodes.length > 0 ) {
			mw.loader.using( 'user.options', function() {
				liquipedia.countdown.timerObjectNodes.forEach( function( timerObjectNode ) {
					const dateObject = liquipedia.countdown.parseTimerObjectNodeToDateObj( timerObjectNode );
					const dateChild = document.createElement( 'span' );
					if ( typeof dateObject === 'object' ) {
						const disableTimeZoneAdjust = mw.user.options.get( 'teamliquidintegration-disable-countdown-timezone-adjust' ) === '1' || mw.user.options.get( 'teamliquidintegration-disable-countdown-timezone-adjust' ) === 1;
						if ( disableTimeZoneAdjust ) {
							dateChild.innerHTML = timerObjectNode.innerHTML;
						} else {
							dateChild.innerHTML = liquipedia.countdown.getCorrectTimeZoneString( dateObject );
						}
					} else {
						dateChild.innerHTML = timerObjectNode.innerHTML;
					}
					dateChild.classList.add( 'timer-object-date' );
					timerObjectNode.innerHTML = '';
					timerObjectNode.appendChild( dateChild );
					let separatorChild;
					if ( typeof timerObjectNode.dataset.separator !== 'undefined' ) {
						separatorChild = document.createElement( 'span' );
						separatorChild.innerText = timerObjectNode.dataset.separator;
						separatorChild.classList.add( 'timer-object-separator' );
					} else {
						separatorChild = document.createElement( 'br' );
						separatorChild.classList.add( 'timer-object-separator' );
					}
					timerObjectNode.appendChild( separatorChild );
					const countdownChild = document.createElement( 'span' );
					countdownChild.classList.add( 'timer-object-countdown' );
					timerObjectNode.appendChild( countdownChild );
				} );
				// Only run when the window is actually in the front, not in background tabs (on browsers that support it)
				mw.loader.using( 'mediawiki.visibleTimeout' ).then( function( require ) {
					liquipedia.countdown.timeoutFunctions = require( 'mediawiki.visibleTimeout' );
					liquipedia.countdown.runCountdown();
				} );
			} );
		}
	},
	timeoutFunctions: null,
	timerObjectNodes: null,
	parseTimerObjectNodeToDateObj: function( timerObjectNode ) {
		if ( timerObjectNode.dataset.timestamp === 'error' ) {
			return false;
		}
		return new Date( 1000 * parseInt( timerObjectNode.dataset.timestamp ) );
	},
	runCountdown: function() {
		liquipedia.countdown.timerObjectNodes.forEach( function( timerObjectNode ) {
			liquipedia.countdown.setCountdownString( timerObjectNode );
		} );
		liquipedia.countdown.timeoutFunctions.set( liquipedia.countdown.runCountdown, 1000 );
	},
	setCountdownString: function( timerObjectNode ) {
		const streamsarr = [ ];
		let datestr = '', live = 'LIVE!';
		if ( typeof timerObjectNode.dataset.countdownEndText !== 'undefined' ) {
			live = timerObjectNode.dataset.countdownEndText;
		}
		if ( timerObjectNode.dataset.timestamp !== 'error' ) {
			const differenceInSeconds = Math.floor( parseInt( timerObjectNode.dataset.timestamp ) - ( Date.now().valueOf() / 1000 ) );
			if ( differenceInSeconds <= 0 ) {
				if ( differenceInSeconds > -43200 && timerObjectNode.dataset.finished !== 'finished' ) {
					datestr = '<span class="timer-object-countdown-live">' + live + '</span>';
				}
			} else {
				let differenceInSecondsMath = differenceInSeconds;
				const weeks = Math.floor( differenceInSecondsMath / 604800 );
				differenceInSecondsMath = differenceInSecondsMath % 604800;
				const days = Math.floor( differenceInSecondsMath / 86400 );
				differenceInSecondsMath = differenceInSecondsMath % 86400;
				const hours = Math.floor( differenceInSecondsMath / 3600 );
				differenceInSecondsMath = differenceInSecondsMath % 3600;
				const minutes = Math.floor( differenceInSecondsMath / 60 );
				const seconds = Math.floor( differenceInSecondsMath % 60 );
				if ( differenceInSeconds >= 604800 ) {
					datestr = weeks + 'w ' + days + 'd';
				} else if ( differenceInSeconds >= 86400 ) {
					datestr = days + 'd ' + hours + 'h ' + minutes + 'm';
				} else if ( differenceInSeconds >= 3600 ) {
					datestr = hours + 'h ' + minutes + 'm ' + seconds + 's';
				} else if ( differenceInSeconds >= 60 ) {
					datestr = minutes + 'm ' + seconds + 's';
				} else {
					datestr = seconds + 's';
				}
			}
		} else {
			datestr = ''; // DATE ERROR!
		}
		const streamKeys = {
			Twitch: 'twitch',
			Youtube: 'youtube',
			Afreecatv: 'freeca',
			Bilibili: 'bilibili',
			Booyah: 'booyah',
			Cc163: 'cc',
			Dailymotion: 'dailymotion',
			Douyu: 'douyu',
			Facebook: 'facebook',
			Huomao: 'huomaotv',
			Huya: 'huyatv',
			Loco: 'stream',
			Mildom: 'mildom',
			Nimo: 'nimotv',
			Trovo: 'trovo'
		};
		for ( const dataSetName in streamKeys ) {
			const icon = streamKeys[ dataSetName ];
			const platform = dataSetName.toLowerCase();
			if ( timerObjectNode.dataset[ 'stream' + dataSetName ] ) {
				streamsarr.push( '<a href="' + mw.config.get( 'wgScriptPath' ) + '/Special:Stream/' + platform + '/' + liquipedia.countdown.getStreamName( timerObjectNode.dataset[ 'stream' + dataSetName ] ) + '"><i class="lp-icon lp-icon-21 lp-' + icon + '"></i></a>' );
				let i = 2;
				while ( timerObjectNode.dataset[ 'stream' + dataSetName + i ] ) {
					streamsarr.push( '<a href="' + mw.config.get( 'wgScriptPath' ) + '/Special:Stream/' + platform + '/' + liquipedia.countdown.getStreamName( timerObjectNode.dataset[ 'stream' + dataSetName + i ] ) + '"><i class="lp-icon lp-icon-21 lp-' + icon + '"></i></a>' );
					i++;
				}
			}
		}
		if ( timerObjectNode.dataset.streamTl ) {
			streamsarr.push( '<a href="https://tl.net/video/streams/' + timerObjectNode.dataset.streamTl + '" target="_blank"><i class="lp-icon lp-icon-21 lp-stream"></i></a>' );
			let tlStreamIndex = 2;
			while ( timerObjectNode.dataset[ 'streamTl' + tlStreamIndex ] ) {
				streamsarr.push( '<a href="https://tl.net/video/streams/' + timerObjectNode.dataset[ 'streamTl' + tlStreamIndex ] + '" target="_blank"><i class="lp-icon lp-icon-21 lp-stream"></i></a>' );
				tlStreamIndex++;
			}
		}
		let html = '<span class="timer-object-countdown-time">' + datestr + '</span>';
		if ( datestr.length > 0 && streamsarr.length > 0 ) {
			html += ' - ';
		}
		if ( timerObjectNode.dataset.finished !== 'finished' ) {
			html += streamsarr.join( ' ' );
		}
		timerObjectNode.querySelector( '.timer-object-countdown' ).innerHTML = html;
	},
	getStreamName: function( url ) {
		return url.replace( /\s/g, '_' );
	},
	timeZoneAbbr: new Map( [
		[ 'Acre Time', 'ACT' ],
		[ 'Afghanistan Time', 'AFT' ],
		[ 'Alaska Daylight Time', 'AKDT' ],
		[ 'Alaska Standard Time', 'AKST' ],
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
		[ 'Newfoundland Standard Time', 'NDT' ],
		[ 'Norfolk Island Time', 'NFT' ],
		[ 'Novosibirsk Standard Time', 'NOVST' ],
		[ 'Omsk Standard Time', 'OMST' ],
		[ 'Pacific Daylight Time', 'PDT' ],
		[ 'Pacific Standard Time', 'PST' ],
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
	getMonthNameFromMonthNumber: function( newFutureMonth ) {
		const monthNames = [ 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December' ];
		return monthNames[ newFutureMonth ];
	},
	getTimeZoneNameLong: function( dateObject ) {
		let date;
		let result;
		const dateTimeFormat = new Intl.DateTimeFormat( 'en', { timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone, timeZoneName: 'long' } );
		if ( typeof Intl.DateTimeFormat.prototype.formatToParts === 'function' ) {
			date = dateTimeFormat.formatToParts( dateObject );
			date.forEach( function( element ) {
				if ( element.type === 'timeZoneName' ) {
					result = element.value;
				}
			} );
		} else {
			date = dateTimeFormat.format( dateObject );
			if ( date.includes( ',' ) ) {
				result = date.split( ',' )[ 1 ].trim();
			} else {
				result = date.split( ' ' ).slice( 2 ).join( ' ' ).trim();
			}
		}
		return result;
	},
	getCorrectTimeZoneString: function( dateObject ) {
		const userTime = {
			localYear: dateObject.getFullYear(),
			localMonth: dateObject.getMonth(),
			localDay: dateObject.getDate(),
			localHours: dateObject.getHours(),
			localMinutes: dateObject.getMinutes(),

			utcYear: dateObject.getUTCFullYear(),
			utcMonth: dateObject.getUTCMonth(),
			utcDay: dateObject.getUTCDate(),
			utcHours: dateObject.getUTCHours(),
			utcMinutes: dateObject.getUTCMinutes(),

			dateObjectYear: dateObject.getFullYear(),
			dateObjectMonth: dateObject.getMonth(),
			dateObjectDay: dateObject.getDate(),
			dateObjectHours: dateObject.getHours(),
			dateObjectMinutes: dateObject.getMinutes(),

			timeZoneName: liquipedia.countdown.getTimeZoneNameLong( dateObject )
		};

		let calculatedOffsetHours = 0;
		const calculatedOffsetMinutes = ( userTime.localMinutes - userTime.utcMinutes );
		let offsetMinutesAsString = '';
		let offsetHoursWithSign = '+0';
		let finalTimeZoneAbbr = '';

		if ( userTime.localDay === userTime.utcDay ) {
			calculatedOffsetHours = userTime.localHours - userTime.utcHours;
		} else if ( userTime.localMonth === userTime.utcMonth ) {
			// Month is same, so no problems comparing dates
			if ( userTime.localDay > userTime.utcDay ) {
				// +24 Hours because of the next day
				calculatedOffsetHours = -( userTime.utcHours ) + userTime.localHours + 24;
			} else if ( userTime.localDay < userTime.utcDay ) {
				// -24 Hours because of the day before
				calculatedOffsetHours = -( userTime.utcHours ) + userTime.localHours - 24;
			}
		} else if ( ( userTime.localMonth > userTime.utcMonth && userTime.localYear === userTime.utcYear ) || userTime.localYear > userTime.utcYear ) {
			// +24 Hours because of the next day (in next month or year)
			calculatedOffsetHours = -( userTime.utcHours ) + userTime.localHours + 24;
		} else if ( ( userTime.localMonth < userTime.utcMonth && userTime.localYear === userTime.utcYear ) || userTime.localYear < userTime.utcYear ) {
			// -24 Hours because of the day before (in previous month or year)
			calculatedOffsetHours = -( userTime.utcHours ) + userTime.localHours - 24;
		}

		const calculatedOffsetInMinutes = ( calculatedOffsetHours * 60 ) + calculatedOffsetMinutes;

		if ( calculatedOffsetHours > 0 ) {
			if ( calculatedOffsetInMinutes % 60 !== 0 ) {
				offsetMinutesAsString = ':' + Math.abs( calculatedOffsetMinutes );
			}
		} else if ( calculatedOffsetHours < 0 ) {
			if ( calculatedOffsetInMinutes % 60 !== 0 ) {
				offsetMinutesAsString = ':' + Math.abs( calculatedOffsetMinutes );
			}
		}

		let finalTimeZoneName = 'UTC' + offsetHoursWithSign + offsetMinutesAsString;

		if ( calculatedOffsetHours < 0 ) {
			offsetHoursWithSign = '-' + Math.abs( calculatedOffsetHours );
		} else if ( calculatedOffsetHours > 0 ) {
			offsetHoursWithSign = '+' + Math.abs( calculatedOffsetHours );
		}

		if ( !liquipedia.countdown.timeZoneAbbr.has( userTime.timeZoneName ) ) {
			// ('0' + calculatedOffsetMinutes).slice(-2), because of the leading zero
			finalTimeZoneName = 'UTC' + offsetHoursWithSign + ':' + ( '0' + calculatedOffsetMinutes ).slice( -2 );
			finalTimeZoneAbbr = 'UTC' + offsetHoursWithSign + offsetMinutesAsString;
		} else {
			finalTimeZoneAbbr = liquipedia.countdown.timeZoneAbbr.get( userTime.timeZoneName );
			finalTimeZoneName = userTime.timeZoneName + ' (UTC' + offsetHoursWithSign + offsetMinutesAsString + ')';
		}

		const strLocalTime1 = ( liquipedia.countdown.getMonthNameFromMonthNumber( userTime.dateObjectMonth ) ) + ' ' + userTime.dateObjectDay + ', ' + userTime.dateObjectYear + ' - ' + ( '0' + userTime.dateObjectHours ).slice( -2 ) + ':' + ( '0' + userTime.dateObjectMinutes ).slice( -2 );
		const strLocalTime2 = ' <abbr data-tz="' + offsetHoursWithSign + ':' + ( '0' + calculatedOffsetMinutes ).slice( -2 ) + '"';
		const strLocalTime3 = ' title="' + finalTimeZoneName + '">' + finalTimeZoneAbbr + '</abbr>';
		const dateObjectString = strLocalTime1 + strLocalTime2 + strLocalTime3;
		return dateObjectString;
	}
};
liquipedia.core.modules.push( 'countdown' );
