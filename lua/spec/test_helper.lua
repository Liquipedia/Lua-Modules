---@meta
-- luacheck: ignore

---@param wiki string?
function SetActiveWiki(wiki) error('SOMETHING WENT WRONG') end

---@param name string
---@param funcToRun fun(args: table, name: string)
---@param wikiArgs {default: {}?, [any]: {}}
---@return function
function allwikis(name, funcToRun, wikiArgs) error('SOMETHING WENT WRONG') end

---@param testname string
---@param actual string
function GoldenTest(testname, actual) error('SOMETHING WENT WRONG') end

return function(busted, helper, options)
	-- Copy from standard/lua.lua
	local function fileExists(name)
		if package.loaded[name] then
			return true
		else
			for _, searcher in ipairs(package.loaders) do
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

	local preloadByWiki = {}
	local activeWiki
	local function SetActiveWiki(wiki)
		wiki = wiki or ''
		if activeWiki == wiki then
			return
		end
		preloadByWiki[activeWiki or ''] = package.preload
		package.preload = preloadByWiki[wiki] or {}
		activeWiki = wiki
		local paths = {}
		table.insert(paths, '?.lua')
		if wiki ~= '' then
			table.insert(paths, 'wikis/'.. wiki ..'/?.lua')
			table.insert(paths, 'wikis/'.. wiki ..'/faction/?.lua')
			table.insert(paths, 'wikis/'.. wiki ..'/match2/?.lua')
			table.insert(paths, 'wikis/'.. wiki ..'/prize_pool/?.lua')
			table.insert(paths, 'wikis/'.. wiki ..'/infobox/?.lua')
			table.insert(paths, 'wikis/'.. wiki ..'/opponent/?.lua')
			table.insert(paths, 'wikis/'.. wiki ..'/hidden_data_box/?.lua')
			table.insert(paths, 'wikis/'.. wiki ..'/squad/?.lua')
			table.insert(paths, 'wikis/'.. wiki ..'/standings/?.lua')
			table.insert(paths, 'wikis/'.. wiki ..'/transfer/?.lua')
			table.insert(paths, 'wikis/'.. wiki ..'/highlight_conditions/?.lua')
		end
		table.insert(paths, 'wikis/commons/?.lua')
		table.insert(paths, 'wikis/commons/faction/?.lua')
		table.insert(paths, 'wikis/commons/faction/starcraft_starcraft2/?.lua')
		table.insert(paths, 'wikis/commons/faction/?.lua')
		table.insert(paths, 'wikis/commons/hidden_data_box/?.lua')
		table.insert(paths, 'wikis/commons/highlight_conditions/?.lua')
		table.insert(paths, 'wikis/commons/infobox/?.lua')
		table.insert(paths, 'wikis/commons/infobox/extensions/?.lua')
		table.insert(paths, 'wikis/commons/infobox/custom/?.lua')
		table.insert(paths, 'wikis/commons/links/?.lua')
		table.insert(paths, 'wikis/commons/opponent/?.lua')
		table.insert(paths, 'wikis/commons/opponent/starcraft_starcraft2/?.lua')
		table.insert(paths, 'wikis/commons/match2/?.lua')
		table.insert(paths, 'wikis/commons/match2/starcraft_starcraft2/?.lua')
		table.insert(paths, 'wikis/commons/prize_pool/?.lua')
		table.insert(paths, 'wikis/commons/region/?.lua')
		table.insert(paths, 'wikis/commons/tier/?.lua')
		table.insert(paths, 'wikis/commons/squad/?.lua')
		table.insert(paths, 'wikis/commons/standings/?.lua')
		table.insert(paths, 'wikis/commons/team_card/?.lua')
		table.insert(paths, 'wikis/commons/transfer/?.lua')
		table.insert(paths, 'wikis/commons/standard/?.lua')
		table.insert(paths, 'wikis/commons/widget/?.lua')
		table.insert(paths, 'wikis/commons/widget/basic/?.lua')
		table.insert(paths, 'wikis/commons/widget/contexts/?.lua')
		table.insert(paths, 'wikis/commons/widget/html/?.lua')
		table.insert(paths, 'wikis/commons/widget/infobox/?.lua')
		table.insert(paths, 'wikis/commons/widget/image/?.lua')
		table.insert(paths, 'wikis/commons/widget/match/summary/?.lua')
		table.insert(paths, 'wikis/commons/widget/match/summary/ffa/?.lua')
		table.insert(paths, 'wikis/commons/widget/misc/?.lua')
		table.insert(paths, 'wikis/commons/widget/squad/?.lua')

		package.path = table.concat(paths, ';')
	end

	--[[
	This will generate all wikis based on wiki folders files
	local wikis = {}
	local pfile = io.popen('ls -a "wikis"')
	if pfile then
		for filename in pfile:lines() do
			-- TODO add check for . and ..
			table.insert(wikis, filename)
		end
		pfile:close()
	else
		error('Could not locate wikis')
	end]]

	-- Top 10 wikis based on traffic
	local wikis = {'dota2', 'valorant', 'counterstrike', 'rocketleague', 'mobilelegends', 'leagueoflegends', 'apexlegends', 'rainbowsix', 'overwatch', 'starcraft2'}
	-- Warnings! Extremely time consuming if different filesystems (eg. windows files with wsl)
	local function allwikis(name, funcToRun, wikiArgs)
		busted.executors.insulate('', function ()
			for _, wiki in ipairs(wikis) do
				busted.executors.insulate(wiki, function ()
					busted.executors.it(name, function()
						SetActiveWiki(wiki)
						funcToRun(wikiArgs[wiki] or wikiArgs.default, wiki)
					end)
				end)
			end
			busted.executors.teardown(function ()
				SetActiveWiki()
			end)
		end)
	end

	local function writeGolden(filename, data)
		local file = assert(io.open(filename, 'w+'))
		file:write(data)
	end

	local function GoldenTest(testname, actual)
		local filename = 'spec/golden_masters/' .. testname .. '.txt'
		local file = io.open(filename, 'r')
		actual = tostring(actual)

		---@diagnostic disable-next-line: undefined-field
		if not file or _G.updategolden == true then
			writeGolden(filename, actual)
			return
		end

		local expected = file:read('*a')
		file:close()

		require('luassert').are_same(expected, actual)
	end

	local function setupForTesting()
		busted.export('allwikis', allwikis)
		busted.export('GoldenTest', GoldenTest)
		busted.export('SetActiveWiki', SetActiveWiki)

		require('definitions.mw')

		SetActiveWiki()

		local require_original = require
		local Plugin = require_original('plugins.sumneko_plugin')

		local function attemptImport(module)
			local newName = module
			if (string.find(module, 'Module:')) then
				newName = Plugin.luaifyModuleName(module)
			end

			if newName == 'arguments' then
				return {getArgs = function(t) return t end}
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

			-- TODO This should be added to git
			if newName == 'team_template' then
				return {
					getPageName = function(s) return s end
				}
			end

			if fileExists(newName) then
				return require_original(newName)
			end
		end

		function require(module)
			local imported = attemptImport(module)
			if imported then
				return imported
			end

			local mocked_import = {}
			setmetatable(mocked_import, {
				__index = function(t, k)
					print('Warning!', 'called', module, '.', k, 'but', module, 'was unable to be imported')
				end
			})

			return mocked_import
		end
		local stub = require('luassert.stub')
		stub(require('Module:Lua'), 'requireIfExists', attemptImport)
		stub(require('Module:Lua'), 'moduleExists', function(file)
			return attemptImport(file) ~= nil
		end)
	end

	busted.subscribe({'suite', 'start'}, setupForTesting)
	busted.subscribe({'test', 'end'}, resetMediawiki)

	return true
end
