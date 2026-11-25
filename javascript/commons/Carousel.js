/**
 * A `.carousel` element holds the scroll controls (`.carousel-button--left/right`, optional `.carousel-fade--*`)
 * and one or more `.carousel-content` elements containing `.carousel-item`s.
 *
 * The controls act on whichever `.carousel-content` is currently displayed. This allows the controls to be placed
 * apart from the content (e.g. in a panel header), to drive several contents of which only one is shown at a time
 * (e.g. inside a toggle area) and to keep working when the content is replaced (e.g. by filter buttons).
 *
 * Set `data-carousel-controls="disable"` on the `.carousel` element to disable the buttons at either end instead of
 * hiding them.
 */
class LiquipediaCarousel {
	/**
	 * @type {LiquipediaCarousel[]}
	 */
	static carousels = [];

	static resizeListenerAdded = false;

	static refreshScheduled = false;

	static scheduleRefresh() {
		if ( LiquipediaCarousel.refreshScheduled ) {
			return;
		}
		LiquipediaCarousel.refreshScheduled = true;
		const requestFrame = window.requestAnimationFrame || ( ( cb ) => setTimeout( cb, 0 ) );
		requestFrame( () => {
			LiquipediaCarousel.refreshScheduled = false;
			LiquipediaCarousel.handleResize();
		} );
	}

	static init() {
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
				resizeTimeout = setTimeout( LiquipediaCarousel.handleResize, 150 );
			} );
			LiquipediaCarousel.resizeListenerAdded = true;
		}

		// Content of already initialized carousels may have been replaced
		LiquipediaCarousel.scheduleRefresh();
	}

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

		if ( !this.controls.left[ 0 ] || !this.controls.right[ 0 ] ) {
			return;
		}

		carousel.dataset.carouselInitialized = 'true';
		this.disableControls = carousel.dataset.carouselControls === 'disable';

		LiquipediaCarousel.carousels.push( this );
		this.updateButtonVisibility();

		LiquipediaCarousel.bindActivation( this.controls.left[ 0 ], () => this.scroll( -1 ) );
		LiquipediaCarousel.bindActivation( this.controls.right[ 0 ], () => this.scroll( 1 ) );

		// Scroll events do not bubble, so listen in the capture phase.
		// This also covers content that is inserted after initialization.
		let scrollTimeout;
		carousel.addEventListener( 'scroll', ( event ) => {
			if ( !this.ownsContent( event.target ) ) {
				return;
			}
			clearTimeout( scrollTimeout );
			scrollTimeout = setTimeout( () => {
				this.updateButtonVisibility();
			}, 50 );
		}, true );

		// Switching tabs of a toggle area changes which content is displayed
		carousel.addEventListener( 'click', ( event ) => {
			if ( event.target instanceof Element && event.target.closest( '.toggle-area-button' ) ) {
				LiquipediaCarousel.scheduleRefresh();
			}
		} );

		// If the carousel is initialized while hidden (e.g. inside a collapsible or content switch),
		// its measurements are 0. Observe size changes so it self-heals once it becomes visible.
		const ro = new ResizeObserver( LiquipediaCarousel.scheduleRefresh );
		ro.observe( carousel );
		this.resizeObserver = ro;
	}

	/**
	 * Activate a control by pointer and keyboard.
	 * The controls are `role="button"` elements, as MediaWiki does not allow `<button>`, so Enter and Space are
	 * handled here the way a native button does: Enter on keydown, Space on keyup (only if it was also pressed on
	 * the control), without Space scrolling the page.
	 *
	 * @param {HTMLElement} element
	 * @param {function(): void} callback
	 */
	static bindActivation( element, callback ) {
		const activate = () => {
			if ( element.getAttribute( 'aria-disabled' ) !== 'true' ) {
				callback();
			}
		};
		element.addEventListener( 'click', activate );

		// Native buttons already turn Enter and Space into clicks
		if ( element instanceof HTMLButtonElement ) {
			return;
		}

		let spacePressed = false;
		element.addEventListener( 'keydown', ( event ) => {
			if ( event.key === 'Enter' ) {
				event.preventDefault();
				activate();
			} else if ( event.key === ' ' ) {
				event.preventDefault();
				spacePressed = true;
			}
		} );
		element.addEventListener( 'keyup', ( event ) => {
			if ( event.key === ' ' && spacePressed ) {
				event.preventDefault();
				spacePressed = false;
				activate();
			}
		} );
		element.addEventListener( 'blur', () => {
			spacePressed = false;
		} );
	}

	/**
	 * @param {EventTarget} element
	 * @return {boolean}
	 */
	ownsContent( element ) {
		return element instanceof Element &&
			element.classList.contains( 'carousel-content' ) &&
			element.closest( '.carousel' ) === this.carouselElement;
	}

	/**
	 * The content currently displayed, falling back to the first one.
	 *
	 * @return {HTMLElement?}
	 */
	getContent() {
		const contents = Array.from( this.carouselElement.querySelectorAll( '.carousel-content' ) )
			.filter( ( content ) => this.ownsContent( content ) );
		return contents.find( ( content ) => content.getClientRects().length > 0 ) ?? contents[ 0 ] ?? null;
	}

	scroll( direction ) {
		const content = this.getContent();
		const itemWidth = content?.querySelector( '.carousel-item' )?.offsetWidth;
		if ( !itemWidth ) {
			return;
		}

		// An explicit 'smooth' would override the reduced-motion handling in CSS
		const prefersReducedMotion = window.matchMedia( '(prefers-reduced-motion: reduce)' ).matches;
		content.scrollBy( {
			left: itemWidth * direction,
			behavior: prefersReducedMotion ? 'instant' : 'smooth'
		} );
	}

	updateButtonVisibility() {
		const content = this.getContent();
		let atStart = true;
		let atEnd = true;
		if ( content ) {
			const { scrollLeft, scrollWidth, clientWidth } = content;
			atStart = scrollLeft <= 0;
			atEnd = scrollLeft >= scrollWidth - clientWidth;
		}

		// Read before toggling: hiding a focused control drops focus to the document
		const focused = document.activeElement;
		this.toggleControls( this.controls.left, atStart );
		this.toggleControls( this.controls.right, atEnd );
		this.redirectFocus( focused, atStart, atEnd );
	}

	/**
	 * Keep focus within the controls when the focused one becomes inactive at either end.
	 *
	 * @param {Element?} focused
	 * @param {boolean} atStart
	 * @param {boolean} atEnd
	 */
	redirectFocus( focused, atStart, atEnd ) {
		const left = this.controls.left[ 0 ];
		const right = this.controls.right[ 0 ];
		if ( focused === left && atStart && !atEnd ) {
			right.focus( { preventScroll: true } );
		} else if ( focused === right && atEnd && !atStart ) {
			left.focus( { preventScroll: true } );
		}
	}

	/**
	 * @param {(HTMLElement|null)[]} elements
	 * @param {boolean} isInactive
	 */
	toggleControls( elements, isInactive ) {
		elements.forEach( ( element ) => {
			if ( !element ) {
				return;
			}
			if ( this.disableControls && element.classList.contains( 'carousel-button' ) ) {
				element.classList.toggle( 'carousel-button--disabled', isInactive );
				element.setAttribute( 'aria-disabled', String( isInactive ) );
				element.setAttribute( 'tabindex', isInactive ? '-1' : '0' );
				return;
			}
			element.style.display = isInactive ? 'none' : '';
		} );
	}

	static handleResize() {
		LiquipediaCarousel.carousels.forEach( ( carousel ) => {
			carousel.updateButtonVisibility();
		} );
	}
}

liquipedia.carousel = LiquipediaCarousel;
liquipedia.core.modules.push( 'carousel' );
