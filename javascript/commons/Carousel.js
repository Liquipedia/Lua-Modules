liquipedia.carousel = {
	carousels: [],
	resizeListenerAdded: false,
	refreshScheduled: false,

	scheduleRefresh: function() {
		if ( liquipedia.carousel.refreshScheduled ) {
			return;
		}
		liquipedia.carousel.refreshScheduled = true;
		const requestFrame = window.requestAnimationFrame || ( ( cb ) => setTimeout( cb, 0 ) );
		requestFrame( () => {
			liquipedia.carousel.refreshScheduled = false;
			liquipedia.carousel.handleResize();
		} );
	},

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
		if ( carousel.dataset.carouselInitialized === 'true' ) {
			return;
		}

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

		carousel.dataset.carouselInitialized = 'true';

		// Single item carousels don't need scroll tracking or button handlers
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

		// If the carousel is initialized while hidden (e.g. inside a collapsible or content switch),
		// its measurements are 0. Observe size changes so it self-heals once it becomes visible.
		const ro = new ResizeObserver( () => {
			liquipedia.carousel.scheduleRefresh();
		} );
		ro.observe( carouselData.content );
		carouselData.resizeObserver = ro;
	},

	scroll: function( carouselData, direction ) {
		if ( !carouselData.itemWidth && carouselData.items.length > 0 ) {
			carouselData.itemWidth = carouselData.items[ 0 ].offsetWidth;
			liquipedia.carousel.updateButtonVisibility( carouselData );
		}
		if ( !carouselData.itemWidth ) {
			return;
		}

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
