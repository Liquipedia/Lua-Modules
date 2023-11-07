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

	local require_original = require
	local plugin = require_original('sumneko_plugin')

	function require(module)
		local newName = module
		if (string.find(module, 'Module:')) then
			newName = plugin.luaifyModuleName(module)
		end

		return require_original(newName)
	end
 end


require("busted").subscribe({"suite", "start"}, mockRequire)