/**
 * @jest-environment jsdom
 */
/* global jest */

const { test, expect, beforeAll, beforeEach, afterEach, describe } = require( '@jest/globals' );

// Fixed "now" for every test: 2026-11-16 12:00:00 UTC
const NOW = Date.UTC( 2026, 10, 16, 12, 0, 0 );
const NOW_SECONDS = NOW / 1000;

/**
 * Callbacks handed to mediawiki.visibleTimeout's set(), so tests can run countdown ticks manually.
 *
 * @type {Function[]}
 */
let scheduledTicks = [];

let userOptions = {};

/**
 * Creates a Date that behaves as if the browser were in a time zone with the given UTC offset.
 *
 * Jest runs tests in a sandbox where assigning process.env.TZ has no effect, so the local-time
 * getters are overridden instead. They are kept consistent with the real UTC getters, so any way of
 * deriving the offset (getTimezoneOffset or comparing local and UTC fields) sees the same zone.
 *
 * @param {string} isoDate UTC instant
 * @param {number} offsetMinutes local time minus UTC, e.g. 330 for UTC+5:30
 * @return {Date}
 */
function zonedDate( isoDate, offsetMinutes ) {
	const date = new Date( isoDate );
	const local = new Date( date.getTime() + ( offsetMinutes * 60000 ) );
	date.getTimezoneOffset = () => -offsetMinutes;
	date.getFullYear = () => local.getUTCFullYear();
	date.getMonth = () => local.getUTCMonth();
	date.getDate = () => local.getUTCDate();
	date.getHours = () => local.getUTCHours();
	date.getMinutes = () => local.getUTCMinutes();
	return date;
}

function createTimer( attributes, text = 'original text' ) {
	const timer = document.createElement( 'span' );
	timer.className = 'timer-object';
	Object.entries( attributes ).forEach( ( [ key, value ] ) => {
		timer.setAttribute( key, value );
	} );
	timer.innerHTML = text;
	document.body.appendChild( timer );
	return timer;
}

function runNextTick( advanceMs ) {
	jest.setSystemTime( Date.now() + advanceMs );
	scheduledTicks.shift()();
}

describe( 'Countdown module', () => {
	beforeAll( () => {
		globalThis.liquipedia = {
			core: {
				modules: []
			},
			switchButtons: {
				triggerEventName: 'switchButtonChanged',
				getSwitchGroup: jest.fn( () => Promise.resolve( null ) )
			}
		};

		const visibleTimeout = {
			set: jest.fn( ( callback ) => {
				scheduledTicks.push( callback );
				return scheduledTicks.length;
			} ),
			clear: jest.fn()
		};

		globalThis.mw = {
			user: {
				options: {
					get: jest.fn( ( key ) => userOptions[ key ] )
				}
			},
			loader: {
				// mw.loader.using resolves to a require() function for the loaded modules
				using: jest.fn( () => Promise.resolve( () => visibleTimeout ) )
			}
		};

		require( '../commons/Countdown.js' );
	} );

	beforeEach( () => {
		jest.useFakeTimers( { now: NOW } );
		document.body.innerHTML = '';
		scheduledTicks = [];
		userOptions = {};
	} );

	afterEach( () => {
		jest.useRealTimers();
		jest.restoreAllMocks();
	} );

	test( 'should register itself as a module', () => {
		expect( globalThis.liquipedia.core.modules ).toContain( 'countdown' );
	} );

	describe( 'formatTimeDifference', () => {
		test.each( [
			[ 0, '0s' ],
			[ 59, '59s' ],
			[ 60, '1m 0s' ],
			[ 3599, '59m 59s' ],
			[ 3600, '1h 0m 0s' ],
			[ 86399, '23h 59m 59s' ],
			[ 86400, '1d 0h 0m' ],
			[ 604799, '6d 23h 59m' ],
			[ 604800, '1w 0d' ],
			[ ( 57 * 604800 ) + 86400, '57w 1d' ]
		] )( '%i seconds is formatted as "%s"', ( seconds, expected ) => {
			expect( globalThis.liquipedia.countdown.formatTimeDifference( seconds ) ).toBe( expected );
		} );
	} );

	describe( 'getCountdownStringAndClassName', () => {
		const getResult = ( attributes ) => globalThis.liquipedia.countdown.getCountdownStringAndClassName(
			createTimer( attributes )
		);

		test( 'counts down to a future timestamp', () => {
			expect( getResult( { 'data-timestamp': NOW_SECONDS + 90 } ) )
				.toEqual( { text: '1m 30s', className: '' } );
		} );

		test( 'shows LIVE once the timestamp has passed', () => {
			expect( getResult( { 'data-timestamp': NOW_SECONDS - 60 } ) )
				.toEqual( { text: 'LIVE', className: 'timer-object-countdown-live' } );
		} );

		test( 'uses data-countdown-end-text instead of LIVE when given', () => {
			expect( getResult( { 'data-timestamp': NOW_SECONDS - 60, 'data-countdown-end-text': 'Ongoing' } ) )
				.toEqual( { text: 'Ongoing', className: 'timer-object-countdown-live' } );
		} );

		test( 'shows nothing once the match is marked as finished', () => {
			expect( getResult( { 'data-timestamp': NOW_SECONDS - 60, 'data-finished': 'finished' } ) )
				.toEqual( { text: '', className: '' } );
		} );

		test( 'shows nothing 12 hours after the timestamp', () => {
			expect( getResult( { 'data-timestamp': NOW_SECONDS - 43200 } ) )
				.toEqual( { text: '', className: '' } );
			expect( getResult( { 'data-timestamp': NOW_SECONDS - 43199 } ).text ).toBe( 'LIVE' );
		} );
	} );

	describe( 'parseTimerObjectNodeToDateObj', () => {
		test( 'converts the unix timestamp to a Date', () => {
			const timer = createTimer( { 'data-timestamp': NOW_SECONDS } );
			expect( globalThis.liquipedia.countdown.parseTimerObjectNodeToDateObj( timer ).getTime() ).toBe( NOW );
		} );

		test( 'returns false for an errored timestamp', () => {
			const timer = createTimer( { 'data-timestamp': 'error' } );
			expect( globalThis.liquipedia.countdown.parseTimerObjectNodeToDateObj( timer ) ).toBe( false );
		} );
	} );

	describe( 'month names', () => {
		test( 'returns English month names for 0-based month numbers', () => {
			const longNames = [
				'January', 'February', 'March', 'April', 'May', 'June',
				'July', 'August', 'September', 'October', 'November', 'December'
			];
			const shortNames = [ 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' ];

			longNames.forEach( ( name, month ) => {
				expect( globalThis.liquipedia.countdown.getMonthNameFromMonthNumber( month ) ).toBe( name );
				expect( globalThis.liquipedia.countdown.getMonthNameShortFromMonthNumber( month ) )
					.toBe( shortNames[ month ] );
			} );
		} );
	} );

	describe( 'getTimeZoneNameLong', () => {
		test( 'returns the long English name of the browser time zone', () => {
			const date = new Date( NOW );
			const expected = new Intl.DateTimeFormat( 'en', { timeZoneName: 'long' } )
				.formatToParts( date )
				.find( ( part ) => part.type === 'timeZoneName' ).value;

			expect( globalThis.liquipedia.countdown.getTimeZoneNameLong( date ) ).toBe( expected );
		} );
	} );

	describe( 'getCorrectTimeZoneString', () => {
		/**
		 * @param {string} isoDate
		 * @param {number} offsetMinutes
		 * @param {string} timeZoneName long time zone name the browser would report
		 * @param {string} [dateFormat]
		 * @return {string}
		 */
		const format = ( isoDate, offsetMinutes, timeZoneName, dateFormat ) => {
			jest.spyOn( globalThis.liquipedia.countdown, 'getTimeZoneNameLong' ).mockReturnValue( timeZoneName );
			return globalThis.liquipedia.countdown.getCorrectTimeZoneString(
				zonedDate( isoDate, offsetMinutes ),
				dateFormat
			);
		};

		describe( 'whole-hour time zones', () => {
			test.each( [
				[
					'2026-01-15T08:30:00Z', 60, 'Central European Standard Time',
					'January 15, 2026 - 09:30 <abbr data-tz="+1:00" ' +
						'title="Central European Standard Time (UTC+1)">CET</abbr>'
				],
				[
					'2026-07-15T13:30:00Z', 120, 'Central European Summer Time',
					'July 15, 2026 - 15:30 <abbr data-tz="+2:00" ' +
						'title="Central European Summer Time (UTC+2)">CEST</abbr>'
				],
				[
					'2026-01-15T08:30:00Z', -300, 'Eastern Standard Time',
					'January 15, 2026 - 03:30 <abbr data-tz="-5:00" title="Eastern Standard Time (UTC-5)">EST</abbr>'
				],
				[
					'2026-07-15T13:30:00Z', -240, 'Eastern Daylight Time',
					'July 15, 2026 - 09:30 <abbr data-tz="-4:00" title="Eastern Daylight Time (UTC-4)">EDT</abbr>'
				],
				[
					'2026-01-15T08:30:00Z', 540, 'Korean Standard Time',
					'January 15, 2026 - 17:30 <abbr data-tz="+9:00" title="Korean Standard Time (UTC+9)">KST</abbr>'
				]
			] )( '%s at UTC offset %i minutes (%s)', ( isoDate, offsetMinutes, timeZoneName, expected ) => {
				expect( format( isoDate, offsetMinutes, timeZoneName ) ).toBe( expected );
			} );

			test( 'falls back to a plain UTC offset for time zone names without an abbreviation', () => {
				expect( format( '2026-01-15T08:30:00Z', 0, 'Coordinated Universal Time' ) )
					.toBe( 'January 15, 2026 - 08:30 <abbr data-tz="+0:00" title="UTC+0:00">UTC+0</abbr>' );
			} );

			test( 'shows the local date when it differs from the UTC date', () => {
				expect( format( '2026-12-31T22:45:00Z', 540, 'Korean Standard Time' ) ).toBe(
					'January 1, 2027 - 07:45 <abbr data-tz="+9:00" title="Korean Standard Time (UTC+9)">KST</abbr>'
				);
				expect( format( '2026-01-01T02:00:00Z', -300, 'Eastern Standard Time' ) ).toBe(
					'December 31, 2025 - 21:00 <abbr data-tz="-5:00" title="Eastern Standard Time (UTC-5)">EST</abbr>'
				);
			} );

			test( 'defaults to the full format', () => {
				expect( format( '2026-01-15T08:30:00Z', 0, 'Coordinated Universal Time' ) )
					.toBe( format( '2026-01-15T08:30:00Z', 0, 'Coordinated Universal Time', 'full' ) );
			} );
		} );

		describe( 'compact format', () => {
			test( 'leaves out the year for dates in the current year', () => {
				expect( format( '2026-03-05T04:07:00Z', 0, 'Coordinated Universal Time', 'compact' ) )
					.toBe( 'Mar 5 - 04:07 <abbr data-tz="+0:00" title="UTC+0:00">UTC+0</abbr>' );
			} );

			test( 'includes the year for dates in another year', () => {
				expect( format( '2027-03-05T04:07:00Z', 0, 'Coordinated Universal Time', 'compact' ) )
					.toBe( 'Mar 5, 2027 - 04:07 <abbr data-tz="+0:00" title="UTC+0:00">UTC+0</abbr>' );
			} );
		} );

		// Regression tests: the offset used to be computed from hours and minutes separately, which got
		// non-whole-hour zones wrong whenever the local minutes were smaller than the UTC minutes.
		describe( 'half- and quarter-hour time zones', () => {
			test.each( [
				[
					'2026-01-15T08:30:00Z', 330, 'India Standard Time',
					'January 15, 2026 - 14:00 <abbr data-tz="+5:30" title="India Standard Time (UTC+5:30)">IST</abbr>'
				],
				[
					'2026-01-15T09:15:00Z', 330, 'India Standard Time',
					'January 15, 2026 - 14:45 <abbr data-tz="+5:30" title="India Standard Time (UTC+5:30)">IST</abbr>'
				],
				[
					'2026-12-31T22:45:00Z', 330, 'India Standard Time',
					'January 1, 2027 - 04:15 <abbr data-tz="+5:30" title="India Standard Time (UTC+5:30)">IST</abbr>'
				],
				[
					'2026-01-15T08:30:00Z', 345, 'Nepal Time',
					'January 15, 2026 - 14:15 <abbr data-tz="+5:45" title="Nepal Time (UTC+5:45)">NPT</abbr>'
				],
				[
					'2026-07-15T14:15:00Z', 570, 'Australian Central Standard Time',
					'July 15, 2026 - 23:45 <abbr data-tz="+9:30" ' +
						'title="Australian Central Standard Time (UTC+9:30)">ACST</abbr>'
				],
				[
					'2026-01-15T08:30:00Z', 825, 'Chatham Daylight Time',
					'January 15, 2026 - 22:15 <abbr data-tz="+13:45" title="UTC+13:45">UTC+13:45</abbr>'
				],
				[
					'2026-07-15T14:15:00Z', -150, 'Newfoundland Daylight Time',
					'July 15, 2026 - 11:45 <abbr data-tz="-2:30" ' +
						'title="Newfoundland Daylight Time (UTC-2:30)">NDT</abbr>'
				]
			] )( '%s at UTC offset %i minutes (%s)', ( isoDate, offsetMinutes, timeZoneName, expected ) => {
				expect( format( isoDate, offsetMinutes, timeZoneName ) ).toBe( expected );
			} );

			test( 'labels Newfoundland Standard Time as NST', () => {
				expect( format( '2026-01-15T09:15:00Z', -210, 'Newfoundland Standard Time' ) ).toBe(
					'January 15, 2026 - 05:45 <abbr data-tz="-3:30" ' +
						'title="Newfoundland Standard Time (UTC-3:30)">NST</abbr>'
				);
			} );
		} );
	} );

	describe( 'init', () => {
		test( 'replaces the timer content with date, separator and countdown elements', async () => {
			const timer = createTimer( { 'data-timestamp': NOW_SECONDS + 90 } );

			await globalThis.liquipedia.countdown.init();

			const children = Array.from( timer.children );
			expect( children.map( ( child ) => child.className ) )
				.toEqual( [ 'timer-object-date', 'timer-object-separator', 'timer-object-countdown' ] );
			expect( children[ 0 ].innerHTML ).toBe(
				globalThis.liquipedia.countdown.getCorrectTimeZoneString( new Date( NOW + 90000 ), 'full' )
			);
			expect( children[ 1 ].tagName ).toBe( 'BR' );
			expect( children[ 2 ].innerHTML ).toBe( '<span class="timer-object-countdown-time">1m 30s</span>' );
		} );

		test( 'uses the format from data-format', async () => {
			const timer = createTimer( { 'data-timestamp': NOW_SECONDS + 90, 'data-format': 'compact' } );

			await globalThis.liquipedia.countdown.init();

			expect( timer.querySelector( '.timer-object-date' ).innerHTML ).toBe(
				globalThis.liquipedia.countdown.getCorrectTimeZoneString( new Date( NOW + 90000 ), 'compact' )
			);
		} );

		test( 'appends a dash after the countdown when the match has streams', async () => {
			const timer = createTimer( { 'data-timestamp': NOW_SECONDS + 90, 'data-hasstreams': 'true' } );

			await globalThis.liquipedia.countdown.init();

			expect( timer.querySelector( '.timer-object-countdown' ).innerHTML )
				.toBe( '<span class="timer-object-countdown-time">1m 30s</span> - ' );
		} );

		test( 'marks live countdowns with the live class', async () => {
			const timer = createTimer( { 'data-timestamp': NOW_SECONDS - 60 } );

			await globalThis.liquipedia.countdown.init();

			const countdown = timer.querySelector( '.timer-object-countdown' );
			expect( countdown.classList.contains( 'timer-object-countdown-live' ) ).toBe( true );
			expect( countdown.textContent ).toBe( 'LIVE' );
		} );

		test( 'keeps the original text when the timestamp is errored', async () => {
			const timer = createTimer( { 'data-timestamp': 'error' }, 'TBD' );

			await globalThis.liquipedia.countdown.init();

			expect( timer.querySelector( '.timer-object-date' ).innerHTML ).toBe( 'TBD' );
			expect( timer.querySelector( '.timer-object-countdown' ).textContent ).toBe( '' );
		} );

		test( 'keeps the original text when the user disabled time zone adjustment', async () => {
			userOptions[ 'teamliquidintegration-disable-countdown-timezone-adjust' ] = '1';
			const originalText = 'November 16, 2026 - 12:01 <abbr>UTC</abbr>';
			const timer = createTimer( { 'data-timestamp': NOW_SECONDS + 90 }, originalText );

			await globalThis.liquipedia.countdown.init();

			expect( timer.querySelector( '.timer-object-date' ).innerHTML ).toBe( originalText );
		} );

		test( 'does not duplicate elements when run again', async () => {
			const timer = createTimer( { 'data-timestamp': NOW_SECONDS + 90 } );

			await globalThis.liquipedia.countdown.init();
			await globalThis.liquipedia.countdown.init();

			expect( timer.querySelectorAll( '.timer-object-date' ) ).toHaveLength( 1 );
			expect( timer.querySelectorAll( '.timer-object-separator' ) ).toHaveLength( 1 );
			expect( timer.querySelectorAll( '.timer-object-countdown' ) ).toHaveLength( 1 );
		} );

		// jsdom does not implement innerText, so this only passes when the separator is set via textContent
		test( 'renders a custom separator as text', async () => {
			const timer = createTimer( { 'data-timestamp': NOW_SECONDS + 90, 'data-separator': ' | ' } );

			await globalThis.liquipedia.countdown.init();

			const separator = timer.querySelector( '.timer-object-separator' );
			expect( separator.tagName ).toBe( 'SPAN' );
			expect( separator.textContent ).toBe( ' | ' );
		} );
	} );

	describe( 'runCountdown', () => {
		test( 'updates the countdown on every tick', async () => {
			const timer = createTimer( { 'data-timestamp': NOW_SECONDS + 90 } );
			await globalThis.liquipedia.countdown.init();
			const countdown = timer.querySelector( '.timer-object-countdown' );

			expect( countdown.textContent ).toBe( '1m 30s' );
			runNextTick( 1000 );
			expect( countdown.textContent ).toBe( '1m 29s' );
			runNextTick( 89000 );
			expect( countdown.textContent ).toBe( 'LIVE' );
			expect( countdown.classList.contains( 'timer-object-countdown-live' ) ).toBe( true );
		} );

		test( 'does not rewrite the countdown when its text is unchanged', async () => {
			// Countdowns longer than a day only show minutes, so most ticks produce the same text
			const timer = createTimer( { 'data-timestamp': NOW_SECONDS + ( 2 * 86400 ) - 30 } );
			await globalThis.liquipedia.countdown.init();
			const countdown = timer.querySelector( '.timer-object-countdown' );
			const renderedSpan = countdown.firstElementChild;

			runNextTick( 1000 );

			expect( countdown.textContent ).toBe( '1d 23h 59m' );
			expect( countdown.firstElementChild ).toBe( renderedSpan );
		} );
	} );
} );
