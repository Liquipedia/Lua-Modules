/* eslint-env node */
module.exports = function( grunt ) {
	grunt.loadNpmTasks( 'grunt-stylelint' );

	grunt.initConfig( {
		stylelint: {
			options: {
				fix: grunt.option( 'fix' )
			},
			all: [
				'**/*.{css,scss,less}',
				'!node_modules/**',
				'!vendor/**'
			]
		}
	} );

	grunt.registerTask( 'main', [ 'stylelint' ] );
	grunt.registerTask( 'default', 'test' );
};
