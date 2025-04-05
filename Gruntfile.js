/* eslint-env node */
module.exports = function( grunt ) {
	grunt.loadNpmTasks( 'grunt-eslint' );
	grunt.loadNpmTasks( 'grunt-stylelint' );

	grunt.initConfig( {
		/**
		 * @TODO: Add support for javascript subdirectory again
		 * Upsteam eslint config does not support eslint v9 yet
		 * Tracking ticket https://github.com/wikimedia/eslint-config-wikimedia/issues/563
		**/
		eslint: {
			options: {
				fix: grunt.option( 'fix' ),
				overrideConfigFile: 'eslint.config.mjs',
			},
			src: [
				'lua/wikis/**/*.{ts,tsx}'
			]
		},
		stylelint: {
			options: {
				fix: grunt.option( 'fix' )
			},
			all: [
				'stylesheets/**/*.{css,scss,less}'
			]
		}
	} );

	grunt.registerTask( 'main', [ 'eslint', 'stylelint' ] );
	grunt.registerTask( 'default', 'main' );
};
