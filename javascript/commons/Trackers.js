/*******************************************************************************
 * Template(s): Links
 * Author(s): Eetwalt
 * Description: This script enables anonymous event tracking of user interactions
 *              for product development and user experience improvements.
 ******************************************************************************/
liquipedia.trackers = {
	init: function() {
		const wikiMenuLinks = document.querySelectorAll( '[data-wiki-menu="link"]' );

		wikiMenuLinks.forEach( ( wikiMenuLink ) => {
			const eventProperties = {
				wiki: wikiMenuLink.closest( '[data-wiki-id]' ).dataset.wikiId,
				'page url': window.location.href,
				position: 'wiki menu',
				destination: wikiMenuLink.href,
				'trending page': false,
				'trending position': null
			};

			wikiMenuLink.addEventListener( 'click', () => {
				window.amplitude.track( 'Wiki switched', eventProperties );
			} );
		} );

		function findPosition( element ) {
			const trackerElement = element.closest( '[data-tracking-id]' );
			if ( trackerElement ) {
				return trackerElement.dataset.trackingId;
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
		}

		const links = document.querySelectorAll( 'a' );

		links.forEach( ( link ) => {
			const eventProperties = {
				title: link.innerText,
				position: findPosition( link ),
				'page url': window.location.href,
				'destination url': link.href
			};

			link.addEventListener( 'click', () => {
				window.amplitude.track( 'Link clicked', eventProperties );
			} );
		} );
	}
};
liquipedia.core.modules.push( 'trackers' );
