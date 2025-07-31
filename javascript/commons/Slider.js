/*******************************************************************************
 Template(s): Slider
 Author(s): Rathoz (original)
 *******************************************************************************/
const SLIDER_CHILD_ACTIVE = 'slider-value--active';
const SLIDER_CHILD_PREFIX = 'slider-value--';
const SLIDER_VALUE_LABEL = 'slider-value-label';

liquipedia.slider = {
	sliders: {},

	init: function () {
		document.querySelectorAll( '.slider' ).forEach( ( container ) => {
			if ( !this.sliders[ container.dataset.sliderid ] ) {
				this.sliders[ container.dataset.sliderid ] = container;
				this.initSlider( container );
			}
		} );
	},

	initSlider: function ( container ) {
		const sliderValue = document.createElement( 'span' );
		sliderValue.className = SLIDER_VALUE_LABEL;

		const sliderInput = document.createElement( 'input' );
		sliderInput.type = 'range';
		sliderInput.id = container.dataset.sliderid;
		sliderInput.min = container.dataset.min;
		sliderInput.max = container.dataset.max;
		sliderInput.step = container.dataset.step;
		sliderInput.value = container.dataset.value;
		sliderInput.className = 'slider-input';

		sliderInput.addEventListener( 'input', ( event ) => {
			const value = event.target.value;
			sliderInput.querySelectorAll( '.' + SLIDER_CHILD_ACTIVE ).forEach( ( valueContainer ) => {
				valueContainer.classList.remove( SLIDER_CHILD_ACTIVE );
			} );
			const containerToShow = sliderInput.querySelector( '.' + SLIDER_CHILD_PREFIX + value );
			containerToShow.classList.add( SLIDER_CHILD_ACTIVE );
			sliderValue.textContent = containerToShow.textContent;
		} );

		container.appendChild( sliderValue );
		container.appendChild( sliderInput );
	}
}

liquipedia.core.modules.push( 'slider' );
