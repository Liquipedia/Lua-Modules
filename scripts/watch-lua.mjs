import chokidar from 'chokidar';
import { spawn } from 'child_process';

const devEnvName = process.env.LUA_DEV_ENV_NAME;

if ( !devEnvName ) {
	console.error( 'LUA_DEV_ENV_NAME is not set. Check your .env file.' );
	process.exit( 1 );
}

console.log( `Lua watcher started. Deploying changes to: ${devEnvName}` );
console.log( 'Watching lua/wikis/**/*.lua ...\n' );

let activeDeployChild = null;

const watcher = chokidar.watch( 'lua/wikis/**/*.lua', {
	awaitWriteFinish: {
		stabilityThreshold: 200,
		pollInterval: 50,
	},
	ignoreInitial: true,
} );

watcher.on( 'change', ( filePath ) => {
	if ( activeDeployChild ) {
		console.log( `[${new Date().toLocaleTimeString()}] Skipping ${filePath} — deploy already in progress.\n` );
		return;
	}

	const time = new Date().toLocaleTimeString();
	console.log( `[${time}] Changed: ${filePath}` );
	console.log( 'Deploying...' );

	const child = spawn( 'python3', [ 'scripts/deploy.py', filePath ], {
		env: process.env,
		stdio: 'inherit',
	} );
	activeDeployChild = child;

	child.on( 'close', ( code ) => {
		if ( code === 0 ) {
			console.log( 'Done.\n' );
		} else {
			console.error( `Deploy failed (exit code ${code})\n` );
		}
		activeDeployChild = null;
	} );

	child.on( 'error', ( err ) => {
		console.error( `Spawn failed: ${err.message}\n` );
		activeDeployChild = null;
	} );
} );
