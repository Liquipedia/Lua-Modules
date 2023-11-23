-- luacheck: ignore

-- Copy from standard/lua.lua
local function fileExists(name)
	if package.loaded[name] then
		return true
	else
		-- Package.Searchers was renamed from Loaders in lua5.2, have support for both
		---@diagnostic disable-next-line: deprecated
		for _, searcher in ipairs(package.searchers or package.loaders) do
			local loader = searcher(name)
			if type(loader) == 'function' then
				package.preload[name] = loader
				return true
			end
		end
		return false
	end
end

local function resetMediawiki()
	mw.ext.VariablesLua.variablesStorage = {}
end

local function setupForTesting()
	require('definitions.mw')

	package.path = '?.lua;' ..
			'standard/?.lua;' .. -- Load std folder
			package.path

	local require_original = require
	local Plugin = require_original('plugins.sumneko_plugin')

	function require(module)
		local newName = module
		if (string.find(module, 'Module:')) then
			newName = Plugin.luaifyModuleName(module)
		end

		if fileExists(newName) then
			return require_original(newName)
		end

		if newName == 'info' then
			return require_original('info.commons.info')
		end

		if newName == 'region' or newName == 'region_data' then
			return require('region.commons.' .. newName)
		end

		if newName == 'opponent' then
			return require('components.opponent.commons.opponent')
		end

		if newName == 'feature_flag_config' then
			return {
				award_table = {defaultValue = false},
				debug_import = {defaultValue = false},
				debug_match_history = {defaultValue = false},
				debug_placement = {defaultValue = false},
				debug_query = {defaultValue = false},
				dev = {defaultValue = false},
				force_type_check = {defaultValue = false},
				next = {defaultValue = false},
				perf = {defaultValue = false},
				perf_rich_reporter = {defaultValue = true},
				random_errors = {defaultValue = false},
				team_list = {defaultValue = false},
			}
		end

		-- Just apply a fake function that returns the first input, as something
		local mocked_import = {}
		setmetatable(mocked_import, {
			__index = function(t, k)
				return function(v) return v end
			end
		})

		return mocked_import
	end
end

require('busted').subscribe({'suite', 'start'}, setupForTesting)
require('busted').subscribe({'test', 'start'}, resetMediawiki)
