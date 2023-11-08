-- luacheck: ignore

-- Copy from Standard/lua.lua
local function fileExists(name)
	if package.loaded[name] then
		return true
	else
		-- Package.Searchers was renamed from Loaders in lua5.2, have support for both
		---@diagnostic disable-next-line: deprecated
		for _, searcher in ipairs(package.searchers or package.loaders) do
			local loader = searcher(name)
			if type(loader) == 'function' then
				-- luacheck: ignore
				-- luacheck complains about package.preload being read-only
				package.preload[name] = loader
				return true
			end
		end
		return false
	end
end

local function mockRequire()
	local require_original = require
	local Plugin = require_original('sumneko_plugin')

	function require(module)
		local newName = module
		if (string.find(module, 'Module:')) then
			newName = Plugin.luaifyModuleName(module)
		end

		if fileExists(newName) then
			return require_original(newName)
		end

		-- Just apply a fake function that returns the first input, as something
		local mocked_import = {}
		setmetatable(mocked_import, {
			__index = function (t, k)
				return function(v) return v end
			end
		})

		return mocked_import
	end
 end


require("busted").subscribe({"suite", "start"}, mockRequire)