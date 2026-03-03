/*******************************************************************************
 * Template(s): MatchPage
 ******************************************************************************/
liquipedia.matchpage = {
	init: function() {
		if ( mw.config.get( 'wgUserId' ) === null ) {
			return;
		} else if ( mw.config.get( 'wgPostEdit' ) === null ) {
			return;
		} else if ( mw.config.get( 'wgNamespaceNumber' ) !== 130 ) {
			return;
		}
		const matchPage = document.querySelector( '.match-bm' );
		if ( !matchPage ) {
			return;
		}
		const bracketPage = matchPage.getAttribute( 'data-matchPage-bracket-page' );
		if ( !bracketPage ) {
			return;
		}
		mw.loader.using( [ 'mediawiki.api' ] ).then( () => {
			const api = new mw.Api();
			api.post( {
				action: 'purge',
				format: 'json',
				titles: bracketPage,
				forcelinkupdate: true
			} ).then( () => {
				mw.notify( 'Tournament page purged' );
			} ).catch( () => {
				mw.notify( 'Tournament page purge failed' );
			} );
		} );
	}
};
liquipedia.core.modules.push( 'matchpage' );
