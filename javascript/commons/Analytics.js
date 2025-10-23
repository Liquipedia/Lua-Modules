/*******************************************************************************
 * Description: This script enables anonymous analytics of user interactions
 *              for product development and user experience improvements.
 ******************************************************************************/

// Event names
const PAGE_VIEW = 'Page view';
const LINK_CLICKED = 'Link clicked';
const WIKI_SWITCHED = 'Wiki switched';
const SEARCH_PERFORMED = 'Page searched';
const BUTTON_CLICKED = 'Button clicked';
const MATCH_POPUP_OPENED = 'Match popup opened';

// Constants
const IGNORE_CATEGORY_PREFIX = 'Pages ';
const TOC = 'ToC';
const SIDEBAR = 'sidebar';
const INLINE = 'inline';

// Statically defined properties
const getPageDomain = () => window.location.origin;
const getPageLocation = () => window.location.href;
const getPagePath = () => window.location.pathname;
const getPageTitle = () => document.title;
const getPageUrl = () => `${ window.location.origin }${ window.location.pathname }`;
const getReferrerUrl = () => document.referrer;
const getReferrerDomain = () => document.referrer ? new URL( document.referrer ).hostname : null;
const getWikiId = () => mw.config.get( 'wgScriptPath' )?.slice( 1 );

liquipedia.analytics = {
	customPropertyFinders: {
		/********************************************************************
		 * A registry of functions to find component-specific properties.
		 * Each key matches a `data-analytics-name` value.
		 * Each function receives (element, properties, analyticsElement).
		 *******************************************************************/
		ToC: function( tocElement ) {
			if ( tocElement.id === 'sidebar-toc' ) {
				return {
					'ToC position': SIDEBAR
				};
			} else {
				return {
					'ToC position': INLINE
				};
			}
		}
	},

	clickTrackers: [],

	init: function() {
		liquipedia.analytics.sendPageViewEvent();

		liquipedia.analytics.setupWikiMenuLinkClickAnalytics();
		liquipedia.analytics.setupLinkClickAnalytics();
		liquipedia.analytics.setupButtonClickAnalytics();
		liquipedia.analytics.setupSearchAnalytics();
		liquipedia.analytics.setupSearchFormSubmitAnalytics();
		liquipedia.analytics.setupMatchPopupAnalytics();

		document.body.addEventListener( 'click', ( event ) => {
			for ( const tracker of liquipedia.analytics.clickTrackers ) {
				const element = event.target.closest( tracker.selector );

				if ( element ) {
					const eventProperties = tracker.propertiesBuilder( element );
					liquipedia.analytics.track( tracker.trackerName, eventProperties );
				}
			}
		}, true );
	},

	track: function( eventName, properties ) {
		window.amplitude.track( eventName, {
			'page domain': getPageDomain(),
			'page location': getPageLocation(),
			'page path': getPagePath(),
			'page title': getPageTitle(),
			'page url': getPageUrl(),
			wiki: getWikiId(),
			...properties
		} );
	},

	sendPageViewEvent: function() {
		const categories = mw.config.get( 'wgCategories' ) || [];
		liquipedia.analytics.track( PAGE_VIEW, {
			referrer: getReferrerUrl(),
			'referring domain': getReferrerDomain(),
			categories: categories.filter( ( category ) => !category.startsWith( IGNORE_CATEGORY_PREFIX ) )
		} );
	},

	getAnalyticsContextElement: function( element ) {
		const analyticsElement = element.closest( '[data-analytics-name]' );
		if ( analyticsElement ) {
			return {
				type: 'component',
				element: analyticsElement,
				name: analyticsElement.dataset.analyticsName
			};
		}

		const tocElement = element.closest( '#sidebar-toc, #toc' );
		if ( tocElement ) {
			return {
				type: 'toc',
				element: tocElement,
				name: TOC
			};
		}

		const walker = document.createTreeWalker(
			document.body,
			NodeFilter.SHOW_ELEMENT,
			( node ) => (
				[ 'H1', 'H2', 'H3', 'H4' ].includes( node.tagName ) ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_SKIP
			)
		);
		walker.currentNode = element;
		const headingNode = walker.previousNode();

		if ( headingNode ) {
			const clone = headingNode.cloneNode( true );
			clone.querySelector( '.mw-editsection' )?.remove();
			return {
				type: 'heading',
				element: headingNode,
				name: clone.textContent.trim()
			};
		}

		return { type: 'none', element: null, name: null };
	},

	findLinkPosition: function( element ) {
		const context = liquipedia.analytics.getAnalyticsContextElement( element );
		return context.name;
	},

	// Converts a camelCase dataset key into a human-readable property name like
	// 'analyticsInfoboxType' into 'infobox type'.
	formatAnalyticsKey: function( key ) {
		const baseName = key.replace( /^analytics/, '' );
		const withSpaces = baseName.replace( /([A-Z])/g, ' $1' );
		const trimmed = withSpaces.trim();

		if ( !trimmed ) {
			return '';
		}

		return trimmed.toLowerCase();
	},

	getDatasetAnalyticsProperties: function( dataset ) {
		const properties = {};
		Object.entries( dataset )
			.filter( ( [ key ] ) => key.startsWith( 'analytics' ) && key !== 'analyticsName' )
			.forEach( ( [ key, value ] ) => {
				const propertyName = liquipedia.analytics.formatAnalyticsKey( key );
				properties[ propertyName ] = value || null;
			} );
		return properties;
	},

	addCustomProperties: function( element ) {
		const context = liquipedia.analytics.getAnalyticsContextElement( element );
		let customProperties = {};

		if ( context.type === 'component' ) {
			customProperties = liquipedia.analytics.getDatasetAnalyticsProperties( context.element.dataset );
		}

		if ( context.name ) {
			const customFinder = liquipedia.analytics.customPropertyFinders[ context.name ];

			if ( typeof customFinder === 'function' ) {
				const finderProperties = customFinder( context.element, element );

				customProperties = { ...customProperties, ...finderProperties };
			}
		}

		return customProperties;
	},

	setupLinkClickAnalytics: function() {
		liquipedia.analytics.clickTrackers.push( {
			selector: 'a',
			trackerName: LINK_CLICKED,
			propertiesBuilder: ( link ) => {
				const properties = {
					title: link.innerText,
					destination: link.href,
					position: liquipedia.analytics.findLinkPosition( link )
				};

				const customProperties = liquipedia.analytics.addCustomProperties( link );

				return { ...properties, ...customProperties };
			}
		} );
	},

	setupButtonClickAnalytics: function() {
		liquipedia.analytics.clickTrackers.push( {
			selector: '.btn:not(a *), button:not(a *)',
			trackerName: BUTTON_CLICKED,
			propertiesBuilder: ( link ) => ( {
				title: link.innerText,
				position: liquipedia.analytics.findLinkPosition( link )
			} )
		} );
	},

	setupWikiMenuLinkClickAnalytics: function() {
		liquipedia.analytics.clickTrackers.push( {
			selector: '[data-wiki-menu="link"]',
			trackerName: WIKI_SWITCHED,
			propertiesBuilder: ( wikiMenuLink ) => ( {
				wiki: wikiMenuLink.closest( '[data-wiki-id]' ).dataset.wikiId,
				position: 'wiki menu',
				destination: wikiMenuLink.href,
				'trending page': false,
				'trending position': null
			} )
		} );
	},

	setupSearchAnalytics: function() {
		const searchInput = document.querySelector( '#searchInput' );

		if ( searchInput ) {
			searchInput.addEventListener( 'input', () => {
				searchInput.dataset.lastSearchTerm = searchInput.value;
			} );
		}

		liquipedia.analytics.clickTrackers.push( {
			selector: '.mw-searchSuggest-link',
			trackerName: SEARCH_PERFORMED,
			propertiesBuilder: ( link ) => {
				const searchTerm = searchInput?.dataset.lastSearchTerm ?? searchInput?.value ?? '';
				const getResultPosition = () => {
					if ( link.querySelector( '.suggestions-special' ) ) {
						return 'more';
					}

					return parseInt( link.querySelector( '.suggestions-result' ).getAttribute( 'rel' ), 10 ) + 1;
				};

				return {
					'search input': searchTerm,
					title: link.innerText,
					destination: link.href,
					'result position': getResultPosition()
				};
			}
		} );
	},

	setupSearchFormSubmitAnalytics: function() {
		document.body.addEventListener( 'submit', ( event ) => {
			if ( event.target.matches( '#searchform' ) ) {
				const searchTerm = event.target.querySelector( 'input' ).value;

				liquipedia.analytics.track( SEARCH_PERFORMED, {
					'search input': searchTerm,
					title: null,
					destination: `index.php?search=${ encodeURIComponent( searchTerm ) }`,
					'result position': 'enter'
				} );
			}
		} );
	},

	setupMatchPopupAnalytics: function() {
		liquipedia.analytics.clickTrackers.push( {
			selector: '.brkts-match-popup-wrapper',
			trackerName: MATCH_POPUP_OPENED,
			propertiesBuilder: ( match ) => {
				const uniqueParticipants = new Set(
					Array.from( match.querySelectorAll( '.brkts-opponent-hover' ) )
						.map( ( element ) => element.getAttribute( 'aria-label' ) )
				);
				const participants = [ ...uniqueParticipants ];

				const isMatchlist = match.closest( '.brkts-matchlist' );
				const isBracket = match.closest( '.brkts-bracket' );
				const containerType = isMatchlist ? 'matchlist' : isBracket ? 'bracket' : 'unknown';

				return {
					position: liquipedia.analytics.findLinkPosition( match ),
					participants,
					type: containerType
				};
			}
		} );
	}
};

liquipedia.core.modules.push( 'analytics' );
