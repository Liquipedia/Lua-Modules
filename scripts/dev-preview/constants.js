const path = require( 'path' );

const repoRoot = path.resolve( __dirname, '..', '..' );

const DEV_DIR = path.join( repoRoot, '.dev-preview' );

module.exports = {
	REPO_ROOT: repoRoot,
	OUTPUT_CSS: path.join( repoRoot, 'lua', 'output', 'css', 'main.css' ),
	OUTPUT_JS: path.join( repoRoot, 'lua', 'output', 'js', 'main.js' ),
	DEV_DIR,
	PROFILE_DIR: path.join( DEV_DIR, 'profile' ),
	CA_DIR: path.join( DEV_DIR, 'ca' ),
	DEFAULT_PORT: 8081,
	WATCH_GLOBS: [ 'stylesheets/**/*.scss', 'javascript/**/*.js' ],
	// First existing entry wins. LP_DEV_BROWSER env overrides all of this.
	BROWSER_CANDIDATES: {
		linux: [
			'/usr/bin/google-chrome',
			'/usr/bin/google-chrome-stable',
			'/usr/bin/chromium',
			'/usr/bin/chromium-browser',
			'/usr/bin/brave-browser',
			'/opt/brave-bin/brave',
			'/usr/bin/microsoft-edge'
		],
		darwin: [
			'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
			'/Applications/Chromium.app/Contents/MacOS/Chromium',
			'/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
			'/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge'
		],
		win32: [
			'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
			'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
			'C:\\Program Files\\BraveSoftware\\Brave-Browser\\Application\\brave.exe',
			'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe'
		]
	}
};
