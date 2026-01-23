/*******************************************************************************
 * Template(s): Tab Templates
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.tabs = {
	init: function() {
		document.querySelectorAll( '.tabs-dynamic' ).forEach( ( tabs ) => {
			const navWrapper = tabs.querySelector( '.tabs-nav-wrapper' );
			const navTabs = tabs.querySelector( '.nav-tabs' );
			const contentContainer = tabs.querySelector( '.tabs-content' );

			if ( !navTabs ) {
				return;
			}

			const tabItems = Array.from( navTabs.querySelectorAll( 'li' ) );
			// If content is not inside .tabs-dynamic (portal style), it might be harder to find,
			// but usually it follows immediately.
			const tabContents = contentContainer ?
				Array.from( contentContainer.children ) :
				( tabs.nextElementSibling && tabs.nextElementSibling.classList.contains( 'tabs-content' ) ?
					Array.from( tabs.nextElementSibling.children ) : [] );

			// Indexing
			tabItems.forEach( ( item, i ) => {
				item.dataset.count = i + 1;
			} );
			tabContents.forEach( ( content, i ) => {
				content.dataset.count = i + 1;
			} );

			// Headings for mobile/show-all
			tabContents.forEach( ( tabContent, i ) => {
				if ( tabItems[ i ] ) {
					const heading = document.createElement( 'h6' );
					heading.style.display = 'none';
					heading.innerHTML = tabItems[ i ].innerHTML;
					tabContent.insertAdjacentElement( 'afterbegin', heading );
				}
			} );

			// Click handlers
			tabItems.forEach( ( tabItem, i ) => {
				if ( tabItem.classList.contains( 'active' ) && tabContents[ i ] ) {
					tabContents[ i ].classList.add( 'active' );
				}

				// Wrap in <a> if not already wrapped (Lua might have done it, or not)
				if ( !tabItem.querySelector( 'a' ) ) {
					tabItem.innerHTML = '<a href="#">' + tabItem.innerHTML + '</a>';
				}

				tabItem.addEventListener( 'click', function( ev ) {
					if ( this.dataset.preventClick === 'true' ) {
						delete this.dataset.preventClick;
						return;
					}
					ev.preventDefault();

					tabItems.forEach( ( element ) => {
						element.classList.remove( 'active' );
					} );
					this.classList.add( 'active' );

					tabContents.forEach( ( element ) => {
						element.classList.remove( 'active' );
					} );

					if ( !this.classList.contains( 'show-all' ) ) {
						const index = parseInt( this.dataset.count ) - 1;
						if ( tabContents[ index ] ) {
							tabContents[ index ].classList.add( 'active' );
						}
						tabContents.forEach( ( tabContent ) => {
							const h6 = tabContent.querySelector( 'h6:first-child' );
							if ( h6 ) {
								h6.style.display = 'none';
							}
						} );
					} else {
						tabContents.forEach( ( tabContent ) => {
							tabContent.classList.add( 'active' );
							const h6 = tabContent.querySelector( 'h6:first-child' );
							if ( h6 ) {
								h6.style.display = 'block';
							}
						} );
					}

					liquipedia.tabs.scrollActiveIntoView( navTabs, this );
					liquipedia.tracker.track( 'Dynamic tabs clicked' );
				} );
			} );

			// Drag to scroll & Arrows
			if ( navTabs ) {
				liquipedia.tabs.initDragToScroll( navTabs );
				if ( navWrapper ) {
					liquipedia.tabs.initArrows( navWrapper, navTabs );
				}

				// Initial scroll to active
				const activeTab = navTabs.querySelector( 'li.active' );
				if ( activeTab ) {
					setTimeout( () => {
						liquipedia.tabs.scrollActiveIntoView( navTabs, activeTab, true );
					}, 100 );
				}
			}
		} );

		liquipedia.tabs.onHashChange();
		window.addEventListener( 'hashchange', liquipedia.tabs.onHashChange, false );
	},

	initDragToScroll: function( slider ) {
		let isDown = false;
		let startX;
		let scrollLeft;
		let moved = false;

		slider.addEventListener( 'mousedown', ( e ) => {
			isDown = true;
			slider.classList.add( 'dragging' );
			startX = e.pageX - slider.offsetLeft;
			scrollLeft = slider.scrollLeft;
			moved = false;
		} );

		slider.addEventListener( 'mouseleave', () => {
			isDown = false;
			slider.classList.remove( 'dragging' );
		} );

		slider.addEventListener( 'mouseup', () => {
			isDown = false;
			slider.classList.remove( 'dragging' );
		} );

		slider.addEventListener( 'mousemove', ( e ) => {
			if ( !isDown ) {
				return;
			}
			e.preventDefault();
			const x = e.pageX - slider.offsetLeft;
			const walk = ( x - startX ) * 2;
			if ( Math.abs( walk ) > 5 ) {
				moved = true;
			}
			slider.scrollLeft = scrollLeft - walk;
			const wrapper = slider.closest( '.tabs-nav-wrapper' );
			if ( wrapper ) {
				liquipedia.tabs.updateArrowsVisibility( wrapper, slider );
			}
		} );

		// Prevent click if dragged
		slider.addEventListener( 'click', ( e ) => {
			if ( moved ) {
				const tab = e.target.closest( 'li' );
				if ( tab ) {
					tab.dataset.preventClick = 'true';
				}
			}
		}, true );
	},

	initArrows: function( wrapper, slider ) {
		const leftArrow = wrapper.querySelector( '.tabs-scroll-arrow.left' );
		const rightArrow = wrapper.querySelector( '.tabs-scroll-arrow.right' );

		if ( !leftArrow || !rightArrow ) {
			return;
		}

		const update = () => liquipedia.tabs.updateArrowsVisibility( wrapper, slider );

		slider.addEventListener( 'scroll', update );
		window.addEventListener( 'resize', update );
		update();

		leftArrow.addEventListener( 'click', () => {
			slider.scrollBy( { left: -200, behavior: 'smooth' } );
		} );

		rightArrow.addEventListener( 'click', () => {
			slider.scrollBy( { left: 200, behavior: 'smooth' } );
		} );
	},

	updateArrowsVisibility: function( wrapper, slider ) {
		const leftArrow = wrapper.querySelector( '.tabs-scroll-arrow.left' );
		const rightArrow = wrapper.querySelector( '.tabs-scroll-arrow.right' );

		if ( !leftArrow || !rightArrow ) {
			return;
		}

		const hasOverflow = slider.scrollWidth > slider.clientWidth;

		if ( hasOverflow ) {
			if ( slider.scrollLeft > 5 ) {
				leftArrow.classList.add( 'visible' );
			} else {
				leftArrow.classList.remove( 'visible' );
			}

			if ( slider.scrollLeft + slider.clientWidth < slider.scrollWidth - 5 ) {
				rightArrow.classList.add( 'visible' );
			} else {
				rightArrow.classList.remove( 'visible' );
			}
		} else {
			leftArrow.classList.remove( 'visible' );
			rightArrow.classList.remove( 'visible' );
		}
	},

	scrollActiveIntoView: function( slider, activeItem, instant ) {
		if ( !slider || !activeItem ) {
			return;
		}

		const sliderWidth = slider.clientWidth;
		const itemOffset = activeItem.offsetLeft;
		const itemWidth = activeItem.clientWidth;

		const targetScroll = itemOffset - ( sliderWidth / 2 ) + ( itemWidth / 2 );

		slider.scrollTo( {
			left: targetScroll,
			behavior: instant ? 'auto' : 'smooth'
		} );

		// Update arrows after scroll
		setTimeout( () => {
			const wrapper = slider.closest( '.tabs-nav-wrapper' );
			if ( wrapper ) {
				liquipedia.tabs.updateArrowsVisibility( wrapper, slider );
			}
		}, instant ? 0 : 300 );
	},

	onHashChange: function() {
		const hash = location.hash.slice( 1 );
		let tabno;
		let scrollto;
		if ( hash.slice( 0, 4 ) === 'tab-' ) {
			const hasharr = hash.split( '-scrollto-' );
			tabno = hasharr[ 0 ].replace( 'tab-', '' );
			scrollto = null;
			if ( hasharr.length === 2 ) {
				scrollto = '#' + hasharr[ 1 ];
			}
			liquipedia.tabs.showDynamicTab( tabno, scrollto );
		} else {
			scrollto = location.hash.replace( /(\.)/g, '\\$1' );
			if ( scrollto.length > 0 ) {
				const tabs = document.getElementById( scrollto.slice( 1 ) );
				if ( tabs !== null && tabs.closest( '.tabs-dynamic .tabs-content > div' ) !== null ) {
					tabno = tabs.closest( '.tabs-dynamic .tabs-content > div' ).dataset.count;
					if ( typeof tabno !== 'undefined' ) {
						liquipedia.tabs.showDynamicTab( tabno, scrollto );
					}
				}
			}
		}
	},

	showDynamicTab: function( tabno, scrollto ) {
		let scrolltoelement = null;
		if ( scrollto !== null ) {
			scrolltoelement = document.getElementById( scrollto.slice( 1 ) );
		}
		if ( scrolltoelement !== null ) {
			const tabs = scrolltoelement.closest( '.tabs-dynamic' );
			const navTabs = tabs.querySelector( '.nav-tabs' );
			if ( !navTabs ) {
				return;
			}
			navTabs.querySelectorAll( 'li' ).forEach( ( listelement ) => {
				listelement.classList.remove( 'active' );
			} );
			const activeTab = navTabs.querySelector( '.tab' + tabno );
			if ( activeTab ) {
				activeTab.classList.add( 'active' );
				liquipedia.tabs.scrollActiveIntoView( navTabs, activeTab );
			}
			tabs.querySelectorAll( '.tabs-content > div' ).forEach( ( contentelement ) => {
				contentelement.classList.remove( 'active' );
			} );
			const content = tabs.querySelector( '.tabs-content > .content' + tabno );
			if ( content ) {
				content.classList.add( 'active' );
			}
			if ( scrollto !== null ) {
				setTimeout( () => {
					if ( typeof window.scrollY !== 'undefined' ) {
						window.scrollTo( 0, scrolltoelement.getBoundingClientRect().top + window.scrollY );
					} else {
						window.scrollTo( 0, scrolltoelement.getBoundingClientRect().top + window.pageYOffset );
					}
				}, 500 );
			}
		} else {
			document.querySelectorAll( '.tabs-dynamic' ).forEach( ( tabs ) => {
				const navTabs = tabs.querySelector( '.nav-tabs' );
				if ( !navTabs ) {
					return;
				}
				navTabs.querySelectorAll( 'li' ).forEach( ( listelement ) => {
					listelement.classList.remove( 'active' );
				} );
				const activeTab = navTabs.querySelector( '.tab' + tabno );
				if ( activeTab ) {
					activeTab.classList.add( 'active' );
					liquipedia.tabs.scrollActiveIntoView( navTabs, activeTab );
				}
				tabs.querySelectorAll( '.tabs-content > div' ).forEach( ( contentelement ) => {
					contentelement.classList.remove( 'active' );
				} );
				const content = tabs.querySelector( '.tabs-content > .content' + tabno );
				if ( content ) {
					content.classList.add( 'active' );
				}
			} );
		}
	}
};
liquipedia.core.modules.push( 'tabs' );
