/* global snapdom */

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

/**
 * Handles export operations (DOM composition, canvas capture, download, clipboard)
 */
class ExportService {
	constructor() {
		this.snapdomLoaded = false;
		this.activeExports = new Set();
	}

	// element itself may match the selector, not just its descendants.
	queryAllIncludingSelf( element, selector ) {
		const matches = [ ...element.querySelectorAll( selector ) ];
		if ( element.matches( selector ) ) {
			matches.push( element );
		}
		return matches;
	}

	// Cut placements are hidden by `.collapsed` on the wrapper; expand so they export.
	expandPrizepoolTables( element ) {
		const collapsedTables = this.queryAllIncludingSelf( element, '.prizepool-table-wrapper.collapsed' );

		for ( const collapsedTable of collapsedTables ) {
			collapsedTable.classList.remove( 'collapsed' );
		}

		return collapsedTables;
	}

	// Shallow ancestor shells keep ancestor-scoped CSS (e.g. theme--dark) applying to the clone.
	// `content` sits at the bottom of the spine, so it has to be fully assembled before this
	// runs: the returned root is the only node attached to the document, and anything left
	// outside it is detached and lays out at zero size.
	buildAncestorSpine( element, content ) {
		let root = content;
		let descendant = element;
		let ancestor = element.parentElement;

		while ( ancestor ) {
			const shallowClone = ancestor.cloneNode( false );
			shallowClone.appendChild( root );
			this.carrySwitchState( ancestor, descendant, shallowClone );
			root = shallowClone;
			descendant = ancestor;
			ancestor = ancestor.parentElement;
		}

		return root;
	}

	// Switch state is read by CSS with `:has()` scoped to an ancestor — e.g. the participants
	// "Compact view" toggle via `.team-participant:has( .switch-toggle-active[...] )` — but the
	// toggles themselves sit in sibling controls the shallow shells drop, so those rules stop
	// matching and the clone exports in its default state. Re-add them under the same shell so
	// the scoping still resolves; `:has()` matches regardless of `display`, and these live
	// outside the captured wrapper, so they never reach the image.
	carrySwitchState( ancestor, descendant, shallowClone ) {
		const switchElements = ancestor.querySelectorAll( '.switch-toggle, .switch-pill' );

		for ( const switchElement of switchElements ) {
			// Anything inside `descendant` is already carried by the level below.
			if ( descendant.contains( switchElement ) ) {
				continue;
			}

			const switchClone = switchElement.cloneNode( true );
			switchClone.style.display = 'none';
			shallowClone.appendChild( switchClone );
		}
	}

	// Brackets.scss forces `--match-width: var( --match-width-mobile ) !important` under 768px,
	// so a bracket exported from a phone renders at the cramped mobile width instead of the
	// desktop one baked into the markup as `style="--match-width:190px"`. A stylesheet
	// `!important` only loses to another `!important` of equal-or-higher specificity, and an
	// inline declaration outranks any selector — so re-declaring the clone's own existing value
	// as `!important` restores the desktop width without rebuilding the page in a sandboxed
	// viewport (which previously broke unrelated `:has()`-driven toggles when their stylesheets
	// were re-applied fresh at a forced width).
	normalizeBracketWidth( element ) {
		const brackets = this.queryAllIncludingSelf( element, '.brkts-bracket' );

		for ( const bracket of brackets ) {
			const desktopWidth = bracket.style.getPropertyValue( '--match-width' );
			if ( desktopWidth ) {
				bracket.style.setProperty( '--match-width', desktopWidth, 'important' );
			}
		}
	}

	// The capture root is `position: fixed` with no explicit width (needed to move it offscreen
	// without affecting page layout), so it — and every plain block-level ancestor shell below
	// it — sizes to shrink-to-fit. Per the CSS Grid spec, `repeat( auto-fill/auto-fit, ... )`
	// collapses to a single track whenever the grid container has no definite size, which is why
	// clones of e.g. `.team-participant__grid` always render as one column regardless of device
	// or viewport, even though the live grid (laid out in normal document flow, where it has a
	// definite width) shows several. Copying each live grid's already-resolved column list onto
	// the corresponding clone sidesteps the recompute rather than fighting it.
	preserveGridLayout( liveRoot, clonedRoot ) {
		const liveNodes = this.queryAllIncludingSelf( liveRoot, '*' );
		const clonedNodes = this.queryAllIncludingSelf( clonedRoot, '*' );

		liveNodes.forEach( ( liveNode, index ) => {
			const display = window.getComputedStyle( liveNode ).display;
			if ( display === 'grid' || display === 'inline-grid' ) {
				clonedNodes[ index ].style.gridTemplateColumns =
					window.getComputedStyle( liveNode ).gridTemplateColumns;
			}
		} );
	}

	// A `grid-template-columns: subgrid` root (e.g. `.brkts-matchlist-collapse-area`) loses its tracks once buildAncestorSpine() reparents it under a plain flex wrapper, so bake the live parent's resolved pixel tracks onto the clone to make it self-contained.
	resolveSubgridRoot( element, target ) {
		if ( window.getComputedStyle( element ).gridTemplateColumns.startsWith( 'subgrid' ) ) {
			target.style.display = 'grid';
			target.style.gridTemplateColumns = window.getComputedStyle( element.parentElement ).gridTemplateColumns;
		}
	}

	// snapdom doesn't wait for images; undecoded ones can be missing or collapse row heights.
	async waitForImages( element, timeout = EXPORT_IMAGE_CONFIG.TIMEOUTS.IMAGE_LOAD ) {
		const images = this.queryAllIncludingSelf( element, 'img' );

		await Promise.all( images.map( ( image ) => Promise.race( [
			image.decode ? image.decode().catch( () => {} ) : Promise.resolve(),
			new Promise( ( resolve ) => {
				setTimeout( resolve, timeout );
			} )
		] ) ) );
	}

	createLogoImage( isDarkTheme ) {
		const dims = EXPORT_IMAGE_CONFIG.DIMENSIONS;
		const logo = document.createElement( 'img' );

		logo.crossOrigin = 'anonymous';
		logo.src = isDarkTheme ? EXPORT_IMAGE_CONFIG.LOGOS.DARK : EXPORT_IMAGE_CONFIG.LOGOS.LIGHT;
		logo.width = dims.LOGO_WIDTH;
		logo.height = dims.LOGO_HEIGHT;
		logo.style.display = 'block';
		logo.style.flex = 'none';

		return logo;
	}

	buildHeaderElement( sectionTitle, isDarkTheme, dims ) {
		const theme = isDarkTheme ? EXPORT_IMAGE_CONFIG.COLORS.DARK : EXPORT_IMAGE_CONFIG.COLORS.LIGHT;

		const mainTitle = document.createElement( 'span' );
		mainTitle.textContent = mw.config.get( 'wgDisplayTitle' ) || mw.config.get( 'wgTitle' );
		Object.assign( mainTitle.style, { font: EXPORT_IMAGE_CONFIG.FONTS.HEADER, color: '#ffffff' } );

		const subTitle = document.createElement( 'span' );
		subTitle.textContent = sectionTitle;
		Object.assign( subTitle.style, { font: EXPORT_IMAGE_CONFIG.FONTS.SUBHEADER, color: '#ffffff' } );

		const header = document.createElement( 'div' );
		Object.assign( header.style, {
			display: 'flex',
			flexWrap: 'wrap',
			alignItems: 'center',
			justifyContent: 'space-between',
			rowGap: '4px',
			minHeight: `${ dims.HEADER_HEIGHT }px`,
			padding: `4px ${ dims.HEADER_TEXT_OFFSET }px`,
			borderRadius: `${ dims.BORDER_RADIUS }px`,
			background: `linear-gradient(to right, ${ theme.HEADER_START }, ${ theme.HEADER_END })`,
			boxSizing: 'border-box'
		} );
		header.append( mainTitle, subTitle );

		return header;
	}

	buildFooterElement( isDarkTheme, dims ) {
		const theme = isDarkTheme ? EXPORT_IMAGE_CONFIG.COLORS.DARK : EXPORT_IMAGE_CONFIG.COLORS.LIGHT;

		const logo = this.createLogoImage( isDarkTheme );
		logo.style.marginLeft = `${ dims.LOGO_OFFSET_X }px`;

		const text = document.createElement( 'span' );
		text.textContent = 'POWERED BY LIQUIPEDIA';
		Object.assign( text.style, {
			font: EXPORT_IMAGE_CONFIG.FONTS.FOOTER,
			color: theme.TEXT,
			letterSpacing: `${ EXPORT_IMAGE_CONFIG.SPACING.LETTER_SPACING }px`,
			marginLeft: `${ dims.TEXT_OFFSET_X - dims.LOGO_OFFSET_X - dims.LOGO_WIDTH }px`
		} );

		const footer = document.createElement( 'div' );
		Object.assign( footer.style, {
			display: 'flex',
			alignItems: 'center',
			height: `${ dims.FOOTER_HEIGHT }px`,
			borderRadius: `${ dims.BORDER_RADIUS }px`,
			background: `linear-gradient(to right, ${ theme.FOOTER_START }, ${ theme.FOOTER_END })`,
			boxSizing: 'border-box'
		} );
		footer.append( logo, text );

		return footer;
	}

	wrapWithHeaderFooter( target, sectionTitle, isDarkTheme ) {
		const dims = EXPORT_IMAGE_CONFIG.DIMENSIONS;
		const theme = isDarkTheme ? EXPORT_IMAGE_CONFIG.COLORS.DARK : EXPORT_IMAGE_CONFIG.COLORS.LIGHT;

		const wrapper = document.createElement( 'div' );
		Object.assign( wrapper.style, {
			display: 'flex',
			flexDirection: 'column',
			gap: `${ dims.PADDING }px`,
			padding: `${ dims.PADDING }px`,
			width: 'fit-content',
			minWidth: `${ dims.MIN_WIDTH }px`,
			background: theme.BACKGROUND,
			boxSizing: 'border-box'
		} );

		target.style.alignSelf = 'flex-start';

		wrapper.append(
			this.buildHeaderElement( sectionTitle, isDarkTheme, dims ),
			target,
			this.buildFooterElement( isDarkTheme, dims )
		);

		return wrapper;
	}

	async export( element, title, mode ) {
		// Prevent concurrent exports
		if ( this.activeExports.size > 0 ) {
			throw new Error( 'An export is already in progress' );
		}

		const exportId = Symbol( 'export' );
		this.activeExports.add( exportId );

		try {
			await this.ensureSnapdomLoaded();

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

	// On WebKit (every iOS browser), snapdom renders shadowed content at native size then resamples it up to avoid corrupting box/text-shadow, which softens the result — so exports need to detect it and compensate.
	isSafariBrowser() {
		const ua = navigator.userAgent;
		return /safari/i.test( ua ) && !/chrome|android|crios|fxios|edg/i.test( ua );
	}

	async generateImageBlob( element, title ) {
		const isDarkTheme = document.documentElement.classList.contains( 'theme--dark' );
		const backgroundColor = this.getBackgroundColor();
		const frameBackground = isDarkTheme ?
			EXPORT_IMAGE_CONFIG.COLORS.DARK.BACKGROUND :
			EXPORT_IMAGE_CONFIG.COLORS.LIGHT.BACKGROUND;
		const dpr = window.devicePixelRatio || 1;
		// Safari gets a higher ceiling to oversample past its shadow-safe resample blur (see isSafariBrowser()); everyone else keeps the original, size-conscious 2-3x range.
		const scale = this.isSafariBrowser() ?
			Math.min( Math.max( dpr, 3 ), 4 ) :
			Math.min( Math.max( dpr, 2 ), 3 );

		const target = element.cloneNode( true );

		// Must run before the clone is detached/repositioned, while `element` is still the
		// correctly-laid-out live reference to copy resolved grid columns from.
		this.preserveGridLayout( element, target );
		this.resolveSubgridRoot( element, target );

		// Mutates the clone, not the live page, so nothing needs restoring afterwards.
		target.style.background = backgroundColor;
		this.expandPrizepoolTables( target );
		this.normalizeBracketWidth( target );

		// The wrapper is what gets captured, so the spine has to be built around it —
		// wrapWithHeaderFooter() moves `target` inside, leaving it orphaned otherwise.
		const wrapper = this.wrapWithHeaderFooter( target, title, isDarkTheme );
		const root = this.buildAncestorSpine( element, wrapper );

		root.style.position = 'fixed';
		root.style.top = '-99999px';
		root.style.left = '-99999px';
		document.body.appendChild( root );

		try {
			if ( document.fonts && document.fonts.ready ) {
				await document.fonts.ready;
			}
			await this.waitForImages( wrapper );

			const capturedCanvas = await snapdom.toCanvas( wrapper, {
				scale: scale,
				dpr: 1,
				backgroundColor: frameBackground,
				reconcile: true,
				fast: false,
				exclude: [
					'.switch-pill-container',
					'.prizepooltabletoggle',
					'.prizepool-table-wrapper .table2__footer'
				],
				excludeMode: 'remove',
				filter: ( capturedElement ) => !capturedElement.matches( '.brkts-match-info-icon' ),
				filterMode: 'hide'
			} );

			if ( capturedCanvas.width === 0 || capturedCanvas.height === 0 ) {
				throw new Error( 'Canvas capture resulted in zero dimensions' );
			}

			return new Promise( ( resolve, reject ) => {
				capturedCanvas.toBlob( ( blob ) => {
					if ( blob ) {
						resolve( blob );
					} else {
						reject( new Error( 'Failed to create image blob' ) );
					}
				}, 'image/png' );
			} );
		} finally {
			root.remove();
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

		// Clean up object URL after short delay
		setTimeout( () => {
			URL.revokeObjectURL( url );
		}, EXPORT_IMAGE_CONFIG.TIMEOUTS.URL_REVOKE_DELAY );
	}

	async ensureSnapdomLoaded() {
		if ( this.snapdomLoaded ) {
			return;
		}

		return new Promise( ( resolve ) => {
			mw.loader.using( 'snapdom', () => {
				this.snapdomLoaded = true;
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
			while ( menuElement.firstChild && menuElement.firstChild !== loadingElement ) {
				menuElement.removeChild( menuElement.firstChild );
			}

			if ( !menuElement.contains( loadingElement ) ) {
				menuElement.appendChild( loadingElement );
			}

			if ( this.zoomManager.hasZoomed ) {
				const refreshItem = this.createRefreshMenuItem();
				menuElement.insertBefore( refreshItem, loadingElement );
				return;
			}

			// Filter visible elements
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
			class: 'button button--ghost button--extrasmall dropdown-widget__toggle',
			type: 'button',
			title: 'Share',
			'aria-label': 'Share this content',
			'aria-expanded': 'false',
			'aria-haspopup': 'true'
		}, buttonContent );

		button.addEventListener( 'click', () => {
			if ( menuElement.style.display === 'none' ) {
				this.exportService.ensureSnapdomLoaded();
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
		this.exportService = new ExportService();
		this.zoomManager = new ZoomManager();
		this.dropdownWidget = new DropdownWidget( this.exportService, this.zoomManager );
	}

	init() {
		this.injectDropdowns();
	}

	injectDropdowns() {
		const headingsToElements = ExportImageDOMUtils.findExportableElements();

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
		const dropdowns = document.querySelectorAll( '.dropdown-widget' );
		for ( const dropdown of dropdowns ) {
			this.dropdownWidget.cleanup( dropdown );
		}
	}
}

liquipedia.exportImage = new ExportImageModule();
liquipedia.core.modules.push( 'exportImage' );
