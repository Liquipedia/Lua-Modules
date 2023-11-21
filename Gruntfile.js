/* eslint-env node */
module.exports = function( grunt ) {
	grunt.loadNpmTasks( 'grunt-eslint' );

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
		}
	} );

	grunt.registerTask( 'main', [ 'eslint' ] );
	grunt.registerTask( 'default', 'test' );
};
