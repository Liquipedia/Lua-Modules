/*******************************************************************************
 * Template(s): Tab Templates
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.tabs = {
	init: function() {
		document.querySelectorAll( '.tabs-dynamic' ).forEach( function( tabs ) {
			var tabItems = [];
			var tabContents = [];
			for ( var i = 0; i < tabs.children.length; i++ ) {
				var j;
				if ( tabs.children[ i ].classList.contains( 'tabs-content' ) ) {
					for ( j = 0; j < tabs.children[ i ].children.length; j++ ) {
						tabs.children[ i ].children[ j ].dataset.count = j + 1;
						tabContents.push( tabs.children[ i ].children[ j ] );
					}
				} else {
					for ( j = 0; j < tabs.children[ i ].children.length; j++ ) {
						tabs.children[ i ].children[ j ].dataset.count = j + 1;
						tabItems.push( tabs.children[ i ].children[ j ] );
					}
				}
			}
			tabContents.forEach( function( tabContent, idx ) {
				var heading = document.createElement( 'h6' );
				heading.style.display = 'none';
				heading.innerHTML = tabItems[ idx ].innerHTML;
				tabContent.insertAdjacentElement( 'afterbegin', heading );
			} );
			tabItems.forEach( function( tabItem, idx ) {
				if ( tabItem.classList.contains( 'active' ) ) {
					tabContents[ idx ].classList.add( 'active' );
				}
				tabItem.innerHTML = '<a href="#">' + tabItem.innerHTML + '</a>';
				tabItem.addEventListener( 'click', function( ev ) {
					ev.preventDefault();
					tabItems.forEach( function( element ) {
						element.classList.remove( 'active' );
					} );
					this.classList.add( 'active' );
					tabContents.forEach( function( element ) {
						element.classList.remove( 'active' );
					} );
					if ( !this.classList.contains( 'show-all' ) ) {
						tabContents[ parseInt( this.dataset.count ) - 1 ].classList.add( 'active' );
						tabContents.forEach( function( tabContent ) {
							tabContent.querySelector( 'h6:first-child' ).style.display = 'none';
						} );
					} else {
						tabContents.forEach( function( tabContent ) {
							tabContent.classList.add( 'active' );
							tabContent.querySelector( 'h6:first-child' ).style.display = 'block';
						} );
					}
					liquipedia.tracker.track( 'Dynamic tabs clicked' );
				} );
			} );
		} );
		liquipedia.tabs.onHashChange();
		window.addEventListener( 'hashchange', liquipedia.tabs.onHashChange, false );
	},
	onHashChange: function() {
		var hash = location.hash.slice( 1 );
		var tabno;
		var scrollto;
		if ( hash.slice( 0, 4 ) === 'tab-' ) {
			var hasharr = hash.split( '-scrollto-' );
			tabno = hasharr[ 0 ].replace( 'tab-', '' );
			scrollto = null;
			if ( hasharr.length === 2 ) {
				scrollto = '#' + hasharr[ 1 ];
			}
			liquipedia.tabs.showDynamicTab( tabno, scrollto );
		} else {
			scrollto = location.hash.replace( /(\.)/g, '\\\\$1' );
			if ( scrollto.length > 0 ) {
				var tabs = document.getElementById( scrollto.slice( 1 ) );
				if ( tabs !== null && tabs.closest( '.tabs-dynamic > .tabs-content > div' ) !== null ) {
					tabno = tabs.closest( '.tabs-dynamic > .tabs-content > div' ).dataset.count;
					if ( typeof tabno !== 'undefined' ) {
						liquipedia.tabs.showDynamicTab( tabno, scrollto );
					}
				}
			}
		}
	},
	showDynamicTab: function( tabno, scrollto ) {
		var scrolltoelement = null;
		if ( scrollto !== null ) {
			scrolltoelement = document.getElementById( scrollto.slice( 1 ) );
		}
		if ( scrolltoelement !== null ) {
			var scrollTabs = scrolltoelement.closest( '.tabs-dynamic' );
			scrollTabs.querySelectorAll( '.nav-tabs li' ).forEach( function( listelement ) {
				listelement.classList.remove( 'active' );
			} );
			scrollTabs.querySelector( '.nav-tabs .tab' + tabno ).classList.add( 'active' );
			scrollTabs.querySelectorAll( '.tabs-content > div' ).forEach( function( contentelement ) {
				contentelement.classList.remove( 'active' );
			} );
			scrollTabs.querySelector( '.tabs-content > .content' + tabno ).classList.add( 'active' );
			if ( scrollto !== null ) {
				setTimeout( function() {
					if ( typeof window.scrollY !== 'undefined' ) {
						window.scrollTo( 0, scrolltoelement.getBoundingClientRect().top + window.scrollY );
					} else {
						window.scrollTo( 0, scrolltoelement.getBoundingClientRect().top + window.pageYOffset );
					}
				}, 500 );
			}
		} else {
			document.querySelectorAll( '.tabs-dynamic' ).forEach( function( tabs ) {
				tabs.querySelectorAll( '.nav-tabs li' ).forEach( function( listelement ) {
					listelement.classList.remove( 'active' );
				} );
				tabs.querySelector( '.nav-tabs .tab' + tabno ).classList.add( 'active' );
				tabs.querySelectorAll( '.tabs-content > div' ).forEach( function( contentelement ) {
					contentelement.classList.remove( 'active' );
				} );
				tabs.querySelector( '.tabs-content > .content' + tabno ).classList.add( 'active' );
			} );
		}
	}
};
liquipedia.core.modules.push( 'tabs' );
