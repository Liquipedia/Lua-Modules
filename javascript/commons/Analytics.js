/*******************************************************************************
 * Template(s): Links
 * Author(s): Eetwalt
 * Description: This script enables anonymous analytics of user interactions
 *              for product development and user experience improvements.
 ******************************************************************************/
liquipedia.analytics = {
	init: function() {
		liquipedia.analytics.setupWikiMenuLinkClickAnalytics();
		liquipedia.analytics.setupLinkClickAnalytics();
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
					if ( node.tagName === 'H2' ) {
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

	setupClickHandler: function( selector, trackerName, propertiesBuilder ) {
		const elements = document.querySelectorAll( selector );

		elements.forEach( ( element ) => {
			element.addEventListener( 'click', () => {
				const eventProperties = propertiesBuilder( element );
				window.amplitude.track( trackerName, eventProperties );
			} );
		} );
	},

	setupWikiMenuLinkClickAnalytics: function() {
		liquipedia.analytics.setupClickHandler(
			'[data-wiki-menu="link"]',
			'Wiki switched',
			( wikiMenuLink ) => ( {
				wiki: wikiMenuLink.closest( '[data-wiki-id]' ).dataset.wikiId,
				'page url': window.location.href,
				position: 'wiki menu',
				destination: wikiMenuLink.href,
				'trending page': false,
				'trending position': null
			} )
		);
	},

	setupLinkClickAnalytics: function() {
		liquipedia.analytics.setupClickHandler(
			'a',
			'Link clicked',
			( link ) => ( {
				title: link.innerText,
				position: liquipedia.analytics.findLinkPosition( link ),
				'page url': window.location.href,
				'destination url': link.href
			} )
		);
	}
};
liquipedia.core.modules.push( 'analytics' );
