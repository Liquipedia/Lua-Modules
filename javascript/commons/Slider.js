/*******************************************************************************
 Template(s): Slider
 Author(s): Rathoz (original)
 *******************************************************************************/
const SLIDER_CONTAINER = 'slider';
const SLIDER_RANGE = 'slider-range';
const SLIDER_CHILD_ACTIVE = 'slider-value--active';
const SLIDER_CHILD_PREFIX = 'slider-value--';
const SLIDER_VALUE_LABEL = 'slider-value-label';

liquipedia.slider = {
	sliders: {},

	init: function () {
		document.querySelectorAll( `.${ SLIDER_CONTAINER }` ).forEach( ( container ) => {
			if ( !this.sliders[ container.dataset.id ] ) {
				this.sliders[ container.dataset.id ] = container;
				this.initSlider( container );
			}
		} );
	},

	initSlider: function ( container ) {
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

		const thumbWidth = 24; // Needs to match the CSS thumb width

		const updateSlider = function () {
			const trackWidth = sliderInput.offsetWidth - thumbWidth;
			const value = sliderInput.value;
			const percent = ( ( sliderInput.value - sliderInput.min ) / ( sliderInput.max - sliderInput.min ) );
			const leftPosition = percent * trackWidth + ( thumbWidth / 2 );
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

		const firstChild = container.firstChild;
		container.insertBefore( sliderValue, firstChild );
		container.insertBefore( sliderInput, firstChild );
		updateSlider();
	}
};

liquipedia.core.modules.push( 'slider' );
