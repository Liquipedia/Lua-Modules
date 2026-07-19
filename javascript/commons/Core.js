/*******************************************************************************
 * Template(s): JavaScript Core
 * Author(s): FO-nTTaX
 * Information: All modules need to have a parameterless init function. The script
 * calls this init function in an asynchronous way so a failing module can not
 * stop the execution of the rest of the scripts. A slow script will also not
 * block execution of other modules. The script does not check for dependencies
 * (impossible to do since modules are in different files), so these need to be
 * resolved manually. Modules need to register themselves into the core part of
 * the liquipedia.core.modules array, so the script can find them.
 ******************************************************************************/
const liquipedia = { };
liquipedia.core = {
	modules: [ ],
	init: function() {
		liquipedia.core.modules.forEach( ( module ) => {
			// Usage of setTimeout to make scripts asynchronous
			window.setTimeout( () => {
				liquipedia[ module ].init();
			}, 0 );
		} );
	}
};
