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

		document.body.addEventListener( 'click', ( event ) => {
			for ( const tracker of liquipedia.analytics.clickTrackers ) {
				const element = event.target.closest( tracker.selector );

				if ( element ) {
					const eventProperties = tracker.propertiesBuilder( element );
					window.amplitude.track( tracker.trackerName, eventProperties );
				}
			}
		}, true );
	},

	sendPageViewEvent: function() {
		const categories = RLCONF.wgCategories || [];
		window.amplitude.track( PAGE_VIEW, {
			'page url': getPageUrl(),
			'referrer url': getReferrerUrl(),
			'page title': getPageTitle(),
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
			{
				acceptNode: function( node ) {
					if ( node.tagName === 'H1' || node.tagName === 'H2' ) {
						return NodeFilter.FILTER_ACCEPT;
					}
					return NodeFilter.FILTER_SKIP;
				}
			}
		);

		walker.currentNode = element;

		const headingNode = walker.previousNode();

		if ( !headingNode ) {
			return null;
		}

		const clone = headingNode.cloneNode( true );
		const editSection = clone.querySelector( '.mw-editsection' );

		if ( editSection ) {
			editSection.remove();
		}

		return clone.textContent.trim();
	},

	setupWikiMenuLinkClickAnalytics: function() {
		liquipedia.analytics.clickTrackers.push( {
			selector: '[data-wiki-menu="link"]',
			trackerName: WIKI_SWITCHED,
			propertiesBuilder: ( wikiMenuLink ) => ( {
				wiki: wikiMenuLink.closest( '[data-wiki-id]' ).dataset.wikiId,
				'page url': getPageUrl(),
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
				'page url': getPageUrl(),
				'destination url': link.href
			} )
		} );
	}
};
liquipedia.core.modules.push( 'analytics' );
