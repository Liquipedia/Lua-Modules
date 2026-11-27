/*******************************************************************************
 * Template(s): localStorage helper
 * Information: Wraps window.localStorage so blocked or full storage (e.g. some
 * private browsing modes) never throws. Reads fall back to null or the given
 * default, writes are dropped silently.
 ******************************************************************************/
liquipedia.storage = {
	/**
	 * @param {string} key
	 * @return {string|null}
	 */
	get: function( key ) {
		try {
			return window.localStorage.getItem( key );
		} catch {
			return null;
		}
	},

	/**
	 * @param {string} key
	 * @param {string} value
	 * @return {void}
	 */
	set: function( key, value ) {
		try {
			window.localStorage.setItem( key, value );
		} catch {}
	},

	/**
	 * @param {string} key
	 * @return {void}
	 */
	remove: function( key ) {
		try {
			window.localStorage.removeItem( key );
		} catch {}
	},

	/**
	 * @param {string} key
	 * @param {*} fallback returned when the key is missing or holds invalid JSON
	 * @return {*}
	 */
	getJson: function( key, fallback ) {
		const value = this.get( key );
		if ( value === null ) {
			return fallback;
		}
		try {
			return JSON.parse( value );
		} catch {
			return fallback;
		}
	},

	/**
	 * @param {string} key
	 * @param {*} value
	 * @return {void}
	 */
	setJson: function( key, value ) {
		this.set( key, JSON.stringify( value ) );
	}
};
