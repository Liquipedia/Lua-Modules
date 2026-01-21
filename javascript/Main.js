/*
 This file is only used for testing purpose and have no impact on actual production.
 The equivalent to this file on production is Special:RLA, and should be kept in sync with it.
*/

// List of JavaScript modules to include
const jsModules = [
	'Analytics',
	'BattleRoyale',
	'Bracket',
	'Carousel',
	'Collapse',
	'Commons_mainpage',
	'Commons_tools',
	'CopyToClipboard',
	'Countdown',
	'Crosstable',
	'Dropdown',
	'Dialog',
	'ExportImage',
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
window.liquipedia = window.liquipedia || {
	core: {
		modules: []
	}
};

// Mock MediaWiki APIs for testing
window.mw = window.mw || {
	config: {
		get: function ( key ) {
			const mockConfig = {
				wgPageName: 'Test_Page',
				wgNamespaceNumber: 0,
				wgServer: 'https://liquipedia.net',
				wgScriptPath: ''
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

// Auto-initialize all loaded modules
onload = () => {
	liquipedia.core.modules.forEach( ( module ) => {
		if ( !liquipedia[ module ] || typeof liquipedia[ module ].init !== 'function' ) {
			return;
		}
		try {
			liquipedia[ module ].init();
		} catch ( e ) {
			// eslint-disable-next-line no-console
			console.error( `Failed to initialize module: ${ module }. Error: ${ e }` );
		}
	} );
};
