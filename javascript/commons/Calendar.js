/*******************************************************************************
 Template(s): Calendar
 Author(s): FO-nTTaX, PhiLtheFisH
 *******************************************************************************/
liquipedia.calendar = {
	init: function() {
		document.querySelectorAll( '.calendar' ).forEach( function( calendar ) {
			const nowDate = new Date();
			const referenceDate = new Date(
				nowDate.getFullYear(),
				nowDate.getMonth(),
				nowDate.getDate(),
				0, 0, 0 );
			let difference,
				topOffset;

			// Constants
			const PX_PER_MINUTE = 0.5;
			const MINUTES_PER_DAY = 1440;
			const WIDTH_OF_COLUMN = 103;
			const HEIGHT_OF_CALENDAR = 719;
			const NUMBER_OF_DAYS = 7;

			// Label header row
			const DAYS = [ 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' ];
			const otherDayDate = new Date( nowDate );
			const calendarHeader = calendar.querySelector( '.calendar-header' );
			for ( let i = 0; i < NUMBER_OF_DAYS; i++ ) {
				const columnHeader = document.createElement( 'div' );
				columnHeader.classList.add( 'calendar-column' );
				columnHeader.innerHTML = DAYS[ ( nowDate.getDay() + i ) % 7 ] + ' ' + otherDayDate.getDate();
				calendarHeader.append( columnHeader );
				otherDayDate.setDate( otherDayDate.getDate() + 1 );
			}
			const clear = document.createElement( 'div' );
			clear.style.clear = 'both';
			calendarHeader.append( clear );

			const calendarEvents = calendar.querySelector( '.calendar-events' );

			// Add a red line that marks the current time
			difference = ( ( nowDate - referenceDate ) / 60000 );
			topOffset = difference * PX_PER_MINUTE;
			const redLine = document.createElement( 'div' );
			redLine.style.position = 'absolute';
			redLine.style.zIndex = 2;
			redLine.style.width = WIDTH_OF_COLUMN + 'px';
			redLine.style.borderBottom = '2px solid #ff0000';
			redLine.style.top = topOffset + 'px';
			calendarEvents.append( redLine );

			// Add events
			calendarEvents.querySelectorAll( '.calendar-event-item' ).forEach( function( calendarItem ) {
				let eventLength, leftOffset, abbr, ttz, el;

				el = calendarItem.querySelector( '.start-datetime' );
				abbr = el.querySelector( 'abbr' );
				ttz = abbr !== null ? abbr.title : false;
				const startDate = liquipedia.calendar.stringToDate( el, ttz );

				el = calendarItem.querySelector( '.end-datetime' );
				abbr = el.querySelector( 'abbr' );
				ttz = abbr !== null ? abbr.title : false;
				const endDate = liquipedia.calendar.stringToDate( el, ttz );

				// Check if dates are properly entered
				if (
					Object.prototype.toString.call( startDate ) === '[object Date]' &&
					Object.prototype.toString.call( endDate ) === '[object Date]'
				) {
					if ( !isNaN( startDate.getTime() ) && !isNaN( endDate.getTime() ) ) {
						// calculate position of the event in the calendar
						eventLength = ( ( endDate - startDate ) / 60000 ) * PX_PER_MINUTE - 9;
						difference = ( ( startDate - referenceDate ) / 60000 );
						topOffset = ( ( difference % MINUTES_PER_DAY + MINUTES_PER_DAY ) % MINUTES_PER_DAY ) * PX_PER_MINUTE + 1;
						leftOffset = WIDTH_OF_COLUMN * Math.floor( difference / MINUTES_PER_DAY ) + 1;

						let clone;
						// event was yesterday or more than a week in the future
						if ( leftOffset < -1 || topOffset < -2 || leftOffset > WIDTH_OF_COLUMN * ( NUMBER_OF_DAYS - 1 ) + 1 || topOffset > HEIGHT_OF_CALENDAR ) {
							if ( eventLength + topOffset > 0 && leftOffset === -( WIDTH_OF_COLUMN - 1 ) ) {
								clone = calendarItem.cloneNode( true );
								calendarItem.parentNode.insertBefore( clone, calendarItem );
								clone.style.top = ( topOffset - HEIGHT_OF_CALENDAR ) + 'px';
								clone.style.left = ( leftOffset + WIDTH_OF_COLUMN ) + 'px';
								clone.style.height = eventLength + 'px';
							}
							calendarItem.style.display = 'none';
						} else {
							// add event to calendar
							calendarItem.style.top = topOffset + 'px';
							calendarItem.style.left = leftOffset + 'px';
							calendarItem.style.height = eventLength + 'px';
							// if it overlaps (from one day to another), add the another event that is positioned on the next day
							if ( ( topOffset + eventLength ) > HEIGHT_OF_CALENDAR ) {
								clone = calendarItem.cloneNode( true );
								calendarItem.parentNode.insertBefore( clone, calendarItem );
								calendarItem.style.top = ( topOffset - HEIGHT_OF_CALENDAR ) + 'px';
								calendarItem.style.left = ( leftOffset + WIDTH_OF_COLUMN ) + 'px';
								calendarItem.style.height = eventLength + 'px';
							}
						}
					} else {
						calendarItem.style.display = 'none';
					}
				} else {
					calendarItem.style.display = 'none';
				}
			} );
		} );
	},
	stringToDate: function( tempDate, tempTimezone ) {
		let tempDateinnerhTML,
			posTimezone,
			tempPosTimezone,
			UTCTime = 0;

		if ( tempDate.childNodes !== undefined &&
			typeof tempDate.childNodes[ 1 ] !== 'undefined' &&
			typeof tempDate.childNodes[ 1 ].childNodes[ 0 ] !== 'undefined' &&
			tempDate.childNodes[ 1 ].childNodes[ 0 ].nodeValue !== null ) {

			tempDateinnerhTML = tempDate.childNodes[ 0 ].nodeValue + tempDate.childNodes[ 1 ].childNodes[ 0 ].nodeValue;
		} else {
			tempDateinnerhTML = tempDate.childNodes[ 0 ].nodeValue;
		}

		if ( tempTimezone !== false ) {
			posTimezone = tempTimezone.indexOf( '(UTC' ) + 1;

			if ( posTimezone > 0 ) {
				tempPosTimezone = tempTimezone.slice( posTimezone, -1 );
				UTCTime = tempPosTimezone.slice( 3 );
			}
		} else {
			posTimezone = tempDate.innerHTML.trim().indexOf( '(UTC' ) + 1;

			if ( posTimezone > 0 ) {
				tempPosTimezone = tempDate.innerHTML.trim().slice( posTimezone, -1 );
				UTCTime = tempPosTimezone.slice( 3, 5 );
			}
		}

		if ( tempDateinnerhTML === null ) {
			throw new Error( 'Date is null' );
		}

		// Creating DateObject from tempDate
		let str = tempDateinnerhTML.trim().split( ' ' );

		for ( let j = 0; j < str.length; j++ ) {
			str[ j ] = str[ j ].trim();
		}

		str = str.filter( function( e ) {
			return e;
		} );

		if ( tempDateinnerhTML.indexOf( ':' ) === -1 ) {
			return 0;
		} else {
			let endTime;
			if ( ( 'TBA' in liquipedia.calendar.oc( str ) ) || ( 'TBD' in liquipedia.calendar.oc( str ) ) ) {
				return 0;
			} else {
				const index2 = str.indexOf( '-' );

				if ( index2 !== -1 ) {
					str.splice( index2, 1 );
				}
				if ( str.length === 6 ) {
					str.splice( str.length - 2, 1, 'GMT' );
				}
				if ( str.length === 5 ) {
					str.splice( str.length - 1, 1, 'GMT' );
				}
				if ( str.length === 4 ) {
					str.splice( str.length, 1, 'GMT' );
				}

				const dateTemp2 = str.join( ' ' );

				// Get the UTC time, and setHours according to it
				endTime = new Date( dateTemp2 );
				endTime.setHours( endTime.getHours() - UTCTime );
			}
			return endTime;
		}
	},
	oc: function( a ) {
		const o = { };
		for ( let i = 0; i < a.length; i++ ) {
			o[ a[ i ] ] = '';
		}
		return o;
	}
};
liquipedia.core.modules.push( 'calendar' );
