/*******************************************************************************
 * Description: This script enables anonymous analytics of user interactions
 *              for product development and user experience improvements.
 ******************************************************************************/
/* global RLCONF */

// Event names
const PAGE_VIEW = 'Page view';
const LINK_CLICKED = 'Link clicked';
const WIKI_SWITCHED = 'Wiki switched';

// Constants
const IGNORE_CATEGORY_PREFIX = 'Pages ';

// Statically defined properties
const getPageUrl = () => window.location.href;
const getReferrerUrl = () => document.referrer;
const getPageTitle = () => document.title;

liquipedia.analytics = {
	clickTrackers: [],

	init: function() {
		liquipedia.analytics.sendPageViewEvent();
		liquipedia.analytics.setupWikiMenuLinkClickAnalytics();
		liquipedia.analytics.setupLinkClickAnalytics();
		liquipedia.analytics.setupSearchAnalytics();
		liquipedia.analytics.setupSearchFormSubmitAnalytics();

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
			'page url': getPageUrl(),
			'page title': getPageTitle(),
			...properties
		} );
	},

	sendPageViewEvent: function() {
		const categories = RLCONF?.wgCategories || [];
		liquipedia.analytics.track( PAGE_VIEW, {
			'referrer url': getReferrerUrl(),
			categories: categories.filter( ( category ) => !category.startsWith( IGNORE_CATEGORY_PREFIX ) )
		} );
	},

	findLinkPosition: function( element ) {
		const analyticsElement = element.closest( '[data-analytics-name]' );
		if ( analyticsElement ) {
			return analyticsElement.dataset.analyticsName;
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
		if ( !headingNode ) {
			return null;
		}
		const clone = headingNode.cloneNode( true );
		clone.querySelector( '.mw-editsection' )?.remove();
		return clone.textContent.trim();
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

	setupLinkClickAnalytics: function() {
		liquipedia.analytics.clickTrackers.push( {
			selector: 'a',
			trackerName: LINK_CLICKED,
			propertiesBuilder: ( link ) => ( {
				title: link.innerText,
				position: liquipedia.analytics.findLinkPosition( link ),
				destination: link.href
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
			trackerName: 'Page searched',
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

				liquipedia.analytics.track( 'Page searched', {
					'search input': searchTerm,
					title: null,
					destination: `index.php?search=${ encodeURIComponent( searchTerm ) }`,
					'result position': 'enter'
				} );
			}
		} );
	}
};
liquipedia.core.modules.push( 'analytics' );
