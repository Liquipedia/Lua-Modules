/* eslint-env node */
module.exports = function( grunt ) {
	grunt.loadNpmTasks( 'grunt-eslint' );
	grunt.loadNpmTasks( 'grunt-stylelint' );

	grunt.initConfig( {
		eslint: {
			options: {
				fix: grunt.option( 'fix' )
			},
			all: [
				'javascript/**/*.{js,json,vue}'
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
	grunt.registerTask( 'default', 'test' );
};
