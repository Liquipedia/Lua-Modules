class LiquipediaCarousel {
	/**
	 * @param {HTMLElement} element
	 */
	constructor( element ) {
		this.carouselElement = element;
	}

	isInitialized() {
		return this.carouselElement.dataset.carouselInitialized === 'true';
	}

	initialize() {
		if ( this.isInitialized() ) {
			return;
		}

		const carousel = this.carouselElement;

		this.content = carousel.querySelector( '.carousel-content' );
		this.items = carousel.querySelectorAll( '.carousel-item' );

		this.controls = {
			left: [
				carousel.querySelector( '.carousel-button--left' ),
				carousel.querySelector( '.carousel-fade--left' )
			],
			right: [
				carousel.querySelector( '.carousel-button--right' ),
				carousel.querySelector( '.carousel-fade--right' )
			]
		};

		if ( !this.content || !this.items.length || !this.controls.left[ 0 ] || !this.controls.right[ 0 ] ) {
			return;
		}

		carousel.dataset.carouselInitialized = 'true';

		// Single item carousels don't need scroll tracking or button handlers
		if ( this.items.length === 1 ) {
			[ ...this.controls.left, ...this.controls.right ].forEach( ( element ) => {
				if ( element ) {
					element.style.display = 'none';
				}
			} );
			return;
		}

		this.itemWidth = this.items[ 0 ].offsetWidth;

		liquipedia.carousel.carousels.push( this );
		this.updateButtonVisibility();

		this.controls.left[ 0 ].addEventListener( 'click', () => this.scroll( -1 ) );
		this.controls.right[ 0 ].addEventListener( 'click', () => this.scroll( 1 ) );

		let scrollTimeout;
		this.content.addEventListener( 'scroll', () => {
			clearTimeout( scrollTimeout );
			scrollTimeout = setTimeout( () => {
				this.updateButtonVisibility();
			}, 50 );
		} );

		// If the carousel is initialized while hidden (e.g. inside a collapsible or content switch),
		// its measurements are 0. Observe size changes so it self-heals once it becomes visible.
		const ro = new ResizeObserver( liquipedia.carousel.scheduleRefresh );
		ro.observe( this.content );
		this.resizeObserver = ro;
	}

	scroll( direction ) {
		if ( !this.itemWidth && this.items.length > 0 ) {
			this.itemWidth = this.items[ 0 ].offsetWidth;
			this.updateButtonVisibility();
		}
		if ( !this.itemWidth ) {
			return;
		}

		const offset = this.itemWidth * direction;

		this.content.scrollBy( {
			left: offset,
			behavior: 'smooth'
		} );
	}

	updateButtonVisibility() {
		const { scrollLeft, scrollWidth, clientWidth } = this.content;
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

		toggleElements( this.controls.left, atStart );
		toggleElements( this.controls.right, atEnd );
	}
}

liquipedia.carousel = {
	/**
	 * @type {LiquipediaCarousel[]}
	 */
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
			new LiquipediaCarousel( carousel ).initialize();
		} );

		if ( !LiquipediaCarousel.resizeListenerAdded ) {
			let resizeTimeout;
			window.addEventListener( 'resize', () => {
				clearTimeout( resizeTimeout );
				resizeTimeout = setTimeout( liquipedia.carousel.handleResize, 150 );
			} );
			LiquipediaCarousel.resizeListenerAdded = true;
		}
	},

	handleResize: function() {
		liquipedia.carousel.carousels.forEach( ( data ) => {
			if ( data.items.length > 0 ) {
				data.itemWidth = data.items[ 0 ].offsetWidth;
			}
			data.updateButtonVisibility();
		} );
	}
};
liquipedia.core.modules.push( 'carousel' );
