/*******************************************************************************
 * Template(s): Main Page
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.mainpage = {
	init: function() {
		/* This day */
		var date = new Date();
		var day = date.getDate();
		var month = ( date.getMonth() + 1 );
		var thisDayDate = document.getElementById( 'this-day-date' );
		if ( thisDayDate !== null && thisDayDate.innerHTML !== '(' + liquipedia.mainpage.getMonthName( month ) + ' ' + liquipedia.mainpage.getOrdinal( day ) + ')' ) {
			liquipedia.mainpage.getData( month, day );
		}
		/* Birthday link */
		document.querySelectorAll( '.share-birthday' ).forEach( function( birthdayIcon ) {
			birthdayIcon.style.cursor = 'pointer';
			birthdayIcon.onclick = liquipedia.mainpage.shareBirthday;
		} );
	},
	getData: function( month, day ) {
		mw.loader.using( [ 'mediawiki.api', 'mediawiki.util' ] ).then( function() {
			var api = new mw.Api();
			api.get( {
				action: 'parse',
				maxage: 600,
				smaxage: 600,
				page: 'Liquipedia:This_day/' + month + '/' + day,
				disablelimitreport: true,
				format: 'json'
			} ).done( function( data ) {
				liquipedia.mainpage.useData( data, month, day );
			} );
		} );
	},
	useData: function( data, month, day ) {
		if ( typeof data.parse !== 'undefined' ) {
			document.getElementById( 'this-day-date' ).innerHTML = '(' + liquipedia.mainpage.getMonthName( month ) + ' ' + liquipedia.mainpage.getOrdinal( day ) + ')';
			document.getElementById( 'this-day-trivialink' ).innerHTML = 'Add trivia about this day <a href="' + mw.util.getUrl( 'Liquipedia:This_day/' + month + '/' + day ) + '" title="Liquipedia:This day/' + month + '/' + day + '">here</a>.';
			document.getElementById( 'this-day-facts' ).innerHTML = data.parse.text[ '*' ].replace( '<p><br />\n</p>', '' );
			document.querySelectorAll( '.age' ).forEach( function( age ) {
				age.innerHTML = ( new Date() ).getFullYear() - age.dataset.year;
			} );
			/* Birthday link */
			document.getElementById( 'this-day-facts' ).querySelectorAll( '.share-birthday' ).forEach( function( birthdayIcon ) {
				birthdayIcon.style.cursor = 'pointer';
				birthdayIcon.onclick = liquipedia.mainpage.shareBirthday;
			} );
		}
	},
	getOrdinal: function( number ) {
		if ( number === 1 || number === 21 || number === 31 ) {
			return number + 'st';
		} else if ( number === 2 || number === 22 ) {
			return number + 'nd';
		} else if ( number === 3 || number === 23 ) {
			return number + 'rd';
		} else {
			return number + 'th';
		}
	},
	getMonthName: function( month ) {
		return ( [
			'January',
			'February',
			'March',
			'April',
			'May',
			'June',
			'July',
			'August',
			'September',
			'October',
			'November',
			'December'
		] )[ ( month - 1 ) ];
	},
	shareBirthday: function( event ) {
		event.stopPropagation();
		var button = this;
		mw.loader.using( 'mediawiki.util' ).then( function() {
			var url = mw.config.get( 'wgServer' ) + mw.config.get( 'wgArticlePath' ).replace( '$1', mw.util.wikiUrlencode( button.dataset.page ) );
			var twitterhandlearr = button.dataset.url.replace( '#!/', '' ).replace( '[', '' ).replace( ']', '' ).split( ' ' )[ 0 ].split( 'twitter.com/' );
			var twitterhandle = twitterhandlearr[ twitterhandlearr.length - 1 ];
			var text = 'Happy birthday, @' + twitterhandle + '!';
			liquipedia.tracker.track( 'Birthdaytweet' );
			Share.twitter( url, text );
		} );
	}
};
liquipedia.core.modules.push( 'mainpage' );
