/* eslint-env node */
module.exports = function( grunt ) {
	grunt.loadNpmTasks( 'grunt-eslint' );
	grunt.loadNpmTasks( 'grunt-stylelint' );
	grunt.loadNpmTasks( 'grunt-contrib-less' );

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
		},
		less: {
			options: {
				compress: false,
				yuicompress: false,
				optimization: 0
			},
			foobar: {
				expand: true,
				cwd: 'stylesheets/',
				src: [ '**/*.less' ],
				dest: 'stylesheets/complied/',
				ext: '.css'
			}
		}
	} );

	grunt.registerTask( 'main', [ 'eslint', 'stylelint' ] );
	grunt.registerTask( 'default', [ 'test', 'less' ] );
};
