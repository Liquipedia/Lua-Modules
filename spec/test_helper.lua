 -- luacheck: ignore
local function mockRequire()
	package.path = '?.lua;' ..
		-- Load plugin for module name parsing
		'../plugins/?.lua;' ..
		'plugins/?.lua;' ..
		-- Load test files
		'test/standard/?.lua;' ..
		-- Load main files
		'../standard/?.lua;' ..
		'standard/?.lua;' ..
		package.path

	require('sumneko_plugin')

	local require_original = require

	function require(module)
		local newName = module
		if (string.find(module, 'Module:')) then
			newName = LuaifyModuleName(module)
		end

		return require_original(newName)
	end
 end


require("busted").subscribe({"suite", "start"}, mockRequire)