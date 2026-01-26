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
		IMAGE_LOAD: 5000
	},
	COLORS: {
		DARK: {
			BACKGROUND: '#181818',
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
			selector: '.group-table',
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
		if ( this.cache.has( key ) ) {
			return this.cache.get( key );
		}

		return new Promise( ( resolve, reject ) => {
			const image = new Image();
			image.crossOrigin = 'Anonymous';

			const timeoutId = setTimeout( () => {
				image.src = '';
				reject( new Error( `Image load timeout: ${ url }` ) );
			}, timeout );

			image.onload = () => {
				clearTimeout( timeoutId );
				this.cache.set( key, image );
				resolve( image );
			};

			image.onerror = () => {
				clearTimeout( timeoutId );
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
	}

	async compose( sourceCanvas, sectionTitle, isDarkTheme ) {
		const dims = EXPORT_IMAGE_CONFIG.DIMENSIONS;
		const contentWidth = sourceCanvas.width + ( dims.PADDING * 2 );
		const canvasWidth = Math.max( contentWidth, dims.MIN_WIDTH );

		const headerLayout = this.calculateHeaderLayout(
			canvasWidth,
			sectionTitle
		);
		const canvas = this.createCanvas( sourceCanvas, headerLayout.height, canvasWidth );
		const context = canvas.getContext( '2d' );
		const theme = isDarkTheme ? EXPORT_IMAGE_CONFIG.COLORS.DARK : EXPORT_IMAGE_CONFIG.COLORS.LIGHT;

		this.drawBackground( context, canvas.width, canvas.height, theme );
		this.drawHeader( context, canvas.width, theme, headerLayout );
		this.drawContent( context, sourceCanvas, headerLayout.height );
		await this.drawFooter( context, canvas.width, sourceCanvas.height, theme, isDarkTheme, headerLayout.height );

		return canvas;
	}

	createCanvas( sourceCanvas, headerHeight, width ) {
		const dims = EXPORT_IMAGE_CONFIG.DIMENSIONS;
		const canvas = document.createElement( 'canvas' );
		canvas.width = width;
		canvas.height = sourceCanvas.height + headerHeight + dims.FOOTER_HEIGHT + ( dims.PADDING * 4 );
		return canvas;
	}

	drawBackground( context, width, height, theme ) {
		context.fillStyle = theme.BACKGROUND;
		context.fillRect( 0, 0, width, height );
	}

	drawHeader( context, canvasWidth, theme, headerLayout ) {
		const dims = EXPORT_IMAGE_CONFIG.DIMENSIONS;
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
			context.textAlign = 'left';
			const lineHeight = 18;
			const totalLines = headerLayout.mainTitleLines.length + headerLayout.sectionTitleLines.length;
			const startY = dims.PADDING + ( headerLayout.height - ( ( totalLines - 1 ) * lineHeight ) ) / 2;

			let currentY = startY;
			context.font = EXPORT_IMAGE_CONFIG.FONTS.HEADER;
			for ( const line of headerLayout.mainTitleLines ) {
				context.fillText( line, dims.PADDING + dims.HEADER_TEXT_OFFSET, currentY );
				currentY += lineHeight;
			}

			context.font = EXPORT_IMAGE_CONFIG.FONTS.SUBHEADER;
			for ( const line of headerLayout.sectionTitleLines ) {
				context.fillText( line, dims.PADDING + dims.HEADER_TEXT_OFFSET, currentY );
				currentY += lineHeight;
			}
		} else {
			// Default horizontal layout
			const verticalCenter = dims.PADDING + ( headerLayout.height / 2 );

			context.textAlign = 'left';
			context.font = EXPORT_IMAGE_CONFIG.FONTS.HEADER;
			context.fillText(
				headerLayout.mainTitleLines[ 0 ],
				dims.PADDING + dims.HEADER_TEXT_OFFSET,
				verticalCenter
			);

			context.textAlign = 'right';
			context.font = EXPORT_IMAGE_CONFIG.FONTS.SUBHEADER;
			context.fillText(
				headerLayout.sectionTitleLines[ 0 ],
				canvasWidth - dims.PADDING - dims.HEADER_TEXT_OFFSET,
				verticalCenter
			);
		}
	}

	drawContent( context, sourceCanvas, headerHeight ) {
		const dims = EXPORT_IMAGE_CONFIG.DIMENSIONS;
		context.drawImage(
			sourceCanvas,
			dims.PADDING,
			dims.PADDING + headerHeight + dims.PADDING
		);
	}

	async drawFooter( context, canvasWidth, sourceHeight, theme, isDarkTheme, headerHeight ) {
		const dims = EXPORT_IMAGE_CONFIG.DIMENSIONS;
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
		context.font = EXPORT_IMAGE_CONFIG.FONTS.FOOTER;
		context.textAlign = 'left';
		const textY = footerY + ( dims.FOOTER_HEIGHT / 2 );

		this.drawTextWithSpacing(
			context,
			'POWERED BY LIQUIPEDIA',
			dims.PADDING + dims.TEXT_OFFSET_X,
			textY,
			EXPORT_IMAGE_CONFIG.SPACING.LETTER_SPACING
		);

		try {
			await this.drawLogo( context, footerY, isDarkTheme );
		} catch ( error ) {
			// eslint-disable-next-line no-console
			console.warn( 'Logo rendering failed:', error );
		}
	}

	calculateHeaderLayout( canvasWidth, sectionTitle ) {
		const dims = EXPORT_IMAGE_CONFIG.DIMENSIONS;
		const availableWidth = canvasWidth - ( dims.PADDING * 2 ) - ( dims.HEADER_TEXT_OFFSET * 2 );
		const mainTitle = mw.config.get( 'wgDisplayTitle' ) || mw.config.get( 'wgTitle' );

		const dummyCanvas = document.createElement( 'canvas' );
		const context = dummyCanvas.getContext( '2d' );

		context.font = EXPORT_IMAGE_CONFIG.FONTS.HEADER;
		const mainTitleWidth = context.measureText( mainTitle ).width;

		context.font = EXPORT_IMAGE_CONFIG.FONTS.SUBHEADER;
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

		const mainTitleLines = this.wrapText( context, mainTitle, availableWidth, EXPORT_IMAGE_CONFIG.FONTS.HEADER );
		const sectionTitleLines = this.wrapText(
			context,
			sectionTitle,
			availableWidth,
			EXPORT_IMAGE_CONFIG.FONTS.SUBHEADER
		);

		const lineHeight = 18;
		const verticalPadding = 12;
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
			const word = words[ i ];
			const width = context.measureText( currentLine + ' ' + word ).width;
			if ( width <= maxWidth ) {
				currentLine += ' ' + word;
			} else {
				lines.push( currentLine );
				currentLine = word;
			}
		}
		lines.push( currentLine );
		return lines;
	}

	async drawLogo( context, footerY, isDarkTheme ) {
		const dims = EXPORT_IMAGE_CONFIG.DIMENSIONS;
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

	async export( element, title, mode ) {
		const exportId = Symbol( 'export' );

		if ( this.activeExports.size > 0 ) {
			throw new Error( 'An export is already in progress' );
		}

		this.activeExports.add( exportId );
		const originalBackground = element.style.background;

		try {
			await this.ensureHtml2CanvasLoaded();

			const isDarkTheme = document.documentElement.classList.contains( 'theme--dark' );
			const backgroundColor = this.getBackgroundColor();
			element.style.background = backgroundColor;

			const capturedCanvas = await html2canvas( element );
			element.style.background = originalBackground;

			if ( capturedCanvas.width === 0 || capturedCanvas.height === 0 ) {
				throw new Error( 'Canvas capture resulted in zero dimensions' );
			}

			const composedCanvas = await this.canvasComposer.compose( capturedCanvas, title, isDarkTheme );
			await this.outputResult( composedCanvas, mode, this.generateFilename( title ) );

		} finally {
			element.style.background = originalBackground;
			this.activeExports.delete( exportId );
		}
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
		filename = filename.replace( /[\\/:*?"<>|]/g, '_' ).trim();

		if ( filename.length > 215 ) {
			filename = filename.slice( 0, 215 ).trim();
		}

		return filename;
	}

	generateTimestamp() {
		const now = new Date();
		const year = now.getFullYear();
		const month = String( now.getMonth() + 1 ).padStart( 2, '0' );
		const day = String( now.getDate() ).padStart( 2, '0' );
		const hour = String( now.getHours() ).padStart( 2, '0' );
		const min = String( now.getMinutes() ).padStart( 2, '0' );
		const sec = String( now.getSeconds() ).padStart( 2, '0' );
		return `${ year }${ month }${ day }_${ hour }${ min }${ sec }`;
	}

	async outputResult( canvas, mode, filename ) {
		if ( mode === 'download' ) {
			await this.downloadImage( canvas, filename );
		} else if ( mode === 'copy' ) {
			await this.copyToClipboard( canvas );
		} else {
			throw new Error( `Unknown export mode: ${ mode }` );
		}
	}

	async downloadImage( canvas, filename ) {
		const link = document.createElement( 'a' );
		link.download = `${ filename }.png`;
		link.href = canvas.toDataURL( 'image/png' );
		link.click();
	}

	async copyToClipboard( canvas ) {
		if ( !window.ClipboardItem ) {
			throw new Error( 'Clipboard API not supported in this browser' );
		}

		const blob = await new Promise( ( resolve, reject ) => {
			canvas.toBlob( ( result ) => {
				if ( result ) {
					resolve( result );
				} else {
					reject( new Error( 'Failed to create image blob' ) );
				}
			}, 'image/png' );
		} );

		// eslint-disable-next-line compat/compat
		await navigator.clipboard.write( [ new ClipboardItem( { 'image/png': blob } ) ] );
		mw.notify( 'Image copied to clipboard!' );
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
		const walker = document.createTreeWalker( document.body, NodeFilter.SHOW_ELEMENT, null, false );
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

		const computedStyle = window.getComputedStyle( element );
		if ( computedStyle.display === 'none' ||
			computedStyle.visibility === 'hidden' ) {
			return false;
		}

		let parent = element.parentElement;
		while ( parent && parent !== document.body ) {
			const parentStyle = window.getComputedStyle( parent );
			if ( parentStyle.display === 'none' ||
				parentStyle.visibility === 'hidden' ) {
				return false;
			}

			if ( parent.classList.contains( 'collapsed' ) ||
				parent.classList.contains( 'is--collapsed' ) ) {
				return false;
			}

			if ( parent.dataset.collapsibleState === 'collapsed' ) {
				return false;
			}

			const inactiveTab = parent.closest( '.tabs-content > div:not(.active)' );
			if ( inactiveTab ) {
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
		const configs = EXPORT_IMAGE_CONFIG.SELECTORS;

		const headingsToElements = new Map();

		for ( const config of configs ) {
			const elements = document.querySelectorAll( config.selector );
			for ( const element of elements ) {
				const targetElement = config.targetSelector ?
					element.querySelector( config.targetSelector ) :
					element;

				if ( !targetElement ) {
					continue;
				}

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

				const titleElement = config.titleSelector ? element.querySelector( config.titleSelector ) : null;
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
			// Ensure loadingElement is at the end if it was removed or moved
			if ( !menuElement.contains( loadingElement ) ) {
				menuElement.appendChild( loadingElement );
			}

			const visibleElements = elements.filter( ( item ) => DOMUtils.isElementVisible( item.element ) );
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
					const exportTitle = item.title || sectionTitle;

					const copyButton = this.createMenuButton( {
						icon: 'copy',
						buttonText: `Copy ${ typeLabel } image to clipboard`,
						item,
						exportTitle,
						exportMode: 'copy',
						menuElement,
						menuItems,
						loadingElement
					} );
					const downloadButton = this.createMenuButton( {
						icon: 'download',
						buttonText: `Download ${ typeLabel } as image`,
						item,
						exportTitle,
						exportMode: 'download',
						menuElement,
						menuItems,
						loadingElement
					} );
					menuItems.push( copyButton, downloadButton );
				}

				menuItems.forEach( ( item ) => menuElement.insertBefore( item, loadingElement ) );
			}
		};

		// Initial population
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
			await this.handleExport( item.element, exportTitle, exportMode, menuElement, menuItems, loadingElement );
		} );

		return button;
	}

	createToggleButton( menuElement, onOpen ) {
		const iconMargin = EXPORT_IMAGE_CONFIG.SPACING.ICON_MARGIN;
		const buttonContent = `<i class="fas fa-share-alt" style="margin-right: ${ iconMargin };"></i>` +
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
			if ( menuElement.style.display === 'none' && onOpen ) {
				onOpen();
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
		menuItems.forEach( ( item ) => {
			item.style.display = 'none';
		} );
	}

	hideLoading( menuItems, loadingElement ) {
		loadingElement.style.display = 'none';
		menuItems.forEach( ( item ) => {
			item.style.display = '';
		} );
	}

	handleExportError( error ) {
		// eslint-disable-next-line no-console
		console.error( 'Export error:', error );

		let userMessage = 'Export failed. Please try again.';
		if ( error.message?.includes( 'Clipboard' ) ) {
			userMessage = 'Clipboard access denied. Please check your browser permissions.';
		} else if ( error.message?.includes( 'timeout' ) ) {
			userMessage = 'Export timed out. Please try again.';
		} else if ( error.message?.includes( 'in progress' ) ) {
			userMessage = 'An export is already in progress.';
		} else if ( error.message?.includes( 'zero dimensions' ) ) {
			userMessage = 'The content is not visible. Please ensure the tab/section is expanded and try again.';
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

			if ( newLeft < -parentRect.left ) {
				newLeft = -parentRect.left;
			}

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

		switch ( event.key ) {
			case 'Escape':
				event.preventDefault();
				this.closeMenu( menuElement, buttonElement );
				buttonElement.focus();
				break;
			case 'ArrowDown':
				event.preventDefault();
				focusableItems[ ( currentIndex + 1 ) % focusableItems.length ]?.focus();
				break;
			case 'ArrowUp':
				event.preventDefault();
				focusableItems[ ( currentIndex - 1 + focusableItems.length ) % focusableItems.length ]?.focus();
				break;
			case 'Home':
				event.preventDefault();
				focusableItems[ 0 ]?.focus();
				break;
			case 'End':
				event.preventDefault();
				focusableItems[ focusableItems.length - 1 ]?.focus();
				break;
			case 'Enter':
			case ' ':
				event.preventDefault();
				document.activeElement?.click();
				break;
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
		Object.entries( attributes ).forEach( ( [ key, value ] ) => {
			if ( key === 'style' && typeof value === 'object' ) {
				Object.assign( element.style, value );
			} else if ( key === 'dataset' && typeof value === 'object' ) {
				Object.assign( element.dataset, value );
			} else {
				element.setAttribute( key, value );
			}
		} );
		if ( typeof children === 'string' ) {
			element.innerHTML = children;
		} else if ( Array.isArray( children ) ) {
			children.forEach( ( child ) => child && element.appendChild( child ) );
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
 * Main module class that coordinates all components
 */
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
		const headingsToElements = DOMUtils.findExportableElements();

		for ( const data of headingsToElements.values() ) {
			let targetNode = data.headingNode;
			if ( targetNode.parentNode?.classList.contains( 'mw-heading' ) ) {
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
		const dropdowns = document.querySelectorAll( '.dropdown-widget' );
		dropdowns.forEach( ( dropdown ) => this.dropdownWidget.cleanup( dropdown ) );
	}
}

// Export for liquipedia integration
liquipedia.exportImage = new ExportImageModule();
liquipedia.core.modules.push( 'exportImage' );
