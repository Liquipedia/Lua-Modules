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
				resizeTimeout = setTimeout( liquipedia.carousel.handleResize, 150 );
			} );
			liquipedia.carousel.resizeListenerAdded = true;
		}
	},

	initCarousel: function( carousel ) {
		const content = carousel.querySelector( '.carousel-content' );
		const items = carousel.querySelectorAll( '.carousel-item' );

		const controls = {
			left: [
				carousel.querySelector( '.carousel-button--left' ),
				carousel.querySelector( '.carousel-fade--left' )
			],
			right: [
				carousel.querySelector( '.carousel-button--right' ),
				carousel.querySelector( '.carousel-fade--right' )
			]
		};

		if ( !content || !items.length || !controls.left[ 0 ] || !controls.right[ 0 ] ) {
			return;
		}

		if ( items.length === 1 ) {
			[ ...controls.left, ...controls.right ].forEach( ( element ) => {
				if ( element ) {
					element.style.display = 'none';
				}
			} );
			return;
		}

		const carouselData = {
			container: carousel,
			content,
			items,
			controls,
			itemWidth: items[ 0 ].offsetWidth
		};

		liquipedia.carousel.carousels.push( carouselData );
		liquipedia.carousel.updateButtonVisibility( carouselData );

		controls.left[ 0 ].addEventListener( 'click', () => liquipedia.carousel.scroll( carouselData, -1 ) );
		controls.right[ 0 ].addEventListener( 'click', () => liquipedia.carousel.scroll( carouselData, 1 ) );

		let scrollTimeout;
		content.addEventListener( 'scroll', () => {
			clearTimeout( scrollTimeout );
			scrollTimeout = setTimeout( () => {
				liquipedia.carousel.updateButtonVisibility( carouselData );
			}, 50 );
		} );
	},

	scroll: function( carouselData, direction ) {
		const offset = carouselData.itemWidth * direction;

		carouselData.content.scrollBy( {
			left: offset,
			behavior: 'smooth'
		} );
	},

	updateButtonVisibility: function( carouselData ) {
		const { content, controls } = carouselData;
		const { scrollLeft, scrollWidth, clientWidth } = content;
		const maxScroll = scrollWidth - clientWidth;

		const atStart = scrollLeft <= 0;
		const atEnd = scrollLeft >= maxScroll;

		const toggleElements = ( elements, shouldHide ) => {
			elements.forEach( ( element ) => {
				if ( element ) {
					element.style.display = shouldHide ? 'none' : '';
				}
			} );
		};

		toggleElements( controls.left, atStart );
		toggleElements( controls.right, atEnd );
	},
	handleResize: function() {
		liquipedia.carousel.carousels.forEach( ( data ) => {
			if ( data.items.length > 0 ) {
				data.itemWidth = data.items[ 0 ].offsetWidth;
			}
			liquipedia.carousel.updateButtonVisibility( data );
		} );
	}
};

liquipedia.core.modules.push( 'carousel' );
