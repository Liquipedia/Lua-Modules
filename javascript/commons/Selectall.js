/*******************************************************************************
 * Template(s): Select all for pre elements
 ******************************************************************************/

class SelectAllContainer {
	/**
	 * @param {HTMLElement} selectAllElement
	 */
	constructor( selectAllElement ) {
		this.element = selectAllElement;
	}

	createWrapper() {
		const wrapper = document.createElement( 'div' );
		wrapper.classList.add( 'selectall-wrapper' );
		const buttonWrapper = document.createElement( 'div' );
		buttonWrapper.classList.add( 'selectall-buttons' );
		wrapper.appendChild( buttonWrapper );
		this.element.parentNode.replaceChild( wrapper, this.element );
		wrapper.appendChild( this.element );
		buttonWrapper.append( this.createSelectButton(), this.createSelectAllButton() );
	}

	createSelectButton() {
		const selectButton = document.createElement( 'button' );
		selectButton.classList.add( 'btn' );
		selectButton.classList.add( 'btn-secondary' );
		selectButton.innerHTML = 'Select';
		selectButton.addEventListener( 'click', () => this.selectElementText() );
		return selectButton;
	}

	createSelectAllButton() {
		const selectCopyButton = document.createElement( 'button' );
		selectCopyButton.classList.add( 'btn' );
		selectCopyButton.classList.add( 'btn-primary' );
		selectCopyButton.innerHTML = 'Select and copy';

		selectCopyButton.addEventListener( 'click', async () => {
			if ( !window.ClipboardItem || !navigator.clipboard || !navigator.clipboard.write ) {
				mw.notify( 'This browser does not support copying text to the clipboard.', { type: 'error' } );
				return;
			}

			this.selectElementText();

			const type = 'text/plain';
			const clipboardItemData = {
				[ type ]: this.element.innerText
			};
			const clipboardItem = new ClipboardItem( clipboardItemData );
			await navigator.clipboard.write( [ clipboardItem ] );
		} );
		return selectCopyButton;
	}

	selectElementText() {
		const range = document.createRange();
		range.selectNodeContents( this.element );
		const selection = window.getSelection();
		selection.removeAllRanges();
		selection.addRange( range );
	}
}

liquipedia.selectall = {
	init: function() {
		document.querySelectorAll( '.selectall' ).forEach( ( selectall ) => {
			new SelectAllContainer( selectall ).createWrapper();
		} );
	}
};

liquipedia.core.modules.push( 'selectall' );
