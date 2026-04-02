// @ts-nocheck
import chokidar from 'chokidar';
import { spawn } from 'child_process';

const devEnvName = process.argv[ 2 ]
	? `/dev/${process.argv[ 2 ]}`
	: process.env.LUA_DEV_ENV_NAME;

if ( !devEnvName ) {
	console.error( 'Usage: npm run watch:lua -- <dev-env-name>' );
	console.error( 'Or set LUA_DEV_ENV_NAME in your .env file.' );
	process.exit( 1 );
}

console.log( `Lua watcher started. Deploying changes to: ${devEnvName}` );
console.log( 'Watching lua/wikis/**/*.lua...\n' );

const queue = [];
let deployingFile = null;

function processQueue() {
	if ( deployingFile !== null || queue.length === 0 ) {
		return;
	}
	deployingFile = queue.shift();

	const time = new Date().toLocaleTimeString();
	const queueInfo = queue.length > 0 ? ` (${queue.length} more queued)` : '';
	console.log( `[${time}] Deploying: ${deployingFile}${queueInfo}` );

	const child = spawn( 'python3', [ 'scripts/deploy.py', deployingFile ], {
		env: {
			...process.env,
			WIKI_USER: process.env.LP_BOTUSER,
			WIKI_PASSWORD: process.env.LP_BOTPASSWORD,
			WIKI_BASE_URL: process.env.LP_BASE_URL,
			WIKI_UA_EMAIL: process.env.LP_UA_EMAIL,
		},
		stdio: 'inherit',
	} );

	child.on( 'close', ( code ) => {
		if ( code === 0 ) {
			console.log( 'Done.\n' );
		} else {
			console.error( `Deploy failed (exit code ${code})\n` );
		}
		deployingFile = null;
		processQueue();
	} );

	child.on( 'error', ( err ) => {
		console.error( `Spawn failed: ${err.message}\n` );
		deployingFile = null;
		processQueue();
	} );
}

const watcher = chokidar.watch( 'lua/wikis', {
	ignored: ( path, stats ) => stats?.isFile() && !path.endsWith( '.lua' ),
	awaitWriteFinish: {
		stabilityThreshold: 200,
		pollInterval: 50,
	},
	ignoreInitial: true,
} );

watcher.on( 'change', ( filePath ) => {
	if ( queue.includes( filePath ) ) {
		return;
	}
	queue.push( filePath );
	processQueue();
} );
