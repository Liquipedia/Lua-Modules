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
			'standard/?.lua;' ..
			'components/match2/commons/?.lua;' ..
			'components/prize_pool/commons/?.lua;' ..
			'components/infobox/commons/?.lua;' ..
			'components/infobox/commons/custom/?.lua;' ..
			'components/opponent/commons/?.lua;' ..
			'components/hidden_data_box/commons/?.lua;' ..
			'components/squad/commons/?.lua;' ..
			'components/standings/commons/?.lua;' ..
			'components/team_card/?.lua;' ..
			'standard/info/commons/?.lua;' ..
			'standard/region/commons/?.lua;' ..
			'standard/tier/commons/?.lua;' ..
			'components/widget/?.lua;' ..
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

		if newName == 'points_data' then
			return {points = {title = 'Points'}}
		end

		if newName == 'a or an' then
			return {_main = function(params)
				-- Simplified implemenation for mocking
				local firstChar = string.sub(params[1], 1, 1):lower()
				if firstChar == 'a' or firstChar == 'e' or firstChar == 'i' or firstChar == 'o' or firstChar == 'u' then
					return 'an '
				end
				return 'a '
			end}
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

local function writeGolden(filename, data)
	local file = assert(io.open(filename, 'w+'))
	file:write(data)
end

function GoldenTest(testname, actual)
	local filename = 'spec/golden_masters/' .. testname .. '.txt'
	local file = io.open(filename, 'r')

	---@diagnostic disable-next-line: undefined-field
	if not file or _G.updategolden == true then
		writeGolden(filename, actual)
		return
	end

	local expected = file:read('*a')
	file:close()

	require('luassert').are_same(expected, actual)
end

require('busted').subscribe({'suite', 'start'}, setupForTesting)
require('busted').subscribe({'test', 'end'}, resetMediawiki)
