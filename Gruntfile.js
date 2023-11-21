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
				'**/*.{js,json,vue}',
				'!node_modules/**',
				'!vendor/**'
			]
		},
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

	grunt.registerTask( 'main', [ 'eslint', 'stylelint' ] );
	grunt.registerTask( 'default', 'test' );
};
