/* global snapdom */

/*******************************************************************************
 * Description: Adds export functionality to Liquipedia pages, enabling users
 *              to copy or download brackets, group tables, prize pools,
 *              standings, participant lists and other tables as images.
 ******************************************************************************/

const EXPORT_IMAGE_CONFIG = {
	LOGOS: {
		DARK: 'https://liquipedia.net/commons/images/f/ff/Liquipedia_default_darkmode_export.png',
		LIGHT: 'https://liquipedia.net/commons/images/9/9a/Liquipedia_default_lightmode_export.png'
	},
	DIMENSIONS: {
		HEADER_HEIGHT: 43,
		FOOTER_HEIGHT: 33,
		PADDING: 12,
		BORDER_RADIUS: 4,
		LOGO_WIDTH: 22,
		LOGO_HEIGHT: 16,
		LOGO_OFFSET_X: 12,
		LOGO_OFFSET_Y_ADJUST: 2,
		TEXT_OFFSET_X: 40,
		HEADER_TEXT_OFFSET: 16,
		MIN_WIDTH: 300
	},
	FONTS: {
		HEADER: 'bold 14px Open Sans, sans-serif',
		SUBHEADER: '500 14px Open Sans, sans-serif',
		FOOTER: 'bold 9px Open Sans, sans-serif'
	},
	SPACING: {
		DROPDOWN_MARGIN: '10px',
		ICON_MARGIN: '0.25rem',
		LETTER_SPACING: 1.8
	},
	TIMEOUTS: {
		IMAGE_LOAD: 5000,
		URL_REVOKE_DELAY: 100,
		STYLESHEET_LOAD: 10000,
		FONT_READY: 5000
	},
	CAPTURE: {
		// Responsive layout is driven by viewport media queries, so exports are
		// rendered in a frame of this width instead of the reader's window.
		LAYOUT_WIDTH: 1440,
		// snapdom clamps its SVG raster to this many pixels per side.
		MAX_RASTER_SIDE: 16384,
		// Fixed so exports match on every display. Two keeps text crisp and leaves
		// the most headroom under the raster limit.
		SCALE: 2,
		TARGET_ATTRIBUTE: 'data-export-target'
	},
	COLORS: {
		DARK: {
			BACKGROUND: '#121212',
			HEADER_START: '#1b63a3',
			HEADER_END: '#0a253d',
			FOOTER_START: 'rgba(255,255,255,0.08)',
			FOOTER_END: 'rgba(255,255,255,0)',
			TEXT: '#ffffff'
		},
		LIGHT: {
			BACKGROUND: '#fdfcff',
			HEADER_START: '#0a253d',
			HEADER_END: '#1b63a3',
			FOOTER_START: 'rgba(0,0,0,0.1)',
			FOOTER_END: 'rgba(0,0,0,0)',
			TEXT: '#181818'
		}
	},
	SELECTORS: [
		{ selector: '.brkts-bracket-wrapper', targetSelector: '.brkts-bracket', typeName: 'Bracket' },
		{
			selector: '.group-table, .grouptable',
			targetSelector: null,
			typeName: 'Group Table',
			titleSelector: '.group-table-title'
		},
		{ selector: '.crosstable', targetSelector: 'tbody', typeName: 'Crosstable' },
		{ selector: '.brkts-matchlist', targetSelector: '.brkts-matchlist-collapse-area', typeName: 'Match List' },
		{
			selector: '.prizepool-table-wrapper:has( .prizepooltable-placement )',
			targetSelector: null,
			typeName: 'Prize Pool'
		},
		{
			selector: '.prizepool-table-wrapper:has( .prizepooltable-award )',
			targetSelector: null,
			typeName: 'Awards',
			manualSubtitle: 'Awards'
		},
		{
			selector: '.team-participant__grid, [class*="teamcard-columns"], .participantTable, .rts-team-list',
			targetSelector: null,
			typeName: 'Participants'
		},
		{
			selector: '.table2.standings-ffa',
			targetSelector: 'table.table2__table',
			titleSelector: '.table2__title',
			typeName: 'BR/FFA Standings Table'
		},
		{
			selector: '.table2.standings-swiss',
			targetSelector: 'table.table2__table',
			titleSelector: '.table2__title',
			typeName: 'Swiss Standings Table'
		},
		{
			selector: '.table2#MvpTable',
			targetSelector: '.table2__container',
			titleSelector: '.table2__title',
			typeName: 'MVP Table'
		}
	]
};

class ImageCache {
	constructor() {
		this.cache = new Map();
	}

	async load( url, key, timeout = EXPORT_IMAGE_CONFIG.TIMEOUTS.IMAGE_LOAD ) {
		if ( this.cache.has( key ) ) {
			return this.cache.get( key );
		}

		return new Promise( ( resolve, reject ) => {
			const image = new Image();
			image.crossOrigin = 'Anonymous';

			const timeoutId = setTimeout( () => {
				image.src = ''; // Cancel image load
				reject( new Error( `Image load timeout: ${ url }` ) );
			}, timeout );

			const cleanup = () => clearTimeout( timeoutId );

			image.onload = () => {
				cleanup();
				this.cache.set( key, image );
				resolve( image );
			};

			image.onerror = () => {
				cleanup();
				reject( new Error( `Image load failed: ${ url }` ) );
			};

			image.src = url;
		} );
	}

	clear() {
		this.cache.clear();
	}
}

class CanvasComposer {
	constructor( imageCache ) {
		this.imageCache = imageCache;
		this.offscreenContext = null;
	}

	async compose( sourceCanvas, sectionTitle, isDarkTheme, scale = 1, contentBackground = null ) {
		const dims = this.getScaledDimensions( scale );
		const fonts = this.getScaledFonts( scale );

		const contentWidth = sourceCanvas.width + ( dims.PADDING * 2 );
		const canvasWidth = Math.max( contentWidth, dims.MIN_WIDTH );

		const headerLayout = this.calculateHeaderLayout( canvasWidth, sectionTitle, scale, fonts, dims );
		const canvas = this.createCanvas( sourceCanvas, headerLayout.height, canvasWidth, dims );
		const context = canvas.getContext( '2d' );
		const theme = isDarkTheme ? EXPORT_IMAGE_CONFIG.COLORS.DARK : EXPORT_IMAGE_CONFIG.COLORS.LIGHT;

		this.drawBackground( context, canvas.width, canvas.height, theme );
		this.drawHeader( context, canvas.width, theme, headerLayout, fonts, dims );
		this.drawContent( context, sourceCanvas, headerLayout.height, dims, contentBackground );
		await this.drawFooter(
			context, canvas.width, sourceCanvas.height, theme, isDarkTheme, headerLayout.height, fonts, dims
		);

		return canvas;
	}

	getScaledDimensions( scale ) {
		const dims = {};
		for ( const [ key, value ] of Object.entries( EXPORT_IMAGE_CONFIG.DIMENSIONS ) ) {
			dims[ key ] = typeof value === 'number' ? value * scale : value;
		}
		return dims;
	}

	getScaledFonts( scale ) {
		const fonts = {};
		for ( const [ key, fontString ] of Object.entries( EXPORT_IMAGE_CONFIG.FONTS ) ) {
			fonts[ key ] = this.scaleFontSize( fontString, scale );
		}
		return fonts;
	}

	scaleFontSize( fontString, scale ) {
		return fontString.replace( /(\d+)px/, ( _match, pixels ) => {
			const scaledPixels = parseInt( pixels ) * scale;
			return `${ scaledPixels }px`;
		} );
	}

	getOffscreenContext() {
		if ( !this.offscreenContext ) {
			const canvas = document.createElement( 'canvas' );
			this.offscreenContext = canvas.getContext( '2d' );
		}
		return this.offscreenContext;
	}

	createCanvas( sourceCanvas, headerHeight, width, dims ) {
		const canvas = document.createElement( 'canvas' );
		canvas.width = width;
		canvas.height = sourceCanvas.height + headerHeight + dims.FOOTER_HEIGHT + ( dims.PADDING * 4 );
		return canvas;
	}

	drawBackground( context, width, height, theme ) {
		context.fillStyle = theme.BACKGROUND;
		context.fillRect( 0, 0, width, height );
	}

	drawHeader( context, canvasWidth, theme, headerLayout, fonts, dims ) {
		const gradient = context.createLinearGradient( dims.PADDING, 0, canvasWidth - dims.PADDING, 0 );
		gradient.addColorStop( 0, theme.HEADER_START );
		gradient.addColorStop( 1, theme.HEADER_END );

		context.fillStyle = gradient;
		this.drawRoundedRect(
			context,
			dims.PADDING,
			dims.PADDING,
			canvasWidth - ( dims.PADDING * 2 ),
			headerLayout.height,
			dims.BORDER_RADIUS
		);
		context.fill();

		context.fillStyle = '#ffffff';
		context.textBaseline = 'middle';

		if ( headerLayout.isStacked ) {
			this.drawStackedHeader( context, headerLayout, fonts, dims );
		} else {
			this.drawHorizontalHeader( context, headerLayout, canvasWidth, fonts, dims );
		}
	}

	drawStackedHeader( context, headerLayout, fonts, dims ) {
		context.textAlign = 'left';
		const lineHeight = 18 * ( dims.PADDING / 12 ); // Scale lineHeight with dims
		const totalLines = headerLayout.mainTitleLines.length + headerLayout.sectionTitleLines.length;
		let currentY = dims.PADDING + ( headerLayout.height - ( ( totalLines - 1 ) * lineHeight ) ) / 2;

		context.font = fonts.HEADER;
		for ( const line of headerLayout.mainTitleLines ) {
			context.fillText( line, dims.PADDING + dims.HEADER_TEXT_OFFSET, currentY );
			currentY += lineHeight;
		}

		context.font = fonts.SUBHEADER;
		for ( const line of headerLayout.sectionTitleLines ) {
			context.fillText( line, dims.PADDING + dims.HEADER_TEXT_OFFSET, currentY );
			currentY += lineHeight;
		}
	}

	drawHorizontalHeader( context, headerLayout, canvasWidth, fonts, dims ) {
		const verticalCenter = dims.PADDING + ( headerLayout.height / 2 );

		context.textAlign = 'left';
		context.font = fonts.HEADER;
		context.fillText(
			headerLayout.mainTitleLines[ 0 ],
			dims.PADDING + dims.HEADER_TEXT_OFFSET,
			verticalCenter
		);

		context.textAlign = 'right';
		context.font = fonts.SUBHEADER;
		context.fillText(
			headerLayout.sectionTitleLines[ 0 ],
			canvasWidth - dims.PADDING - dims.HEADER_TEXT_OFFSET,
			verticalCenter
		);
	}

	drawContent( context, sourceCanvas, headerHeight, dims, contentBackground ) {
		const x = dims.PADDING;
		const y = dims.PADDING + headerHeight + dims.PADDING;

		// Fill transparent capture pixels with the page background, not the surrounding frame.
		if ( contentBackground ) {
			context.fillStyle = contentBackground;
			context.fillRect( x, y, sourceCanvas.width, sourceCanvas.height );
		}

		context.drawImage( sourceCanvas, x, y );
	}

	async drawFooter( context, canvasWidth, sourceHeight, theme, isDarkTheme, headerHeight, fonts, dims ) {
		const footerY = dims.PADDING + headerHeight + dims.PADDING + sourceHeight + dims.PADDING;

		const gradient = context.createLinearGradient( dims.PADDING, 0, canvasWidth - dims.PADDING, 0 );
		gradient.addColorStop( 0, theme.FOOTER_START );
		gradient.addColorStop( 1, theme.FOOTER_END );

		context.fillStyle = gradient;
		this.drawRoundedRect(
			context,
			dims.PADDING,
			footerY,
			canvasWidth - ( dims.PADDING * 2 ),
			dims.FOOTER_HEIGHT,
			dims.BORDER_RADIUS
		);
		context.fill();

		context.fillStyle = theme.TEXT;
		context.font = fonts.FOOTER;
		context.textAlign = 'left';
		const textY = footerY + ( dims.FOOTER_HEIGHT / 2 );

		this.drawTextWithSpacing(
			context,
			'POWERED BY LIQUIPEDIA',
			dims.PADDING + dims.TEXT_OFFSET_X,
			textY,
			EXPORT_IMAGE_CONFIG.SPACING.LETTER_SPACING * ( dims.LOGO_WIDTH / 22 )
		);

		// A missing logo must not prevent the export.
		try {
			await this.drawLogo( context, footerY, isDarkTheme, dims );
		} catch ( error ) {
			// eslint-disable-next-line no-console
			console.warn( 'Logo rendering failed:', error );
		}
	}

	calculateHeaderLayout( canvasWidth, sectionTitle, scale, fonts, dims ) {
		const availableWidth = canvasWidth - ( dims.PADDING * 2 ) - ( dims.HEADER_TEXT_OFFSET * 2 );
		const mainTitle = mw.config.get( 'wgDisplayTitle' ) || mw.config.get( 'wgTitle' );

		const context = this.getOffscreenContext();

		context.font = fonts.HEADER;
		const mainTitleWidth = context.measureText( mainTitle ).width;

		context.font = fonts.SUBHEADER;
		const sectionTitleWidth = context.measureText( sectionTitle ).width;

		const totalTextWidth = mainTitleWidth + sectionTitleWidth + ( dims.HEADER_TEXT_OFFSET * 2 );
		const sideBySideAvailableWidth = canvasWidth - ( dims.PADDING * 2 ) - dims.TEXT_OFFSET_X;

		if ( totalTextWidth <= sideBySideAvailableWidth ) {
			return {
				height: dims.HEADER_HEIGHT,
				isStacked: false,
				mainTitleLines: [ mainTitle ],
				sectionTitleLines: [ sectionTitle ]
			};
		}

		const mainTitleLines = this.wrapText( context, mainTitle, availableWidth, fonts.HEADER );
		const sectionTitleLines = this.wrapText( context, sectionTitle, availableWidth, fonts.SUBHEADER );

		const lineHeight = 18 * scale;
		const verticalPadding = 12 * scale;
		const calculatedHeight = Math.max(
			dims.HEADER_HEIGHT,
			( ( mainTitleLines.length + sectionTitleLines.length ) * lineHeight ) + verticalPadding
		);

		return {
			height: calculatedHeight,
			isStacked: true,
			mainTitleLines,
			sectionTitleLines
		};
	}

	wrapText( context, text, maxWidth, font ) {
		context.font = font;
		const words = text.split( ' ' );
		const lines = [];
		let currentLine = words[ 0 ];

		for ( let i = 1; i < words.length; i++ ) {
			const testLine = `${ currentLine } ${ words[ i ] }`;
			const width = context.measureText( testLine ).width;

			if ( width <= maxWidth ) {
				currentLine = testLine;
			} else {
				lines.push( currentLine );
				currentLine = words[ i ];
			}
		}
		lines.push( currentLine );

		return lines;
	}

	async drawLogo( context, footerY, isDarkTheme, dims ) {
		const logoUrl = isDarkTheme ? EXPORT_IMAGE_CONFIG.LOGOS.DARK : EXPORT_IMAGE_CONFIG.LOGOS.LIGHT;
		const cacheKey = isDarkTheme ? 'dark' : 'light';
		const logoImage = await this.imageCache.load( logoUrl, cacheKey );
		const logoY = footerY + ( dims.FOOTER_HEIGHT - dims.LOGO_HEIGHT ) / 2;

		context.drawImage(
			logoImage,
			dims.PADDING + dims.LOGO_OFFSET_X,
			logoY,
			dims.LOGO_WIDTH,
			dims.LOGO_HEIGHT
		);
	}

	drawRoundedRect( context, x, y, width, height, radius ) {
		context.beginPath();

		if ( context.roundRect ) {
			context.roundRect( x, y, width, height, radius );
		} else {
			this.drawRoundRectFallback( context, x, y, width, height, radius );
		}

		context.closePath();
	}

	drawRoundRectFallback( context, x, y, width, height, radius ) {
		context.moveTo( x + radius, y );
		context.lineTo( x + width - radius, y );
		context.quadraticCurveTo( x + width, y, x + width, y + radius );
		context.lineTo( x + width, y + height - radius );
		context.quadraticCurveTo( x + width, y + height, x + width - radius, y + height );
		context.lineTo( x + radius, y + height );
		context.quadraticCurveTo( x, y + height, x, y + height - radius );
		context.lineTo( x, y + radius );
		context.quadraticCurveTo( x, y, x + radius, y );
	}

	drawTextWithSpacing( context, text, x, y, spacing ) {
		let cursor = x;
		for ( const character of text ) {
			context.fillText( character, cursor, y );
			cursor += context.measureText( character ).width + spacing;
		}
	}
}

/**
 * Renders exportable content in an offscreen document of a fixed width. A
 * capture reproduces the browser's existing layout, and only an iframe can
 * give it a viewport width other than the reader's.
 */
class ExportLayoutFrame {
	constructor() {
		this.iframe = null;
		this.preparePromise = null;
	}

	/**
	 * Builds the frame once, however many callers ask for it.
	 *
	 * @return {Promise<HTMLIFrameElement>}
	 */
	prepare() {
		if ( !this.preparePromise ) {
			this.preparePromise = this.build().catch( ( error ) => {
				// Start over rather than keep a half-built frame.
				this.dispose();
				throw error;
			} );
		}

		return this.preparePromise;
	}

	async build() {
		const iframe = document.createElement( 'iframe' );

		iframe.setAttribute( 'aria-hidden', 'true' );
		iframe.setAttribute( 'tabindex', '-1' );
		Object.assign( iframe.style, {
			position: 'fixed',
			top: '0',
			left: '-20000px',
			width: `${ EXPORT_IMAGE_CONFIG.CAPTURE.LAYOUT_WIDTH }px`,
			height: `${ this.getLayoutHeight() }px`,
			border: '0',
			pointerEvents: 'none'
		} );

		document.body.appendChild( iframe );
		this.iframe = iframe;

		return this.resetDocument( iframe );
	}

	async resetDocument( iframe ) {
		const frameDocument = iframe.contentDocument;

		frameDocument.open();
		frameDocument.write( '<!DOCTYPE html><html><head></head><body></body></html>' );
		frameDocument.close();

		await this.waitForStylesheets( this.copyStyles( frameDocument ) );

		return iframe;
	}

	// Rebuild between exports; snapdom's cached image sizes would corrupt the next.
	recycle() {
		if ( !this.iframe ) {
			return;
		}

		// Discard failed rebuilds so the next export can retry.
		this.preparePromise = this.resetDocument( this.iframe );
		this.preparePromise.catch( () => this.dispose() );
	}

	// Copy the page's stylesheet nodes, not computed styles, which would carry
	// the live viewport's media query results.
	copyStyles( frameDocument ) {
		// The frame document has no URL, so relative paths need a base.
		const base = frameDocument.createElement( 'base' );
		base.href = document.baseURI;
		frameDocument.head.appendChild( base );

		const copiedLinks = [];
		const styleNodes = document.querySelectorAll( 'style, link[rel~="stylesheet"]' );

		for ( const styleNode of styleNodes ) {
			const copy = frameDocument.importNode( styleNode, true );
			frameDocument.head.appendChild( copy );

			if ( copy.tagName === 'LINK' ) {
				copiedLinks.push( { link: copy, loadedInPage: Boolean( styleNode.sheet ) } );
			}
		}

		return copiedLinks;
	}

	// Only fail on a stylesheet the page itself has loaded.
	waitForStylesheets( copiedLinks ) {
		return Promise.all( copiedLinks.map( ( { link, loadedInPage } ) => new Promise( ( resolve, reject ) => {
			if ( link.sheet ) {
				resolve();
				return;
			}

			let timeoutId = null;
			const settle = ( failed ) => {
				clearTimeout( timeoutId );

				if ( failed && loadedInPage ) {
					reject( new Error( `Export frame could not load stylesheet: ${ link.href }` ) );
				} else {
					resolve();
				}
			};

			timeoutId = setTimeout( () => settle( true ), EXPORT_IMAGE_CONFIG.TIMEOUTS.STYLESHEET_LOAD );
			link.addEventListener( 'load', () => settle( false ), { once: true } );
			link.addEventListener( 'error', () => settle( true ), { once: true } );
		} ) ) );
	}

	// Tall enough not to constrain the clone.
	getLayoutHeight() {
		return document.documentElement.scrollHeight;
	}

	/**
	 * Captures an element as it would look at export width.
	 *
	 * @param {HTMLElement} element element in the live document
	 * @param {Object} options required capture settings
	 * @param {number} options.scale requested raster scale
	 * @param {string} options.backgroundColor page background
	 * @param {Function} options.prepareDocument applies export fixes to the frame document
	 * @return {Promise<{canvas: HTMLCanvasElement, scale: number}>}
	 */
	async render( element, options ) {
		const iframe = await this.prepare();
		const frameDocument = iframe.contentDocument;

		iframe.style.height = `${ this.getLayoutHeight() }px`;
		this.copyRootAttributes( frameDocument );

		const target = this.replaceContent( frameDocument, element );
		options.prepareDocument( frameDocument );
		this.pruneHiddenContent( target );
		target.style.background = options.backgroundColor;

		await this.waitForFonts( frameDocument );

		this.pinSubgridTracks( target );

		const bounds = target.getBoundingClientRect();
		if ( bounds.width === 0 || bounds.height === 0 ) {
			throw new Error( 'Canvas capture resulted in zero dimensions' );
		}

		const scale = this.getEffectiveScale( bounds, options.scale );

		try {
			const canvas = await snapdom.toCanvas( target, {
				scale: scale,
				// The fixed scale must not be multiplied by the reader's ratio.
				dpr: 1,
				embedFonts: true,
				// Anything looser keeps stale style maps, which re-render
				// container-constrained images at their intrinsic size.
				cache: 'soft'
			} );

			return { canvas: canvas, scale: scale };
		} finally {
			this.recycle();
		}
	}

	// Pin inherited tracks because the captured root loses its parent grid.
	pinSubgridTracks( element ) {
		const parent = element.parentElement;
		if ( !parent ) {
			return;
		}

		const view = element.ownerDocument.defaultView;
		const style = view.getComputedStyle( element );
		const parentStyle = view.getComputedStyle( parent );

		const axes = [
			{ template: 'gridTemplateColumns', start: 'gridColumnStart', end: 'gridColumnEnd' },
			{ template: 'gridTemplateRows', start: 'gridRowStart', end: 'gridRowEnd' }
		];

		for ( const axis of axes ) {
			if ( !style[ axis.template ].startsWith( 'subgrid' ) ) {
				continue;
			}

			const tracks = this.parseTrackList( parentStyle[ axis.template ] );
			if ( !tracks.length ) {
				continue;
			}

			const from = Math.max( parseInt( style[ axis.start ], 10 ) || 1, 1 ) - 1;
			const end = parseInt( style[ axis.end ], 10 );
			const to = end > 0 ? Math.max( end - 1, from + 1 ) : tracks.length;

			element.style[ axis.template ] = tracks.slice( from, to ).join( ' ' );
		}
	}

	// Splits a resolved track list, keeping line names and functional notation
	// intact: `[a] 10px [b c] minmax( 2px, 1fr )` gives two entries.
	parseTrackList( value ) {
		if ( !value || value === 'none' || value.startsWith( 'subgrid' ) ) {
			return [];
		}

		const tracks = [];
		let pending = '';
		let depth = 0;

		for ( const token of value.split( /\s+/ ) ) {
			pending += ( pending ? ' ' : '' ) + token;
			depth += ( token.match( /[[(]/g ) || [] ).length;
			depth -= ( token.match( /[\])]/g ) || [] ).length;

			// A group of line names belongs to the track that follows it.
			if ( depth === 0 && !token.endsWith( ']' ) ) {
				tracks.push( pending );
				pending = '';
			}
		}

		if ( pending && tracks.length ) {
			tracks[ tracks.length - 1 ] += ` ${ pending }`;
		}

		return tracks;
	}

	// Prune hidden subtrees after export fixes so snapdom skips their images.
	pruneHiddenContent( element ) {
		const view = element.ownerDocument.defaultView;
		const hidden = [];

		// Collect first: removing invalidates style, forcing a recalc per read.
		const collect = ( node ) => {
			for ( let child = node.firstElementChild; child; child = child.nextElementSibling ) {
				if ( view.getComputedStyle( child ).display === 'none' ) {
					hidden.push( child );
				} else {
					collect( child );
				}
			}
		};

		collect( element );

		for ( const node of hidden ) {
			node.remove();
		}
	}

	replaceContent( frameDocument, element ) {
		const marker = EXPORT_IMAGE_CONFIG.CAPTURE.TARGET_ATTRIBUTE;

		element.setAttribute( marker, '' );
		const bodyClone = document.body.cloneNode( true );
		element.removeAttribute( marker );

		const target = bodyClone.querySelector( `[${ marker }]` );
		if ( !target ) {
			throw new Error( 'Could not find the element inside the export frame' );
		}
		target.removeAttribute( marker );

		// Cloned scripts never run, but frames and embeds would load for nothing.
		for ( const node of bodyClone.querySelectorAll( 'script, noscript, iframe, object, embed' ) ) {
			node.remove();
		}

		this.copyDynamicState( element, target );

		frameDocument.adoptNode( bodyClone );
		frameDocument.body.replaceWith( bodyClone );

		return target;
	}

	// Cloning markup loses state that only exists in the DOM.
	copyDynamicState( liveElement, clonedElement ) {
		const selector = 'input, textarea, select, canvas';
		const liveNodes = liveElement.querySelectorAll( selector );
		const clonedNodes = clonedElement.querySelectorAll( selector );

		for ( let index = 0; index < liveNodes.length && index < clonedNodes.length; index++ ) {
			const liveNode = liveNodes[ index ];
			const clonedNode = clonedNodes[ index ];

			// The lists have drifted out of step, so no later pairing can be
			// trusted either.
			if ( liveNode.tagName !== clonedNode.tagName ) {
				return;
			}

			if ( liveNode.tagName === 'CANVAS' ) {
				this.copyCanvas( liveNode, clonedNode );
			} else if ( liveNode.type !== 'file' ) {
				// A file input would throw on an assigned value.
				clonedNode.value = liveNode.value;

				if ( liveNode.tagName === 'INPUT' ) {
					clonedNode.checked = liveNode.checked;
					clonedNode.indeterminate = liveNode.indeterminate;
				}
			}
		}
	}

	copyCanvas( liveCanvas, clonedCanvas ) {
		if ( liveCanvas.width === 0 || liveCanvas.height === 0 ) {
			return;
		}

		try {
			clonedCanvas.getContext( '2d' ).drawImage( liveCanvas, 0, 0 );
		} catch {
			// A tainted canvas cannot be read; leave the copy blank.
		}
	}

	// Theme classes live on the root, runtime custom properties in its style.
	copyRootAttributes( frameDocument ) {
		const liveRoot = document.documentElement;
		const frameRoot = frameDocument.documentElement;

		frameRoot.className = liveRoot.className;
		frameRoot.setAttribute( 'lang', liveRoot.lang || 'en' );
		frameRoot.setAttribute( 'dir', liveRoot.dir || 'ltr' );
		frameRoot.setAttribute( 'style', liveRoot.getAttribute( 'style' ) || '' );
	}

	// Text is measured later, but a slow font must not block the export.
	waitForFonts( frameDocument ) {
		if ( !frameDocument.fonts ) {
			return Promise.resolve();
		}

		return Promise.race( [
			frameDocument.fonts.ready,
			new Promise( ( resolve ) => {
				setTimeout( resolve, EXPORT_IMAGE_CONFIG.TIMEOUTS.FONT_READY );
			} )
		] );
	}

	// The composed chrome shares the raster budget, and losing resolution beats
	// losing the image, so the scale drops as far as it has to.
	getEffectiveScale( bounds, requestedScale ) {
		const dimensions = EXPORT_IMAGE_CONFIG.DIMENSIONS;
		const composed = ( dimensions.PADDING * 4 ) + dimensions.HEADER_HEIGHT + dimensions.FOOTER_HEIGHT;
		const longestSide = Math.max( bounds.width, bounds.height, 1 ) + composed;

		return Math.min( requestedScale, EXPORT_IMAGE_CONFIG.CAPTURE.MAX_RASTER_SIDE / longestSide );
	}

	dispose() {
		if ( this.iframe ) {
			this.iframe.remove();
			this.iframe = null;
		}

		this.preparePromise = null;
	}
}

class ExportService {
	constructor( canvasComposer ) {
		this.canvasComposer = canvasComposer;
		this.layoutFrame = new ExportLayoutFrame();
		this.snapdomPromise = null;
		this.exportInProgress = false;
	}

	applyExportFixes( frameDocument ) {
		this.suppressShadows( frameDocument );
		this.hideInfoIcons( frameDocument );
		this.removeExportControls( frameDocument );
		this.expandPrizepoolTables( frameDocument );
	}

	// One pixel shadow sends Safari and iOS down snapdom's fallback path, which
	// rasterises at natural size and upscales, softening the whole image.
	suppressShadows( frameDocument ) {
		const style = frameDocument.createElement( 'style' );

		style.textContent = '*, *::before, *::after { box-shadow: none !important; ' +
			'text-shadow: none !important; }';
		frameDocument.head.appendChild( style );
	}

	hideInfoIcons( frameDocument ) {
		const infoIcons = frameDocument.querySelectorAll( '.brkts-match-info-icon' );
		for ( const icon of infoIcons ) {
			icon.style.opacity = '0';
		}
	}

	removeExportControls( frameDocument ) {
		const controls = frameDocument.querySelectorAll(
			'.switch-pill-container, .prizepooltabletoggle, .prizepool-table-wrapper .table2__footer'
		);

		for ( const control of controls ) {
			control.remove();
		}
	}

	// Cut placements are hidden by `.collapsed` on the wrapper; expand so they export.
	expandPrizepoolTables( frameDocument ) {
		const collapsedTables = frameDocument.querySelectorAll( '.prizepool-table-wrapper.collapsed' );

		for ( const collapsedTable of collapsedTables ) {
			collapsedTable.classList.remove( 'collapsed' );
		}
	}

	async export( element, title, mode ) {
		if ( this.exportInProgress ) {
			throw new Error( 'An export is already in progress' );
		}

		this.exportInProgress = true;

		try {
			await this.prewarm();

			if ( mode === 'copy' ) {
				await this.copyToClipboard( element, title );
			} else if ( mode === 'download' ) {
				const blob = await this.generateImageBlob( element, title );
				this.downloadBlob( blob, this.generateFilename( title ) );
			} else {
				throw new Error( `Unknown export mode: ${ mode }` );
			}
		} finally {
			this.exportInProgress = false;
		}
	}

	async generateImageBlob( element, title ) {
		const isDarkTheme = document.documentElement.classList.contains( 'theme--dark' );
		const backgroundColor = this.getBackgroundColor();

		const capture = await this.layoutFrame.render( element, {
			scale: EXPORT_IMAGE_CONFIG.CAPTURE.SCALE,
			backgroundColor: backgroundColor,
			prepareDocument: ( frameDocument ) => this.applyExportFixes( frameDocument )
		} );

		if ( capture.canvas.width === 0 || capture.canvas.height === 0 ) {
			throw new Error( 'Canvas capture resulted in zero dimensions' );
		}

		const composedCanvas = await this.canvasComposer.compose(
			capture.canvas,
			title,
			isDarkTheme,
			capture.scale,
			backgroundColor
		);

		return new Promise( ( resolve, reject ) => {
			composedCanvas.toBlob( ( blob ) => {
				if ( blob ) {
					resolve( blob );
				} else {
					reject( new Error( 'Failed to create image blob' ) );
				}
			}, 'image/png' );
		} );
	}

	async copyToClipboard( element, title ) {
		if ( !window.ClipboardItem || !navigator.clipboard || !navigator.clipboard.write ) {
			mw.notify( 'This browser does not support copying images to the clipboard.', { type: 'error' } );
			return;
		}

		try {
			const blobPromise = this.generateImageBlob( element, title );

			const clipboardItem = new ClipboardItem( { 'image/png': blobPromise } );

			await navigator.clipboard.write( [ clipboardItem ] );
			mw.notify( 'Image copied to clipboard!' );
		} catch ( error ) {
			// eslint-disable-next-line no-console
			console.error( 'Clipboard write failed:', error );
			mw.notify( 'Failed to copy image to clipboard. Please try the Download option.', { type: 'error' } );
		}
	}

	downloadBlob( blob, filename ) {
		const url = URL.createObjectURL( blob );
		const link = document.createElement( 'a' );
		link.download = `${ filename }.png`;
		link.href = url;
		link.click();

		setTimeout( () => {
			URL.revokeObjectURL( url );
		}, EXPORT_IMAGE_CONFIG.TIMEOUTS.URL_REVOKE_DELAY );
	}

	// Called on menu open so setup lands before anyone picks an option.
	prewarm() {
		return Promise.all( [ this.ensureSnapdomLoaded(), this.layoutFrame.prepare() ] );
	}

	ensureSnapdomLoaded() {
		if ( !this.snapdomPromise ) {
			this.snapdomPromise = Promise.resolve( mw.loader.using( 'snapdom' ) ).catch( ( error ) => {
				// Let the next export retry instead of reusing the failure.
				this.snapdomPromise = null;
				throw error;
			} );
		}

		return this.snapdomPromise;
	}

	dispose() {
		this.layoutFrame.dispose();
	}

	getBackgroundColor() {
		const computedStyles = window.getComputedStyle( document.documentElement );
		return computedStyles.getPropertyValue( '--clr-background' ) || '#ffffff';
	}

	generateFilename( title ) {
		const pageTitle = mw.config.get( 'wgDisplayTitle' ) || mw.config.get( 'wgTitle' );
		let filename = `Liquipedia ${ pageTitle } ${ title } ${ this.generateTimestamp() }`;

		filename = filename.replace( /[\\/:*?"<>|]/g, '_' ).trim();

		const MAX_FILENAME_LENGTH = 215;
		if ( filename.length > MAX_FILENAME_LENGTH ) {
			filename = filename.slice( 0, MAX_FILENAME_LENGTH ).trim();
		}

		return filename;
	}

	generateTimestamp() {
		const now = new Date();
		const pad = ( num ) => String( num ).padStart( 2, '0' );

		return `${ now.getFullYear() }${ pad( now.getMonth() + 1 ) }${ pad( now.getDate() ) }_` +
			`${ pad( now.getHours() ) }${ pad( now.getMinutes() ) }${ pad( now.getSeconds() ) }`;
	}

	isExporting() {
		return this.exportInProgress;
	}
}

class ExportImageDOMUtils {
	static findPreviousHeading( startElement ) {
		const walker = document.createTreeWalker(
			document.body,
			NodeFilter.SHOW_ELEMENT,
			null,
			false
		);
		walker.currentNode = startElement;

		while ( walker.previousNode() ) {
			const currentNode = walker.currentNode;

			if ( currentNode.matches( 'h1,h2,h3,h4,h5,h6' ) ) {
				const headingText = this.extractHeadingText( currentNode );
				if ( headingText ) {
					return { node: currentNode, text: headingText };
				}
			}
		}

		return null;
	}

	static isElementVisible( element ) {
		if ( !element ) {
			return false;
		}

		const style = window.getComputedStyle( element );
		if ( style.display === 'none' || style.visibility === 'hidden' ) {
			return false;
		}

		// `closest` walks to the root on its own, so one check covers every ancestor.
		if ( element.parentElement?.closest( '.tabs-content > div:not(.active)' ) ) {
			return false;
		}

		let parent = element.parentElement;
		while ( parent && parent !== document.body ) {
			const parentStyle = window.getComputedStyle( parent );

			if ( parentStyle.display === 'none' || parentStyle.visibility === 'hidden' ) {
				return false;
			}

			if ( parent.classList.contains( 'collapsed' ) ||
				parent.classList.contains( 'is--collapsed' ) ||
				parent.dataset.collapsibleState === 'collapsed' ) {
				return false;
			}

			parent = parent.parentElement;
		}

		return true;
	}

	static extractHeadingText( headingElement ) {
		const clonedHeading = headingElement.cloneNode( true );
		clonedHeading.querySelector( '.mw-editsection' )?.remove();
		const headlineElement = clonedHeading.querySelector( '.mw-headline' );
		return ( headlineElement || clonedHeading ).textContent.trim();
	}

	static findExportableElements() {
		const headingsToElements = new Map();
		const processedElements = new Set();

		for ( const config of EXPORT_IMAGE_CONFIG.SELECTORS ) {
			const elements = document.querySelectorAll( config.selector );

			for ( const element of elements ) {
				const targetElement = config.targetSelector ?
					element.querySelector( config.targetSelector ) :
					element;

				if ( !targetElement || processedElements.has( targetElement ) ) {
					continue;
				}

				processedElements.add( targetElement );

				const headingInfo = this.findPreviousHeading( element );
				if ( !headingInfo ) {
					continue;
				}

				if ( !headingsToElements.has( headingInfo.text ) ) {
					headingsToElements.set( headingInfo.text, {
						headingNode: headingInfo.node,
						headingText: headingInfo.text,
						elements: []
					} );
				}

				const titleElement = config.titleSelector ?
					element.querySelector( config.titleSelector ) :
					null;
				const title = titleElement ? titleElement.textContent.trim() : null;

				const subtitle = config.manualSubtitle || headingInfo.text;

				headingsToElements.get( headingInfo.text ).elements.push( {
					element: targetElement,
					typeName: config.typeName,
					title: title,
					subtitle: subtitle,
					isVisible: this.isElementVisible( targetElement )
				} );
			}
		}

		return headingsToElements;
	}
}

class DropdownWidget {
	constructor( exportService ) {
		this.exportService = exportService;
		this.eventCleanupFunctions = new WeakMap();
	}

	create( elements, sectionTitle ) {
		const loadingElement = this.createLoadingElement();
		const menuElement = this.createMenuElement( loadingElement );
		let menuItems = [];

		const populateMenu = () => {
			while ( menuElement.firstChild && menuElement.firstChild !== loadingElement ) {
				menuElement.removeChild( menuElement.firstChild );
			}

			if ( !menuElement.contains( loadingElement ) ) {
				menuElement.appendChild( loadingElement );
			}

			const visibleElements = elements.filter( ( item ) => ExportImageDOMUtils.isElementVisible( item.element )
			);
			const hasSingleElement = visibleElements.length === 1;
			menuItems = [];

			if ( visibleElements.length === 0 ) {
				const disabledButton = this.createDisabledMenuItem(
					'<i class="fas fa-fw fa-eye-slash"></i> Content not visible'
				);
				menuElement.insertBefore( disabledButton, loadingElement );
			} else {
				for ( let i = 0; i < visibleElements.length; i++ ) {
					const item = visibleElements[ i ];
					const elementLabel = this.getElementLabel( visibleElements, i );
					const typeLabel = hasSingleElement ? '' : ` ${ elementLabel }`;
					const exportTitle = item.title || item.subtitle || sectionTitle;

					const copyButton = this.createMenuButton( {
						icon: 'copy',
						buttonText: `Copy ${ typeLabel } image to clipboard`,
						item: item,
						exportTitle: exportTitle,
						exportMode: 'copy',
						menuElement: menuElement,
						menuItems: menuItems,
						loadingElement: loadingElement
					} );

					const downloadButton = this.createMenuButton( {
						icon: 'download',
						buttonText: `Download ${ typeLabel } as image`,
						item: item,
						exportTitle: exportTitle,
						exportMode: 'download',
						menuElement: menuElement,
						menuItems: menuItems,
						loadingElement: loadingElement
					} );

					menuItems.push( copyButton, downloadButton );
				}

				menuItems.forEach( ( item ) => menuElement.insertBefore( item, loadingElement ) );
			}
		};

		populateMenu();

		const toggleButton = this.createToggleButton( menuElement, populateMenu );
		const wrapper = this.createWrapper( toggleButton, menuElement );

		this.setupEventListeners( wrapper, menuElement, toggleButton );

		return wrapper;
	}

	createDisabledMenuItem( buttonText ) {
		return this.createElement( 'div', {
			class: 'dropdown-widget__item',
			style: { color: '#999', cursor: 'not-allowed' },
			title: 'Please switch to the tab or expand the section to export this content'
		}, buttonText );
	}

	createLoadingElement() {
		return this.createElement( 'div', {
			class: 'dropdown-widget__item',
			tabindex: '-1',
			style: { display: 'none' },
			dataset: { loading: 'true' }
		}, '<i class="fas fa-fw fa-spinner fa-spin"></i> Processing...' );
	}

	createMenuElement( loadingElement ) {
		return this.createElement( 'div', {
			class: 'dropdown-widget__menu',
			role: 'menu',
			style: { display: 'none' }
		}, [ loadingElement ] );
	}

	createMenuButton( options ) {
		const {
			icon,
			buttonText,
			item,
			exportTitle,
			exportMode,
			menuElement,
			menuItems,
			loadingElement
		} = options;

		const button = this.createElement( 'div', {
			class: 'dropdown-widget__item',
			tabindex: '0',
			role: 'menuitem'
		}, `<i class="fas fa-fw fa-${ icon }"></i> ${ buttonText }` );

		button.addEventListener( 'click', async ( event ) => {
			event.stopPropagation();
			await this.handleExport(
				item.element,
				exportTitle,
				exportMode,
				menuElement,
				menuItems,
				loadingElement
			);
		} );

		return button;
	}

	createToggleButton( menuElement, onOpen ) {
		const iconMargin = EXPORT_IMAGE_CONFIG.SPACING.ICON_MARGIN;
		const buttonContent =
			`<i class="fas fa-share-alt" style="margin-right: ${ iconMargin };"></i>` +
			'<span style="line-height: 1">Share</span>';

		const button = this.createElement( 'button', {
			class: 'button button--ghost button--extrasmall dropdown-widget__toggle',
			type: 'button',
			title: 'Share',
			'aria-label': 'Share this content',
			'aria-expanded': 'false',
			'aria-haspopup': 'true'
		}, buttonContent );

		button.addEventListener( 'click', () => {
			if ( menuElement.style.display === 'none' ) {
				// Exports retry setup and report properly, so only log here.
				this.exportService.prewarm().catch( ( error ) => {
					// eslint-disable-next-line no-console
					console.warn( 'Export prewarm failed:', error );
				} );
				if ( onOpen ) {
					onOpen();
				}
			}
			this.toggleMenu( menuElement, button );
		} );

		return button;
	}

	createWrapper( toggleButton, menuElement ) {
		return this.createElement( 'div', {
			class: 'dropdown-widget',
			style: {
				display: 'inline-block',
				marginLeft: EXPORT_IMAGE_CONFIG.SPACING.DROPDOWN_MARGIN,
				verticalAlign: 'middle',
				fontSize: '14px'
			}
		}, [ toggleButton, menuElement ] );
	}

	setupEventListeners( wrapper, menuElement, toggleButton ) {
		const outsideClickHandler = ( event ) => {
			if ( !wrapper.contains( event.target ) ) {
				this.closeMenu( menuElement, toggleButton );
			}
		};

		const keydownHandler = ( event ) => {
			this.handleMenuKeydown( event, menuElement, toggleButton );
		};

		document.addEventListener( 'click', outsideClickHandler );
		menuElement.addEventListener( 'keydown', keydownHandler );

		this.eventCleanupFunctions.set( wrapper, () => {
			document.removeEventListener( 'click', outsideClickHandler );
			menuElement.removeEventListener( 'keydown', keydownHandler );
		} );
	}

	async handleExport( element, title, mode, menuElement, menuItems, loadingElement ) {
		if ( this.exportService.isExporting() ) {
			return;
		}

		this.showLoading( menuItems, loadingElement );

		try {
			await this.exportService.export( element, title, mode );
			this.closeMenu( menuElement, menuElement.previousElementSibling );
		} catch ( error ) {
			this.handleExportError( error );
		} finally {
			this.hideLoading( menuItems, loadingElement );
		}
	}

	showLoading( menuItems, loadingElement ) {
		loadingElement.style.display = 'block';
		for ( const item of menuItems ) {
			item.style.display = 'none';
		}
	}

	hideLoading( menuItems, loadingElement ) {
		loadingElement.style.display = 'none';
		for ( const item of menuItems ) {
			item.style.display = '';
		}
	}

	handleExportError( error ) {
		// eslint-disable-next-line no-console
		console.error( 'Export error:', error );

		const errorMessages = {
			clipboard: 'Clipboard access denied. Please check your browser permissions.',
			timeout: 'Export timed out. Please try again.',
			'in progress': 'An export is already in progress.',
			'zero dimensions': 'The content is not visible. Please ensure the tab/section is expanded and try again.'
		};

		let userMessage = 'Export failed. Please try again.';

		for ( const [ key, message ] of Object.entries( errorMessages ) ) {
			if ( error.message && error.message.toLowerCase().includes( key ) ) {
				userMessage = message;
				break;
			}
		}

		mw.notify( userMessage, { type: 'error' } );
	}

	toggleMenu( menuElement, buttonElement ) {
		const isHidden = menuElement.style.display === 'none';
		if ( isHidden ) {
			this.openMenu( menuElement, buttonElement );
		} else {
			this.closeMenu( menuElement, buttonElement );
		}
	}

	openMenu( menuElement, buttonElement ) {
		menuElement.style.left = '';
		menuElement.style.right = '';
		menuElement.style.display = 'block';

		const viewportWidth = window.innerWidth;
		const menuRect = menuElement.getBoundingClientRect();

		if ( menuRect.right > viewportWidth ) {
			const parentRect = buttonElement.parentElement.getBoundingClientRect();
			let newLeft = viewportWidth - menuRect.width - parentRect.left;

			newLeft = Math.max( newLeft, -parentRect.left );

			menuElement.style.left = `${ newLeft }px`;
			menuElement.style.right = 'auto';
		}

		buttonElement.setAttribute( 'aria-expanded', 'true' );

		const firstFocusable = menuElement.querySelector( '[tabindex="0"]' );
		if ( firstFocusable ) {
			firstFocusable.focus();
		}
	}

	closeMenu( menuElement, buttonElement ) {
		menuElement.style.display = 'none';
		buttonElement.setAttribute( 'aria-expanded', 'false' );
	}

	handleMenuKeydown( event, menuElement, buttonElement ) {
		const visibleSelector = '[tabindex="0"]:not([style*="display: none"])';
		const focusableItems = Array.from( menuElement.querySelectorAll( visibleSelector ) );
		const currentIndex = focusableItems.indexOf( document.activeElement );

		const actions = {
			Escape: () => {
				this.closeMenu( menuElement, buttonElement );
				buttonElement.focus();
			},
			ArrowDown: () => {
				const nextItem = focusableItems[ ( currentIndex + 1 ) % focusableItems.length ];
				if ( nextItem ) {
					nextItem.focus();
				}
			},
			ArrowUp: () => {
				const prevItem = focusableItems[ ( currentIndex - 1 + focusableItems.length ) % focusableItems.length ];
				if ( prevItem ) {
					prevItem.focus();
				}
			},
			Home: () => {
				if ( focusableItems[ 0 ] ) {
					focusableItems[ 0 ].focus();
				}
			},
			End: () => {
				const lastItem = focusableItems[ focusableItems.length - 1 ];
				if ( lastItem ) {
					lastItem.focus();
				}
			},
			Enter: () => {
				if ( document.activeElement ) {
					document.activeElement.click();
				}
			},
			' ': () => {
				if ( document.activeElement ) {
					document.activeElement.click();
				}
			}
		};

		const action = actions[ event.key ];
		if ( action ) {
			event.preventDefault();
			action();
		}
	}

	getElementLabel( elements, index ) {
		const item = elements[ index ];

		if ( item.title ) {
			return item.title;
		}

		const sameTypeElements = elements.filter( ( it ) => it.typeName === item.typeName );
		const sameTypeWithoutTitle = sameTypeElements.filter( ( it ) => !it.title );

		if ( sameTypeWithoutTitle.length > 1 ) {
			const indexInType = sameTypeWithoutTitle.indexOf( item );
			return `${ item.typeName } ${ indexInType + 1 }`;
		}

		return item.typeName;
	}

	createElement( tag, attributes = {}, children = [] ) {
		const element = document.createElement( tag );

		for ( const [ key, value ] of Object.entries( attributes ) ) {
			if ( key === 'style' && typeof value === 'object' ) {
				Object.assign( element.style, value );
			} else if ( key === 'dataset' && typeof value === 'object' ) {
				Object.assign( element.dataset, value );
			} else {
				element.setAttribute( key, value );
			}
		}

		if ( typeof children === 'string' ) {
			element.innerHTML = children;
		} else if ( Array.isArray( children ) ) {
			for ( const child of children ) {
				if ( child ) {
					element.appendChild( child );
				}
			}
		}

		return element;
	}

	cleanup( wrapper ) {
		const cleanupFn = this.eventCleanupFunctions.get( wrapper );
		if ( cleanupFn ) {
			cleanupFn();
			this.eventCleanupFunctions.delete( wrapper );
		}
	}
}

class ExportImageModule {
	constructor() {
		this.imageCache = new ImageCache();
		this.canvasComposer = new CanvasComposer( this.imageCache );
		this.exportService = new ExportService( this.canvasComposer );
		this.dropdownWidget = new DropdownWidget( this.exportService );
	}

	init() {
		this.injectDropdowns();
	}

	injectDropdowns() {
		const headingsToElements = ExportImageDOMUtils.findExportableElements();

		for ( const data of headingsToElements.values() ) {
			let targetNode = data.headingNode;

			if ( targetNode.parentNode && targetNode.parentNode.classList.contains( 'mw-heading' ) ) {
				targetNode = targetNode.parentNode;
			}

			if ( !targetNode.querySelector( '.dropdown-widget' ) ) {
				const dropdown = this.dropdownWidget.create( data.elements, data.headingText );
				targetNode.appendChild( dropdown );
			}
		}
	}

	cleanup() {
		this.imageCache.clear();
		this.exportService.dispose();
		const dropdowns = document.querySelectorAll( '.dropdown-widget' );
		for ( const dropdown of dropdowns ) {
			this.dropdownWidget.cleanup( dropdown );
		}
	}
}

liquipedia.exportImage = new ExportImageModule();
liquipedia.core.modules.push( 'exportImage' );
