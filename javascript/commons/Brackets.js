/*******************************************************************************
 * Template(s): Match2 brackets
 ******************************************************************************/

liquipedia.brackets = {
	init: function() {
		liquipedia.brackets.headers.init();
		liquipedia.brackets.attachedMatchList.init();
	},
	headers: {
		init: function() {
			liquipedia.brackets.headers.updateAll();
			window.addEventListener( 'resize', liquipedia.brackets.headers.debounce( () => {
				liquipedia.brackets.headers.updateAll();
			}, 100 ) );
		},
		debounce: function( callback, wait ) {
			let timeout;
			return function( e ) {
				clearTimeout( timeout );
				timeout = setTimeout( () => {
					callback( e );
				}, wait );
			};
		},
		updateAll: function() {
			document.querySelectorAll( '.brkts-header-div' ).forEach( ( element ) => {
				const optionsDivs = Array.from( element.querySelectorAll( '.brkts-header-option' ) );
				if ( optionsDivs.length === 0 ) {
					return;
				}
				const options = optionsDivs.map( ( div ) => div.textContent );

				Array.from( element.childNodes ).forEach( ( child ) => {
					if ( !optionsDivs.includes( child ) ) {
						element.removeChild( child );
					}
				} );

				for ( let i = 0; i < options.length; i++ ) {
					const textNode = document.createTextNode( options[ i ] );
					element.insertBefore( textNode, element.firstChild );
					if ( element.scrollWidth <= element.clientWidth || i === options.length - 1 ) {
						break;
					}
					element.removeChild( textNode );
				}
			} );
		}
	},

	attachedMatchList: {
		init: function() {
			document.querySelectorAll(
				'[data-analytics-name]:has( > .standings-group ) + .brkts-matchlist'
			).forEach( ( matchlist ) => {
				const standings = matchlist.previousElementSibling.firstElementChild;
				new ResizeObserver( ( [ entry ] ) => {
					matchlist.style.width = entry.borderBoxSize[ 0 ].inlineSize + 'px';
				} ).observe( standings );
			} );
		}
	}
};

liquipedia.core.modules.push( 'brackets' );
