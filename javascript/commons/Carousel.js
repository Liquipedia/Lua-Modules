liquipedia.carousel = {
	carousels: [],
	resizeListenerAdded: false,

	init: function() {
		const carouselElements = document.querySelectorAll( '.carousel' );
		if ( !carouselElements.length ) {
			return;
		}

		carouselElements.forEach( ( carousel ) => {
			liquipedia.carousel.initCarousel( carousel );
		} );

		if ( !liquipedia.carousel.resizeListenerAdded ) {
			let resizeTimeout;
			window.addEventListener( 'resize', () => {
				clearTimeout( resizeTimeout );
				resizeTimeout = setTimeout( () => {
					liquipedia.carousel.handleResize();
				}, 150 );
			} );
			liquipedia.carousel.resizeListenerAdded = true;
		}
	},

	initCarousel: function( carousel ) {
		const content = carousel.querySelector( '.carousel-content' );
		const items = carousel.querySelectorAll( '.carousel-item' );
		const leftButton = carousel.querySelector( '.carousel-button--left' );
		const rightButton = carousel.querySelector( '.carousel-button--right' );
		const leftFade = carousel.querySelector( '.carousel-fade--left' );
		const rightFade = carousel.querySelector( '.carousel-fade--right' );

		if ( !content || !items.length || !leftButton || !rightButton ) {
			return;
		}

		if ( items.length === 1 ) {
			if ( leftButton ) {
				leftButton.style.display = 'none';
			}
			if ( rightButton ) {
				rightButton.style.display = 'none';
			}
			if ( leftFade ) {
				leftFade.style.display = 'none';
			}
			if ( rightFade ) {
				rightFade.style.display = 'none';
			}
			return;
		}

		const carouselData = {
			container: carousel,
			content: content,
			items: items,
			leftButton: leftButton,
			rightButton: rightButton,
			leftFade: leftFade,
			rightFade: rightFade,
			itemWidth: items[ 0 ].offsetWidth,
			fadeWidth: leftFade ? leftFade.offsetWidth : 0
		};

		liquipedia.carousel.carousels.push( carouselData );

		liquipedia.carousel.updateButtonVisibility( carouselData );

		leftButton.addEventListener( 'click', () => {
			liquipedia.carousel.scrollLeft( carouselData );
		} );

		rightButton.addEventListener( 'click', () => {
			liquipedia.carousel.scrollRight( carouselData );
		} );

		let scrollTimeout;
		content.addEventListener( 'scroll', () => {
			clearTimeout( scrollTimeout );
			scrollTimeout = setTimeout( () => {
				liquipedia.carousel.updateButtonVisibility( carouselData );
			}, 50 );
		} );
	},

	scrollLeft: function( carouselData ) {
		const currentScroll = carouselData.content.scrollLeft;
		const itemWidth = carouselData.itemWidth;

		// Simple logic: CSS scroll-margin-left handles the precise alignment now
		const target = currentScroll - itemWidth;

		carouselData.content.scrollTo( {
			left: target,
			behavior: 'smooth'
		} );
	},

	scrollRight: function( carouselData ) {
		const currentScroll = carouselData.content.scrollLeft;
		const itemWidth = carouselData.itemWidth;

		// Simple logic: CSS scroll-margin-left handles the precise alignment now
		const target = currentScroll + itemWidth;

		carouselData.content.scrollTo( {
			left: target,
			behavior: 'smooth'
		} );
	},

	updateButtonVisibility: function( carouselData ) {
		const content = carouselData.content;
		const scrollLeft = content.scrollLeft;
		const scrollWidth = content.scrollWidth;
		const clientWidth = content.clientWidth;
		const maxScroll = scrollWidth - clientWidth;

		// Tolerance of 10px allows for minor browser rounding differences
		const atStart = scrollLeft <= 10;
		const atEnd = scrollLeft >= maxScroll - 10;

		if ( carouselData.leftButton ) {
			carouselData.leftButton.style.display = atStart ? 'none' : '';
		}
		if ( carouselData.leftFade ) {
			carouselData.leftFade.style.display = atStart ? 'none' : '';
		}

		if ( carouselData.rightButton ) {
			carouselData.rightButton.style.display = atEnd ? 'none' : '';
		}
		if ( carouselData.rightFade ) {
			carouselData.rightFade.style.display = atEnd ? 'none' : '';
		}
	},

	handleResize: function() {
		liquipedia.carousel.carousels.forEach( ( carouselData ) => {
			if ( carouselData.items.length > 0 ) {
				carouselData.itemWidth = carouselData.items[ 0 ].offsetWidth;
			}
			if ( carouselData.leftFade ) {
				carouselData.fadeWidth = carouselData.leftFade.offsetWidth;
			}
			liquipedia.carousel.updateButtonVisibility( carouselData );
		} );
	}
};

liquipedia.core.modules.push( 'carousel' );
