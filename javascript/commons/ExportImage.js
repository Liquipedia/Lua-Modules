/* global html2canvas */

/*******************************************************************************
 * Description: Adds export functionality to Liquipedia pages, enabling users
 *              to copy or download group tables, crosstables, brackets, and
 *              match lists as images.
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
		URL_REVOKE_DELAY: 100
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
		{ selector: '.brkts-matchlist', targetSelector: '.brkts-matchlist-collapse-area', typeName: 'Match List' }
	]
};

/**
 * Manages image caching and loading
 */
class ImageCache {
	constructor() {
		this.cache = new Map();
	}

	async load( url, key, timeout = EXPORT_IMAGE_CONFIG.TIMEOUTS.IMAGE_LOAD ) {
		// Return cached image if available
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

/**
 * Handles canvas composition and rendering
 */
class CanvasComposer {
	constructor( imageCache ) {
		this.imageCache = imageCache;
		this.offscreenContext = null; // Reusable context for text measurement
	}

	async compose( sourceCanvas, sectionTitle, isDarkTheme, scale = 1 ) {
		// Create scaled dimensions object
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
		this.drawContent( context, sourceCanvas, headerLayout.height, dims );
		await this.drawFooter(
			context, canvas.width, sourceCanvas.height, theme, isDarkTheme, headerLayout.height, fonts, dims
		);

		return canvas;
	}

	// Creates scaled dimensions object
	getScaledDimensions( scale ) {
		const dims = {};
		for ( const [ key, value ] of Object.entries( EXPORT_IMAGE_CONFIG.DIMENSIONS ) ) {
			dims[ key ] = typeof value === 'number' ? value * scale : value;
		}
		return dims;
	}

	// Creates scaled fonts object
	getScaledFonts( scale ) {
		const fonts = {};
		for ( const [ key, fontString ] of Object.entries( EXPORT_IMAGE_CONFIG.FONTS ) ) {
			fonts[ key ] = this.scaleFontSize( fontString, scale );
		}
		return fonts;
	}

	// Scales the pixel size in a font string
	scaleFontSize( fontString, scale ) {
		return fontString.replace( /(\d+)px/, ( _match, pixels ) => {
			const scaledPixels = parseInt( pixels ) * scale;
			return `${ scaledPixels }px`;
		} );
	}

	// Gets or creates reusable offscreen context for text measurements
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
		// Draw header background with gradient
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

		// Draw header text
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

	drawContent( context, sourceCanvas, headerHeight, dims ) {
		context.drawImage(
			sourceCanvas,
			dims.PADDING,
			dims.PADDING + headerHeight + dims.PADDING
		);
	}

	async drawFooter( context, canvasWidth, sourceHeight, theme, isDarkTheme, headerHeight, fonts, dims ) {
		const footerY = dims.PADDING + headerHeight + dims.PADDING + sourceHeight + dims.PADDING;

		// Draw footer background
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

		// Draw footer text
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

		// Draw logo (non-critical, catch errors silently)
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

		// Measure text widths
		context.font = fonts.HEADER;
		const mainTitleWidth = context.measureText( mainTitle ).width;

		context.font = fonts.SUBHEADER;
		const sectionTitleWidth = context.measureText( sectionTitle ).width;

		const totalTextWidth = mainTitleWidth + sectionTitleWidth + ( dims.HEADER_TEXT_OFFSET * 2 );
		const sideBySideAvailableWidth = canvasWidth - ( dims.PADDING * 2 ) - dims.TEXT_OFFSET_X;

		// Check if text fits side-by-side
		if ( totalTextWidth <= sideBySideAvailableWidth ) {
			return {
				height: dims.HEADER_HEIGHT,
				isStacked: false,
				mainTitleLines: [ mainTitle ],
				sectionTitleLines: [ sectionTitle ]
			};
		}

		// Calculate stacked layout
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

		if ( words.length === 0 ) {
			return [];
		}

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
 * Handles export operations (canvas capture, download, clipboard)
 */
class ExportService {
	constructor( canvasComposer ) {
		this.canvasComposer = canvasComposer;
		this.html2canvasLoaded = false;
		this.activeExports = new Set();
	}

	applyCloneFixes( clonedDoc ) {
		this.hideInfoIcons( clonedDoc );
	}

	// Hides info icons that shouldn't appear in exports
	hideInfoIcons( clonedDoc ) {
		const infoIcons = clonedDoc.querySelectorAll( '.brkts-match-info-icon' );
		for ( const icon of infoIcons ) {
			icon.style.opacity = '0';
		}
	}

	async export( element, title, mode ) {
		// Prevent concurrent exports
		if ( this.activeExports.size > 0 ) {
			throw new Error( 'An export is already in progress' );
		}

		const exportId = Symbol( 'export' );
		this.activeExports.add( exportId );

		try {
			await this.ensureHtml2CanvasLoaded();

			if ( mode === 'copy' ) {
				await this.copyToClipboard( element, title );
			} else if ( mode === 'download' ) {
				const blob = await this.generateImageBlob( element, title );
				this.downloadBlob( blob, this.generateFilename( title ) );
			} else {
				throw new Error( `Unknown export mode: ${ mode }` );
			}
		} finally {
			this.activeExports.delete( exportId );
		}
	}

	async generateImageBlob( element, title ) {
		const originalBackground = element.style.background;
		const isDarkTheme = document.documentElement.classList.contains( 'theme--dark' );
		const backgroundColor = this.getBackgroundColor();
		const scale = window.devicePixelRatio || 1;

		try {
			element.style.background = backgroundColor;

			const capturedCanvas = await html2canvas( element, {
				scale: scale,
				windowWidth: 1440,
				windowHeight: document.documentElement.scrollHeight,
				scrollX: 0,
				scrollY: 0,
				backgroundColor: backgroundColor,
				onclone: ( clonedDoc ) => this.applyCloneFixes( clonedDoc )
			} );

			if ( capturedCanvas.width === 0 || capturedCanvas.height === 0 ) {
				throw new Error( 'Canvas capture resulted in zero dimensions' );
			}

			const composedCanvas = await this.canvasComposer.compose(
				capturedCanvas,
				title,
				isDarkTheme,
				scale
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
		} finally {
			element.style.background = originalBackground;
		}
	}

	async copyToClipboard( element, title ) {
		// Check browser support
		if ( !window.ClipboardItem || !navigator.clipboard || !navigator.clipboard.write ) {
			mw.notify( 'This browser does not support copying images to the clipboard.', { type: 'error' } );
			return;
		}

		try {
			const blobPromise = this.generateImageBlob( element, title );

			// eslint-disable-next-line compat/compat
			const clipboardItem = new ClipboardItem( { 'image/png': blobPromise } );

			// eslint-disable-next-line compat/compat
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

		// Clean up object URL after short delay
		setTimeout( () => {
			URL.revokeObjectURL( url );
		}, EXPORT_IMAGE_CONFIG.TIMEOUTS.URL_REVOKE_DELAY );
	}

	async ensureHtml2CanvasLoaded() {
		if ( this.html2canvasLoaded ) {
			return;
		}

		return new Promise( ( resolve ) => {
			mw.loader.using( 'html2canvas', () => {
				this.html2canvasLoaded = true;
				resolve();
			} );
		} );
	}

	getBackgroundColor() {
		const computedStyles = window.getComputedStyle( document.documentElement );
		return computedStyles.getPropertyValue( '--clr-background' ) || '#ffffff';
	}

	generateFilename( title ) {
		const pageTitle = mw.config.get( 'wgDisplayTitle' ) || mw.config.get( 'wgTitle' );
		let filename = `Liquipedia ${ pageTitle } ${ title } ${ this.generateTimestamp() }`;

		// Remove invalid filename characters
		filename = filename.replace( /[\\/:*?"<>|]/g, '_' ).trim();

		// Limit filename length (with buffer for extension)
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
		return this.activeExports.size > 0;
	}
}

/**
 * Utilities for finding elements and headings in the DOM
 */
class DOMUtils {
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

		// Check element itself
		const style = window.getComputedStyle( element );
		if ( style.display === 'none' || style.visibility === 'hidden' ) {
			return false;
		}

		// Check parent chain
		let parent = element.parentElement;
		while ( parent && parent !== document.body ) {
			const parentStyle = window.getComputedStyle( parent );

			if ( parentStyle.display === 'none' || parentStyle.visibility === 'hidden' ) {
				return false;
			}

			// Check for collapsed state
			if ( parent.classList.contains( 'collapsed' ) ||
				parent.classList.contains( 'is--collapsed' ) ||
				parent.dataset.collapsibleState === 'collapsed' ) {
				return false;
			}

			// Check for inactive tabs
			if ( parent.closest( '.tabs-content > div:not(.active)' ) ) {
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

				// Group by heading
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

				headingsToElements.get( headingInfo.text ).elements.push( {
					element: targetElement,
					typeName: config.typeName,
					title: title,
					isVisible: this.isElementVisible( targetElement )
				} );
			}
		}

		return headingsToElements;
	}
}

/**
 * Creates and manages dropdown UI components
 */
class DropdownWidget {
	constructor( exportService, zoomManager ) {
		this.exportService = exportService;
		this.zoomManager = zoomManager;
		this.eventCleanupFunctions = new WeakMap();
	}

	create( elements, sectionTitle ) {
		const loadingElement = this.createLoadingElement();
		const menuElement = this.createMenuElement( loadingElement );
		let menuItems = [];

		const populateMenu = () => {
			// Clear existing items (except loading)
			while ( menuElement.firstChild && menuElement.firstChild !== loadingElement ) {
				menuElement.removeChild( menuElement.firstChild );
			}

			// Ensure loading element is present
			if ( !menuElement.contains( loadingElement ) ) {
				menuElement.appendChild( loadingElement );
			}

			// Show refresh prompt if zoom changed
			if ( this.zoomManager.hasZoomed ) {
				const refreshItem = this.createRefreshMenuItem();
				menuElement.insertBefore( refreshItem, loadingElement );
				return;
			}

			// Filter visible elements
			const visibleElements = elements.filter( ( item ) => DOMUtils.isElementVisible( item.element )
			);
			const hasSingleElement = visibleElements.length === 1;
			menuItems = [];

			// Create menu items
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
					const exportTitle = item.title || sectionTitle;

					const copyButton = this.createMenuButton( {
						icon: 'copy',
						buttonText: `Copy${ typeLabel } image to clipboard`,
						item: item,
						exportTitle: exportTitle,
						exportMode: 'copy',
						menuElement: menuElement,
						menuItems: menuItems,
						loadingElement: loadingElement
					} );

					const downloadButton = this.createMenuButton( {
						icon: 'download',
						buttonText: `Download${ typeLabel } as image`,
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

	createRefreshMenuItem() {
		const item = this.createElement( 'div', {
			class: 'dropdown-widget__item',
			tabindex: '0',
			role: 'menuitem',
			style: { fontWeight: 'bold' }
		}, '<i class="fas fa-fw fa-sync-alt"></i> Refresh the page to export images' );

		item.addEventListener( 'click', () => window.location.reload() );

		return item;
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
			class: 'btn btn-ghost btn-extrasmall dropdown-widget__toggle',
			type: 'button',
			title: 'Share',
			'aria-label': 'Share this content',
			'aria-expanded': 'false',
			'aria-haspopup': 'true'
		}, buttonContent );

		button.addEventListener( 'click', () => {
			if ( menuElement.style.display === 'none' ) {
				this.exportService.ensureHtml2CanvasLoaded();
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

		// Store cleanup function
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
		// Reset positioning
		menuElement.style.left = '';
		menuElement.style.right = '';
		menuElement.style.display = 'block';

		// Adjust for viewport overflow
		const viewportWidth = window.innerWidth;
		const menuRect = menuElement.getBoundingClientRect();

		if ( menuRect.right > viewportWidth ) {
			const parentRect = buttonElement.parentElement.getBoundingClientRect();
			let newLeft = viewportWidth - menuRect.width - parentRect.left;

			// Ensure menu doesn't overflow left edge
			newLeft = Math.max( newLeft, -parentRect.left );

			menuElement.style.left = `${ newLeft }px`;
			menuElement.style.right = 'auto';
		}

		buttonElement.setAttribute( 'aria-expanded', 'true' );

		// Focus first focusable item
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

		// Set attributes
		for ( const [ key, value ] of Object.entries( attributes ) ) {
			if ( key === 'style' && typeof value === 'object' ) {
				Object.assign( element.style, value );
			} else if ( key === 'dataset' && typeof value === 'object' ) {
				Object.assign( element.dataset, value );
			} else {
				element.setAttribute( key, value );
			}
		}

		// Add children
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

/**
 * Manages zoom detection
 */
class ZoomManager {
	constructor() {
		this.initialZoom = this.getZoomLevel();
		this.hasZoomed = false;
		this.resizeTimeout = null;
		this.setupZoomListener();
	}

	getZoomLevel() {
		return window.devicePixelRatio || 1;
	}

	setupZoomListener() {
		window.addEventListener( 'resize', () => {
			clearTimeout( this.resizeTimeout );
			this.resizeTimeout = setTimeout( () => {
				this.handleZoomChange();
			}, 250 );
		} );
	}

	handleZoomChange() {
		const newZoom = this.getZoomLevel();
		const ZOOM_THRESHOLD = 0.01;

		if ( Math.abs( newZoom - this.initialZoom ) > ZOOM_THRESHOLD ) {
			this.hasZoomed = true;
		}
	}
}

/**
 * Main module class that coordinates all components
 */
class ExportImageModule {
	constructor() {
		this.imageCache = new ImageCache();
		this.canvasComposer = new CanvasComposer( this.imageCache );
		this.exportService = new ExportService( this.canvasComposer );
		this.zoomManager = new ZoomManager();
		this.dropdownWidget = new DropdownWidget( this.exportService, this.zoomManager );
	}

	init() {
		this.injectDropdowns();
	}

	injectDropdowns() {
		const headingsToElements = DOMUtils.findExportableElements();

		for ( const data of headingsToElements.values() ) {
			let targetNode = data.headingNode;

			// Use parent if it's a heading wrapper
			if ( targetNode.parentNode && targetNode.parentNode.classList.contains( 'mw-heading' ) ) {
				targetNode = targetNode.parentNode;
			}

			// Avoid duplicate dropdowns
			if ( !targetNode.querySelector( '.dropdown-widget' ) ) {
				const dropdown = this.dropdownWidget.create( data.elements, data.headingText );
				targetNode.appendChild( dropdown );
			}
		}
	}

	cleanup() {
		this.imageCache.clear();
		const dropdowns = document.querySelectorAll( '.dropdown-widget' );
		for ( const dropdown of dropdowns ) {
			this.dropdownWidget.cleanup( dropdown );
		}
	}
}

// Initialize module
liquipedia.exportImage = new ExportImageModule();
liquipedia.core.modules.push( 'exportImage' );
