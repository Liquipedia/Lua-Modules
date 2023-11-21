/*******************************************************************************
 * Template(s): Commons main page
 * Author(s): FO-nTTaX, Clubfan
 ******************************************************************************/
liquipedia.commonsmainpage = {
	init: function() {
		liquipedia.commonsmainpage.redirectUpload();
		liquipedia.commonsmainpage.showRecentUploads();
	},
	redirectUpload: function() {
		window.addEventListener( 'load', function() {
			if ( ( mw.config.get( 'wgPageName' ) === 'Special:Upload' ) && ( mw.config.get( 'wgNamespaceNumber' ) === -1 ) && ( typeof mw.user.isAnon === 'function' ) && ( mw.user.isAnon() ) ) {
				var url = document.querySelector( '#mw-content-text a' ).href;
				if ( !url.startsWith( 'http' ) ) {
					url = mw.config.get( 'wgServer' ) + url;
				}
				window.location.replace( url );
			}
		} );
	},
	showRecentUploads: function() {
		mw.loader.using( 'mediawiki.api' ).then( function() {
			var latestUploads = document.getElementById( 'latest-uploads' );
			if ( latestUploads !== null ) {
				var api = new mw.Api();
				api.get( {
					action: 'query',
					list: 'logevents',
					leaction: 'upload/upload',
					lelimit: 20,
					"continue": '',
					format: 'json'
				} ).done( function( logEntries ) {
					var imageNames = [ ];
					logEntries.query.logevents.forEach( function( title ) {
						imageNames.push( title.title );
					} );
					api.get( {
						action: 'query',
						prop: 'imageinfo',
						titles: imageNames,
						iiprop: 'url',
						iiurlheight: 150,
						format: 'json'
					} ).done( function( imageData ) {
						var imageUrls = [ ];
						imageUrls = imageUrls.reverse();
						var output = '';
						var counter = 0;
						Object.keys( imageData.query.pages ).reverse().forEach( function( key ) {
							var image = imageData.query.pages[ key ];
							if ( typeof image.imageinfo !== 'undefined' ) {
								if ( counter++ < 10 ) {
									output += '<div><a href="' + image.imageinfo[ 0 ].descriptionurl + '"><img src="' + image.imageinfo[ 0 ].thumburl + '"><br><p>' + image.title + '</p></a></div>';
								}
							}
						} );
						latestUploads.innerHTML = output;
					} );
				} );
			}
		} );
	}
};
liquipedia.core.modules.push( 'commonsmainpage' );
