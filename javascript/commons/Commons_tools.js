/*******************************************************************************
 * Template(s): [[Tools]] page on this wiki
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.commonstools = {
	init: function() {
		liquipedia.commonstools.createForms();
		liquipedia.commonstools.createCallbacks();
	},
	wikis: null,
	createForms: function() {
		const checkForPageExistenceForm = document.getElementById( 'checkforpageexistence' );
		if ( checkForPageExistenceForm !== null ) {
			checkForPageExistenceForm.innerHTML = '<form id="checkforpageexistenceform"><input id="checkforpageexistenceinput" placeholder="Name of page" class="form-control"><button id="checkforpageexistencebutton" class="btn btn-primary" type="submit">Search</button></form><div id="checkforpageexistenceresult"></div>';
		}
		const checkPageTextForm = document.getElementById( 'checkpagetext' );
		if ( checkPageTextForm !== null ) {
			checkPageTextForm.innerHTML = '<form id="checkpagetextform"><input id="checkpagetextforminputname" placeholder="Name of page" class="form-control"><input id="checkpagetextforminputsource" placeholder="Source wiki" class="form-control"><button id="checkpagetextbutton" class="btn btn-primary" type="submit">Search</button></form><div id="checkpagetextresult"></div>';
		}
	},
	createCallbacks: function() {
		const checkForPageExistenceForm = document.getElementById( 'checkforpageexistenceform' );
		if ( checkForPageExistenceForm !== null ) {
			checkForPageExistenceForm.addEventListener( 'submit', liquipedia.commonstools.checkForPageExistence );
		}
		const checkPageTextForm = document.getElementById( 'checkpagetextform' );
		if ( checkPageTextForm !== null ) {
			checkPageTextForm.addEventListener( 'submit', liquipedia.commonstools.checkPageText );
		}
	},
	setupWikisWithCallback: function( callback ) {
		if ( liquipedia.commonstools.wikis === null ) {
			const api = new mw.ForeignApi( '/api.php' );
			api.get( {
				action: 'listwikis'
			} ).done( function( data ) {
				liquipedia.commonstools.wikis = data.allwikis;
				callback();
			} );
		} else {
			callback();
		}
	},
	checkForPageExistence: function( ev ) {
		ev.preventDefault();
		mw.loader.using( [ 'mediawiki.ForeignApi', 'mediawiki.api' ], function() {
			liquipedia.commonstools.setupWikisWithCallback( liquipedia.commonstools.checkForPageExistenceReal );
		} );
	},
	checkForPageExistenceReal: function() {
		const title = document.getElementById( 'checkforpageexistenceinput' ).value;
		let wikiData = null;
		let listElement = null;
		const checkForPageExistenceResult = document.getElementById( 'checkforpageexistenceresult' );
		let i = 1;
		if ( checkForPageExistenceResult !== null ) {
			checkForPageExistenceResult.innerHTML = '<ul id="checkforpageexistenceresultlist"></ul>';
			const checkForPageExistenceResultList = document.getElementById( 'checkforpageexistenceresultlist' );
			for ( const wiki in liquipedia.commonstools.wikis ) {
				if ( Object.prototype.hasOwnProperty.call( liquipedia.commonstools.wikis, wiki ) ) {
					wikiData = liquipedia.commonstools.wikis[ wiki ];
					listElement = document.createElement( 'li' );
					checkForPageExistenceResultList.append( listElement );
					liquipedia.commonstools.timeoutPageExistenceApi( i, wiki, wikiData, title, listElement );
					i++;
				}
			}
		}
	},
	checkForPageExistenceApiCall: function( wiki, wikiData, title, listElement ) {
		const api = new mw.Api( { ajax: { url: wikiData.api } } );
		api.get( {
			action: 'query',
			prop: 'revisions',
			rvprop: 'content',
			format: 'json',
			formatversion: 2,
			titles: title
		} ).done( function( data ) {
			if ( !Object.prototype.hasOwnProperty.call( data, 'query' ) ) {
				listElement.innerHTML = '<span style="color:#0000ff;">You need to put in a valid page title</span>';
			} else {
				const page = data.query.pages[ 0 ];
				const link = document.createElement( 'a' );
				const editLink = document.createElement( 'a' );
				const span = document.createElement( 'span' );
				link.href = '/' + wiki + '/' + page.title;
				editLink.href = '/' + wiki + '/index.php?title=' + page.title + '&action=edit';
				editLink.innerHTML = 'Edit';
				span.innerHTML = ' - ';
				if ( Object.prototype.hasOwnProperty.call( page, 'missing' ) && page.missing ) {
					link.innerHTML = wikiData.name + ': No';
					link.style.backgroundColor = '#f8cbcb';
					editLink.style.backgroundColor = '#f8cbcb';
					span.style.backgroundColor = '#f8cbcb';
				} else {
					link.innerHTML = wikiData.name + ': Yes';
					link.style.backgroundColor = '#a6f3a6';
					editLink.style.backgroundColor = '#a6f3a6';
					span.style.backgroundColor = '#a6f3a6';
				}
				link.style.color = '#000000';
				editLink.style.color = '#000000';
				span.style.color = '#000000';
				listElement.append( link );
				listElement.append( span );
				listElement.append( editLink );
			}
		} );
	},
	checkPageText: function( ev ) {
		ev.preventDefault();
		mw.loader.using( [ 'mediawiki.ForeignApi', 'mediawiki.api' ], function() {
			liquipedia.commonstools.setupWikisWithCallback( liquipedia.commonstools.checkPageTextReal );
		} );
	},
	checkPageTextRealSourceText: null,
	checkPageTextReal: function() {
		const title = document.getElementById( 'checkpagetextforminputname' ).value;
		const sourceWiki = document.getElementById( 'checkpagetextforminputsource' ).value;
		let wikiData = null;
		let listElement = null;
		const checkPageTextResult = document.getElementById( 'checkpagetextresult' );
		let i = 1;
		if ( checkPageTextResult !== null ) {
			checkPageTextResult.innerHTML = '<ul id="checkpagetextresultlist"></ul>';
			const checkPageTextResultList = document.getElementById( 'checkpagetextresultlist' );
			const api = new mw.Api( { ajax: { url: '/' + sourceWiki + '/api.php' } } );
			api.get( {
				action: 'query',
				prop: 'revisions',
				rvprop: 'content',
				format: 'json',
				formatversion: 2,
				titles: title
			} ).done( function( data ) {
				if ( !Object.prototype.hasOwnProperty.call( data, 'query' ) ) {
					listElement.innerHTML = '<span style="color:#0000ff;">You need to put in a valid page title</span>';
				} else {
					const page = data.query.pages[ 0 ];
					if ( Object.prototype.hasOwnProperty.call( page, 'missing' ) && page.missing ) {
						listElement = document.createElement( 'li' );
						listElement.style.color = '#0000ff';
						listElement.innerHTML = 'Page does not exist on source wiki';
						checkPageTextResultList.append( listElement );
					} else {
						liquipedia.commonstools.checkPageTextRealSourceText = page.revisions[ 0 ].content;
						for ( const wiki in liquipedia.commonstools.wikis ) {
							if ( Object.prototype.hasOwnProperty.call( liquipedia.commonstools.wikis, wiki ) ) {
								if ( sourceWiki !== wiki ) {
									wikiData = liquipedia.commonstools.wikis[ wiki ];
									listElement = document.createElement( 'li' );
									checkPageTextResultList.append( listElement );
									liquipedia.commonstools.timeoutPageTextApi( i, wiki, wikiData, title, sourceWiki, listElement );
									i++;
								}
							}
						}
					}
				}
			} );
		}
	},
	checkPageTextApiCall: function( wiki, wikiData, title, sourceWiki, listElement ) {
		const api = new mw.Api( { ajax: { url: wikiData.api } } );
		api.get( {
			action: 'query',
			prop: 'revisions',
			rvprop: 'content',
			format: 'json',
			formatversion: 2,
			titles: title
		} ).done( function( data ) {
			if ( !Object.prototype.hasOwnProperty.call( data, 'query' ) ) {
				listElement.innerHTML = '<span style="color:#0000ff;">You need to put in a valid page title</span>';
			} else {
				const page = data.query.pages[ 0 ];
				const link = document.createElement( 'a' );
				const postButton = document.createElement( 'button' );
				const span = document.createElement( 'span' );
				link.href = '/' + wiki + '/' + page.title;
				postButton.type = 'button';
				postButton.innerHTML = 'Transfer';
				span.innerHTML = ' - ';
				if ( Object.prototype.hasOwnProperty.call( page, 'missing' ) && page.missing ) {
					link.innerHTML = wikiData.name + ': Page does not exist';
					link.style.color = '#ff0000';
					span.style.color = '#ff0000';
					listElement.append( link );
					listElement.append( span );
					listElement.append( postButton );
				} else {
					if ( page.revisions[ 0 ].content === liquipedia.commonstools.checkPageTextRealSourceText ) {
						link.innerHTML = wikiData.name + ': Page exists and text is equal';
						link.style.color = '#006400';
						listElement.append( link );
					} else {
						link.innerHTML = wikiData.name + ': Page exists but text is different';
						link.style.color = '#cc752e';
						span.style.color = '#cc752e';
						listElement.append( link );
						listElement.append( span );
						listElement.append( postButton );
					}
				}
				postButton.addEventListener( 'click', function() {
					const api2 = new mw.Api( { ajax: { url: wikiData.api } } );
					api2.get( {
						action: 'query',
						meta: 'tokens'
					} ).done( function( data2 ) {
						const editToken = data2.query.tokens.csrftoken;
						if ( editToken === '+\\' ) {
							const errorMessage = document.createElement( 'p' );
							errorMessage.style.color = '#ff0000';
							errorMessage.innerHTML = 'Not logged in on destination wiki';
							listElement.append( errorMessage );
						} else {
							api2.post( {
								action: 'edit',
								title: title,
								text: liquipedia.commonstools.checkPageTextRealSourceText,
								token: editToken
							} ).done( function() {
								const successMessage = document.createElement( 'p' );
								successMessage.style.color = '#006400';
								successMessage.innerHTML = 'Transferred!';
								listElement.append( successMessage );
							} );
						}
					} );
				} );
			}
		} );
	},
	timeoutPageExistenceApi: function( i, wiki, wikiData, title, listElement ) {
		setTimeout( function() {
			liquipedia.commonstools.checkForPageExistenceApiCall( wiki, wikiData, title, listElement );
		}, i * 1000 );
	},
	timeoutPageTextApi: function( i, wiki, wikiData, title, sourceWiki, listElement ) {
		setTimeout( function() {
			liquipedia.commonstools.checkPageTextApiCall( wiki, wikiData, title, sourceWiki, listElement );
		}, i * 1000 );
	}
};
liquipedia.core.modules.push( 'commonstools' );
