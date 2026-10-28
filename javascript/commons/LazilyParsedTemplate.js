/*******************************************************************************
 Template(s): Lazily parsed templates
 *******************************************************************************/

/**
 * Parse errors raised by lazily parsed templates.
 */
class LazilyParsedTemplateParseError extends Error {
	/**
	 * @param {string?} message
	 * @param {object?} options
	 */
	constructor( message, options ) {
		super( message, options );

		this.name = 'LazilyParsedTemplateParseError';

		if ( Error.captureStackTrace ) {
			Error.captureStackTrace( this, this.constructor );
		}
	}
}

class LazilyParsedTemplateParser {
	/**
	 * @param {HTMLElement} element
	 */
	constructor( element ) {
		this.element = element;
		this.template = this.element.dataset.template;
		if ( typeof this.template !== 'string' ) {
			throw new LazilyParsedTemplateParseError( 'Template not set' );
		}
		this.parameters = JSON.parse( element.innerHTML.toString() );
	}

	/**
	 * Cache for preventing API calls with the same wikicode.
	 *
	 * @type {Map<string, string>}
	 */
	static wikicodeCache = new Map();

	/**
	 * @param {string} wikicode
	 * @return {Promise<string?>}
	 */
	static async parseWikicode( wikicode ) {
		if ( LazilyParsedTemplateParser.wikicodeCache.has( wikicode ) ) {
			return LazilyParsedTemplateParser.wikicodeCache.get( wikicode );
		}
		await mw.loader.using( [ 'mediawiki.api' ] );
		const api = new mw.Api();
		const apiResponse = await api.get( {
			action: 'parse',
			format: 'json',
			contentmodel: 'wikitext',
			maxage: 600,
			smaxage: 600,
			disablelimitreport: true,
			uselang: 'content',
			prop: 'text',
			text: wikicode
		} );
		const parsedText = apiResponse.parse?.text?.[ '*' ];
		if ( parsedText ) {
			LazilyParsedTemplateParser.wikicodeCache.set( wikicode, parsedText );
			return parsedText;
		}
		return null;
	}

	#buildParameterWikicode() {
		const parameterEntries = Object.entries( this.parameters );
		if ( parameterEntries.length === 0 ) {
			return '';
		}
		const paramParts = [ '' ];
		for ( const entry of parameterEntries ) {
			paramParts.push( entry.join( '=' ).replaceAll( '|', '{{!}}' ) );

		}
		return paramParts.join( '|' );
	}

	async loadTemplate() {
		this.element.classList.add( 'loaded' );
		this.element.innerHTML = await LazilyParsedTemplateParser.parseWikicode(
			`{{${ this.template }${ this.#buildParameterWikicode() }}}`
		);
	}
}

( () => {
	const lazilyCalledTemplates = Array.from(
		document.querySelectorAll( '.lp-lazily-called-template:not( .loaded )' )
	);
	if ( lazilyCalledTemplates.length === 0 ) {
		return;
	}
	return Promise.allSettled( lazilyCalledTemplates.map(
		( lazilyCalledTemplate ) => new LazilyParsedTemplateParser( lazilyCalledTemplate ).loadTemplate()
	) );
} )();
