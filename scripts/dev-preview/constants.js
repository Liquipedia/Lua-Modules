const path = require( 'path' );

const repoRoot = path.resolve( __dirname, '..', '..' );

const DEV_DIR = path.join( repoRoot, '.dev-preview' );

module.exports = {
	REPO_ROOT: repoRoot,
	DEV_DIR,
	PROFILE_DIR: path.join( DEV_DIR, 'profile' ),
	// mitmdump keeps its generated CA here rather than in ~/.mitmproxy, so it is
	// disposable along with the rest of .dev-preview. Nothing is ever installed
	// into a trust store — the throwaway browser profile ignores cert errors.
	MITM_CONFDIR: path.join( DEV_DIR, 'mitmproxy' ),
	// Watcher → proxy handshake. Content is "<buildId> <kinds>", e.g.
	// "1754400000000 css,js". Written atomically here, read (never consumed) by
	// scripts/proxy_lp.py.
	MARKER_FILE: path.join( DEV_DIR, 'rebuild_marker' ),
	PROXY_SCRIPT: path.join( repoRoot, 'scripts', 'proxy_lp.py' ),
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
