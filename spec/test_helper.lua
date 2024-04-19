---Enable LLS
-- luacheck: ignore
return function(busted, helper, options)
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

	local function SetActiveWiki(wiki)
		package.preload = {}
		local paths = {}
		table.insert(paths, '?.lua')
		table.insert(paths, 'standard/?.lua')
		if wiki then
			table.insert(paths, 'components/faction/wikis/'.. wiki ..'/?.lua')
			table.insert(paths, 'components/match2/wikis/'.. wiki ..'/?.lua')
			table.insert(paths, 'components/prize_pool/wikis/'.. wiki ..'/?.lua')
			table.insert(paths, 'components/infobox/wikis/'.. wiki ..'/?.lua')
			table.insert(paths, 'components/opponent/wikis/'.. wiki ..'/?.lua')
			table.insert(paths, 'components/hidden_data_box/wikis/'.. wiki ..'/?.lua')
			table.insert(paths, 'components/squad/wikis/'.. wiki ..'/?.lua')
			table.insert(paths, 'components/standings/wikis/'.. wiki ..'/?.lua')
			table.insert(paths, 'standard/info/wikis/'.. wiki ..'/?.lua')
			table.insert(paths, 'standard/region/wikis/'.. wiki ..'/?.lua')
			table.insert(paths, 'standard/tier/wikis/'.. wiki ..'/?.lua')
		end
		table.insert(paths, 'components/faction/commons/?.lua')
		table.insert(paths, 'components/faction/commons/starcraft_starcraft2/?.lua')
		table.insert(paths, 'components/match2/commons/?.lua')
		table.insert(paths, 'components/prize_pool/commons/?.lua')
		table.insert(paths, 'components/infobox/commons/?.lua')
		table.insert(paths, 'components/infobox/extensions/commons/?.lua')
		table.insert(paths, 'components/infobox/commons/custom/?.lua')
		table.insert(paths, 'components/opponent/commons/?.lua')
		table.insert(paths, 'components/opponent/commons/starcraft_starcraft2/?.lua')
		table.insert(paths, 'components/hidden_data_box/commons/?.lua')
		table.insert(paths, 'components/squad/commons/?.lua')
		table.insert(paths, 'components/standings/commons/?.lua')
		table.insert(paths, 'components/team_card/?.lua')
		table.insert(paths, 'standard/info/commons/?.lua')
		table.insert(paths, 'standard/region/commons/?.lua')
		table.insert(paths, 'standard/links/commons/?.lua')
		table.insert(paths, 'standard/tier/commons/?.lua')
		table.insert(paths, 'components/widget/?.lua')

		package.path = table.concat(paths, ';')
	end

	-- Warnings! Extremely time consuming!
	local function allwikis(name, funcToRun, wikiArgs)
		busted.executors.insulate('', function ()
			-- TODO: Build from files in /Info/
			for _, wiki in pairs({'counterstrike', 'starcraft2', 'leagueoflegends'}) do
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

			if fileExists(newName) then
				return require_original(newName)
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

			-- TODO Work away this usage
			if newName == 'games' then
				return {abbr = {}, name = {}}
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
	end

	busted.subscribe({'suite', 'start'}, setupForTesting)
	busted.subscribe({'test', 'end'}, resetMediawiki)

	return true
end