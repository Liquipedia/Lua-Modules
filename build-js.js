const fs = require( 'fs' ).promises;
const path = require( 'path' );

const modulesDir = path.join( __dirname, 'javascript' );
const mainJsPath = path.join( modulesDir, 'Main.js' );
const commonsDir = path.join( modulesDir, 'commons' );
const outFile = path.join( __dirname, 'lua', 'output', 'js', 'main.js' );

function extractJsModules( content ) {
	const modulesMatch = content.match( /const jsModules = (\[[\s\S]*?\]);/ );
	if ( !modulesMatch ) {
		throw new Error( 'Could not find jsModules array in Main.js' );
	}
	return JSON.parse( modulesMatch[ 1 ].replace( /'/g, '"' ) );
}

async function concatenateModules( moduleNames ) {
	const moduleContents = await Promise.all(
		moduleNames.map( async ( moduleName ) => {
			const modulePath = path.join( commonsDir, `${ moduleName }.js` );
			try {
				return await fs.readFile( modulePath, 'utf8' );
			} catch ( e ) {
				console.warn( `Warning: Could not read ${ modulePath }` );
				return null;
			}
		} )
	);

	const validContents = moduleContents.filter( ( content ) => content !== null );
	const modulesString = validContents.map( ( content ) => content + '\n;\n' ).join( '' );

	return '// --- INJECTED LOCAL MODULES ---\n\n' +
        modulesString +
        '// --- END OF INJECTED MODULES ---\n';
}

function removeOriginalCode( content ) {
	const listRegex = /const jsModules = (\[[\s\S]*?\]);/m;
	const dynamicLoaderRegex = /(\/\/ Dynamically load JavaScript modules[\s\S]*?}\s*\);)/m;

	return content
		.replace( listRegex, '// --- jsModules list removed by build script ---' )
		.replace( dynamicLoaderRegex, '// --- Dynamic loader replaced by build script ---' );
}

async function build() {
	console.log( 'Building JS by injecting modules into Main.js...' );

	try {
		const mainJsContent = await fs.readFile( mainJsPath, 'utf8' );
		const moduleNames = extractJsModules( mainJsContent ).filter( ( name ) => name !== 'Analytics' );
		const concatenatedModules = await concatenateModules( moduleNames );
		const processedMainContent = removeOriginalCode( mainJsContent );

		const warningMessage = "console.warn('Browser is using locally compiled JavaScript, and cannot be fully trusted to match the production counterpart.')";
		// Expose liquipedia on window so the dev proxy can detect and re-initialize modules.
		// Core.js uses `const liquipedia` (correct for production), but `const` is not
		// accessible as window.liquipedia, which the dev proxy requires.
		const exposeOnWindow = 'window.liquipedia = liquipedia;';
		const concatenatedModulesWithExpose = concatenatedModules.replace(
			/(const liquipedia\s*=\s*(?:window\.liquipedia\s*\|\|\s*)?\{[^}]*\};)/,
			`$1\n${ exposeOnWindow }`
		);
		const finalContent = warningMessage + processedMainContent + '\n\n' + concatenatedModulesWithExpose;

		await fs.mkdir( path.dirname( outFile ), { recursive: true } );
		await fs.writeFile( outFile, finalContent );
		console.log( 'JS build complete! Output to lua/output/js/main.js' );
	} catch ( error ) {
		console.error( 'JS Build FAILED:' );
		console.error( error.message );
		process.exit( 1 );
	}
}

build();
