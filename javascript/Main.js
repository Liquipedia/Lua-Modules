/*
 This file is only used for testing purpose and have no impact on actual production.
 The equivalent to this file on production is Special:RLA, and should be kept in sync with it.
*/

// List of JavaScript modules to include
const jsModules = [
	'BattleRoyale',
	'Bracket',
	'Collapse',
	'Commons_mainpage',
	'Commons_tools',
	'CopyToClipboard',
	'Countdown',
	'Crosstable',
	'FilterButtons',
	'Liquipedia_links',
	'Mainpage',
	'Miscellaneous',
	'PanelBoxCollapsible',
	'Prizepooltable',
	'RankingTable',
	'Selectall',
	'Slider',
	'SwitchButtons',
	'Tabs'
];

// Dynamically load JavaScript modules
jsModules.forEach( ( module ) => {
	const script = document.createElement( 'script' );
	script.src = `../../javascript/commons/${ module }.js`;
	script.async = false; // Ensure scripts load in order
	document.head.appendChild( script );
} );

// Initialize liquipedia global object
window.liquipedia = window.liquipedia || {};

// Mock MediaWiki APIs for testing
window.mw = window.mw || {
	config: {
		get: function ( key ) {
			const mockConfig = {
				wgPageName: 'Test_Page',
				wgNamespaceNumber: 0,
				wgServer: 'https://liquipedia.net'
			};
			return mockConfig[ key ];
		}
	},
	user: {
		isAnon: function () {
			return false;
		}
	},
	loader: {
		using: function () {
			return Promise.resolve();
		}
	},
	Api: function () {
		return {
			get: function () {
				return Promise.resolve( {
					query: {
						logevents: [],
						pages: {}
					}
				} );
			}
		};
	}
};

// Auto-initialize all loaded Liquipedia modules
document.addEventListener( 'DOMContentLoaded', () => {
	Object.keys( liquipedia ).forEach( ( module ) => {
		if ( !liquipedia[ module ] || typeof liquipedia[ module ].init !== 'function' ) {
			return;
		}
		try {
			liquipedia[ module ].init();
		} catch ( e ) {
			throw new Error( `Failed to initialize module: ${ module }. Error: ${ e }` );
		}
	} );
} );
