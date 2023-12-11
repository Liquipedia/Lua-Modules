/*******************************************************************************
 * Template(s): Select all for pre elements
 * Author(s): FO-nTTaX
 ******************************************************************************/
liquipedia.selectall = {
	init: function() {
		document.querySelectorAll( '.selectall' ).forEach( function( selectall ) {
			var wrapper = document.createElement( 'div' );
			wrapper.classList.add( 'selectall-wrapper' );
			var buttonwrapper = document.createElement( 'div' );
			buttonwrapper.classList.add( 'selectall-buttons' );
			wrapper.appendChild( buttonwrapper );
			var relative = document.createElement( 'div' );
			relative.classList.add( 'selectall-relative' );
			wrapper.appendChild( relative );
			selectall.parentNode.replaceChild( wrapper, selectall );
			relative.appendChild( selectall );
			var selectbutton = document.createElement( 'button' );
			selectbutton.innerHTML = 'Select';
			selectbutton.onclick = function() {
				liquipedia.selectall.selectText( this );
			};
			buttonwrapper.appendChild( selectbutton );
			buttonwrapper.appendChild( document.createTextNode( ' ' ) );
			var selectcopybutton = document.createElement( 'button' );
			selectcopybutton.innerHTML = 'Select and copy';
			selectcopybutton.onclick = function() {
				liquipedia.selectall.selectText( this );
				document.execCommand( 'copy' );
			};
			buttonwrapper.appendChild( selectcopybutton );
		} );
	},
	removeTextarea: function() {
		this.parentNode.removeChild( this );
	},
	selectText: function( button ) {
		var wrapper = button.closest( '.selectall-wrapper' );
		var selectall = wrapper.querySelector( '.selectall' );
		var textarea = document.createElement( 'textarea' );
		textarea.readOnly = true;
		textarea.classList.add( 'selectall-duplicate' );
		textarea.innerHTML = selectall.innerHTML;
		textarea.style.padding = window.getComputedStyle( selectall ).padding;
		textarea.style.lineHeight = window.getComputedStyle( selectall ).lineHeight;
		textarea.style.fontFamily = window.getComputedStyle( selectall ).fontFamily;
		textarea.style.fontSize = window.getComputedStyle( selectall ).fontSize;
		textarea.style.height = window.getComputedStyle( selectall ).height;
		textarea.onblur = liquipedia.selectall.removeTextarea;
		wrapper.querySelector( '.selectall-relative' ).appendChild( textarea );
		textarea.focus();
		textarea.select();
	}
};
liquipedia.core.modules.push( 'selectall' );
