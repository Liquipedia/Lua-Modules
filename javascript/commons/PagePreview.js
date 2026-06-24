/*******************************************************************************
 * Template(s): Page preview hovercards
 ******************************************************************************/

const PAGE_PREVIEW_CONFIG = {
	SELECTORS: {
		island: '#page-preview-data',
		link: '.link-preview[data-preview-page]',
		contentRoot: '#mw-content-text'
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
		} catch {
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
		// key is pre-normalized server-side by PagePreview.key (spaces → underscores); no JS normalization needed
		const key = link.getAttribute( PAGE_PREVIEW_CONFIG.ATTRIBUTES.previewPage );
		return key ? this.data.get( key ) : undefined;
	}

	bindEvents() {
		const root = document.querySelector( PAGE_PREVIEW_CONFIG.SELECTORS.contentRoot ) || document.body;
		const onOver = ( e ) => {
			const link = e.target.closest( PAGE_PREVIEW_CONFIG.SELECTORS.link );
			if ( !link || link === this.activeLink ) {
				return;
			}
			// only trigger over the actual link text (the <a>), not the surrounding
			// component box — the marker sits on a wrapper span that, in block
			// layouts, stretches well beyond the link text via flex/ellipsis.
			const anchor = e.target.closest( 'a' );
			if ( !anchor || !link.contains( anchor ) ) {
				return;
			}
			this.scheduleShow( link );
		};
		const onOut = ( e ) => {
			const link = e.target.closest( PAGE_PREVIEW_CONFIG.SELECTORS.link );
			if ( !link ) {
				return;
			}
			const to = e.relatedTarget;
			if ( to && link.contains( to ) ) {
				return;
			}
			this.scheduleHide();
		};
		root.addEventListener( 'mouseover', onOver );
		root.addEventListener( 'mouseout', onOut );
		this.cleanupFunctions.add( () => root.removeEventListener( 'mouseover', onOver ) );
		this.cleanupFunctions.add( () => root.removeEventListener( 'mouseout', onOut ) );
	}

	/**
	 * @param {HTMLElement} link
	 */
	scheduleShow( link ) {
		window.clearTimeout( this.hideTimer );
		window.clearTimeout( this.showTimer );
		this.warmImage( link );
		this.showTimer = window.setTimeout( () => this.show( link ), this.HOVER_INTENT_MS );
	}

	/**
	 * Start fetching the card image during the hover-intent delay so it is
	 * usually decoded by the time the card renders, avoiding a flash-in.
	 *
	 * @param {HTMLElement} link
	 */
	warmImage( link ) {
		const card = this.getCard( link );
		if ( card && card.image ) {
			const img = new Image();
			img.src = card.image;
		}
	}

	scheduleHide() {
		window.clearTimeout( this.showTimer );
		window.clearTimeout( this.hideTimer );
		this.hideTimer = window.setTimeout( () => this.hide(), this.HIDE_GRACE_MS );
	}

	/**
	 * @param {HTMLElement} link
	 */
	show( link ) {
		const card = this.getCard( link );
		if ( !card ) {
			return;
		}
		this.activeLink = link;
		this.render( card );
		this.position( link );
	}

	hide() {
		if ( this.card ) {
			this.card.style.display = 'none';
		}
		this.activeLink = null;
	}

	/**
	 * @return {HTMLElement}
	 */
	ensureCard() {
		if ( this.card ) {
			return this.card;
		}
		const el = document.createElement( 'div' );
		el.className = 'page-preview-card';
		// the card is purely a passive display surface — no hover listeners, so it
		// dismisses as soon as the cursor leaves the link (not Wikipedia-style sticky)
		document.body.appendChild( el );
		this.card = el;
		this.cleanupFunctions.add( () => el.remove() );
		return el;
	}

	/**
	 * @param {*} value
	 * @return {string}
	 */
	escapeHtml( value ) {
		return String( value )
			.replace( /&/g, '&amp;' )
			.replace( /</g, '&lt;' )
			.replace( />/g, '&gt;' )
			.replace( /"/g, '&quot;' );
	}

	/**
	 * @param {Object} card
	 * @return {string}
	 */
	template( card ) {
		const e = ( v ) => this.escapeHtml( v );
		const img = card.image ?
			`<img class="page-preview-card__image" src="${ e( card.image ) }" alt="">` : '';
		// row order mirrors the player infobox: Nationality, Born, Status, Role, Team, Earnings
		const rows = [];
		const addRow = ( label, value ) => {
			if ( label && value ) {
				rows.push( { label, value } );
			}
		};
		addRow( 'Nationality', card.flag );
		addRow( 'Born', card.born );
		addRow( 'Status', card.status );
		addRow( 'Role', card.role );
		addRow( 'Team', card.team );
		addRow( 'Earnings', card.earnings && `$${ Number( card.earnings ).toLocaleString( 'en-US' ) }` );
		// wiki-specific extra fields (declared in Info.config.pagePreview); plain text, escaped like the rest
		if ( Array.isArray( card.extra ) ) {
			card.extra.forEach( ( field ) => field && addRow( field.label, field.value ) );
		}
		// render the fields as a Table2 (reuses the already-bundled .table2 styles):
		// bold key header cell, right-aligned value, striped rows. The even-row class
		// is set here because Table2.js only stripes tables present at page init, not
		// this card which is built on hover.
		const rowsHtml = rows.map( ( row, i ) => {
			const even = i % 2 === 1 ? ' table2__row--even' : '';
			return `<tr class="table2__row--body${ even }">` +
				`<th>${ e( row.label ) }</th>` +
				`<td data-align="right">${ e( row.value ) }</td></tr>`;
		} ).join( '' );
		const table = rowsHtml ?
			`<div class="table2"><table class="table2__table"><tbody>${ rowsHtml }</tbody></table></div>` : '';
		return img + '<div class="page-preview-card__body">' +
			`<div class="page-preview-card__name">${ e( card.name ) }</div>` +
			( card.realName ? `<div class="page-preview-card__subtitle">${ e( card.realName ) }</div>` : '' ) +
			table + '</div>';
	}

	/**
	 * @param {Object} card
	 */
	render( card ) {
		const el = this.ensureCard();
		el.innerHTML = this.template( card );
		el.style.display = 'block';
	}

	/**
	 * @param {HTMLElement} link
	 */
	position( link ) {
		const el = this.card;
		const rect = link.getBoundingClientRect();
		el.style.position = 'absolute';
		el.style.top = `${ window.scrollY + rect.bottom + 8 }px`;
		el.style.left = `${ window.scrollX + rect.left }px`;
		// viewport flip: if the card would overflow the bottom, place it above the link
		const cardRect = el.getBoundingClientRect();
		if ( rect.bottom + cardRect.height + 8 > window.innerHeight && rect.top - cardRect.height - 8 > 0 ) {
			el.style.top = `${ window.scrollY + rect.top - cardRect.height - 8 }px`;
		}
	}

	destroy() {
		window.clearTimeout( this.showTimer );
		window.clearTimeout( this.hideTimer );
		this.cleanupFunctions.forEach( ( fn ) => fn() );
		this.cleanupFunctions.clear();
		this.card = null;
		this.activeLink = null;
	}

}

liquipedia.pagePreview = new PagePreviewModule();
liquipedia.core.modules.push( 'pagePreview' );
