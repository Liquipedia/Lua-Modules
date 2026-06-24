/*******************************************************************************
 * Template(s): Page preview hovercards
 ******************************************************************************/

const PAGE_PREVIEW_CONFIG = {
	SELECTORS: {
		island: '#page-preview-data',
		link: '.link-preview[data-preview-page]'
	},
	ATTRIBUTES: {
		previewData: 'data-preview',
		previewPage: 'data-preview-page'
	},
	MEDIA: {
		desktopPointer: '(hover: hover) and (pointer: fine)'
	}
};

class PagePreviewModule {
	constructor() {
		this.HOVER_INTENT_MS = 150;
		this.HIDE_GRACE_MS = 100;
		this.data = new Map();
		this.card = null;
		this.activeLink = null;
		this.showTimer = null;
		this.hideTimer = null;
		this.cleanupFunctions = new Set();
	}

	init() {
		if ( !window.matchMedia || !window.matchMedia( PAGE_PREVIEW_CONFIG.MEDIA.desktopPointer ).matches ) {
			return;
		}
		this.loadData();
		if ( this.data.size === 0 ) {
			return;
		}
		this.bindEvents();
	}

	loadData() {
		const island = document.querySelector( PAGE_PREVIEW_CONFIG.SELECTORS.island );
		if ( !island ) {
			return;
		}
		let parsed;
		try {
			parsed = JSON.parse( island.getAttribute( PAGE_PREVIEW_CONFIG.ATTRIBUTES.previewData ) );
		} catch ( e ) {
			return;
		}
		if ( !parsed ) {
			return;
		}
		Object.keys( parsed ).forEach( ( key ) => this.data.set( key, parsed[ key ] ) );
	}

	/**
	 * @param {HTMLElement} link
	 * @return {object|undefined}
	 */
	getCard( link ) {
		const key = link.getAttribute( PAGE_PREVIEW_CONFIG.ATTRIBUTES.previewPage );
		return key ? this.data.get( key ) : undefined;
	}

	bindEvents() {
		// implemented in Task 5
	}

}

liquipedia.pagePreview = new PagePreviewModule();
liquipedia.core.modules.push( 'pagePreview' );
