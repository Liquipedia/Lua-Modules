/*******************************************************************************
 Template(s): Slider
 Author(s): Rathoz (original)
 *******************************************************************************/
const SLIDER_INIT = 'slider';
const SLIDER_RANGE_CONTAINER = 'slider-range-container';
const SLIDER_RANGE = 'slider-range';
const SLIDER_CHILD_ACTIVE = 'slider-value--active';
const SLIDER_CHILD_PREFIX = 'slider-value--';
const SLIDER_VALUE_LABEL = 'slider-value-label';

const THUMB_WIDTH = 24; // Needs to match the CSS thumb width in pixels
const SLIDER_PADDING = 48; // Needs the padding, including +/- buttons
const FIXED_WIDTHS = THUMB_WIDTH + SLIDER_PADDING * 2; // Total width of the slider thumb and padding

liquipedia.slider = {
	sliders: {},

	init: function () {
		document.querySelectorAll( `.${ SLIDER_INIT }` ).forEach( ( container ) => {
			if ( !this.sliders[ container.dataset.id ] ) {
				this.sliders[ container.dataset.id ] = container;
				this.initSlider( container );
			}
		} );
	},

	initSlider: function ( container ) {
		const makeButton = ( faIcon ) => {
			const button = document.createElement( 'div' );
			button.className = `btn btn-tertiary btn-extrasmall fas fa-${ faIcon }`;
			return button;
		};

		const sliderValue = document.createElement( 'span' );
		sliderValue.className = SLIDER_VALUE_LABEL;

		const sliderInput = document.createElement( 'input' );
		sliderInput.type = 'range';
		sliderInput.id = container.dataset.id;
		sliderInput.min = container.dataset.min;
		sliderInput.max = container.dataset.max;
		sliderInput.step = container.dataset.step;
		sliderInput.value = container.dataset.value;
		sliderInput.className = SLIDER_RANGE;

		const updateSlider = function () {
			const trackWidth = sliderInput.offsetWidth - THUMB_WIDTH;
			const value = sliderInput.value;
			const percent = ( ( sliderInput.value - sliderInput.min ) / ( sliderInput.max - sliderInput.min ) );
			const leftPosition = percent * trackWidth + ( FIXED_WIDTHS / 2 );
			sliderInput.style.setProperty( '--progress-fill', `${ percent * 100 }%` );
			sliderValue.style.setProperty( 'left', leftPosition + 'px' );

			container.querySelectorAll( `.${ SLIDER_CHILD_ACTIVE }` ).forEach( ( valueContainer ) => {
				valueContainer.classList.remove( SLIDER_CHILD_ACTIVE );
			} );

			const containerToShow = container.querySelector( `.${ SLIDER_CHILD_PREFIX }${ value }` );
			if ( containerToShow !== null ) {
				containerToShow.classList.add( SLIDER_CHILD_ACTIVE );
				sliderValue.textContent = containerToShow.dataset.title || value;
			} else {
				sliderValue.textContent = value;
			}

		};

		sliderInput.addEventListener( 'input', () => {
			updateSlider();
		} );

		const plusButton = makeButton( 'plus' );
		plusButton.addEventListener( 'click', () => {
			const value = parseInt( sliderInput.value );
			const max = parseInt( sliderInput.max );
			const step = parseInt( sliderInput.step );
			if ( value < max ) {
				sliderInput.value = ( value + step );
				updateSlider();
			}
		} );

		const minusButton = makeButton( 'minus' );
		minusButton.addEventListener( 'click', () => {
			const value = parseInt( sliderInput.value );
			const min = parseInt( sliderInput.min );
			const step = parseInt( sliderInput.step );
			if ( value > min ) {
				sliderInput.value = ( value - step );
				updateSlider();
			}
		} );

		const firstChild = container.firstChild;
		const sliderContainer = document.createElement( 'div' );
		sliderContainer.className = SLIDER_RANGE_CONTAINER;
		container.insertBefore( sliderContainer, firstChild );

		sliderContainer.appendChild( sliderValue );
		sliderContainer.appendChild( minusButton );
		sliderContainer.appendChild( sliderInput );
		sliderContainer.appendChild( plusButton );
		updateSlider();
	}
};

liquipedia.core.modules.push( 'slider' );
