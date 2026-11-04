-- luacheck: ignore
--- Triple Comment to Enable our LLS Plugin
describe('ProfileTabs Components', function()
	local ProfileTabsTabs = require('Module:Features/ProfileTabs/Components/Tabs')
	local PROFILE_TYPES = require('Module:Features/ProfileTabs/Types')

	local match2Data = {
		{player = 'SyntacticSalt', opponent = 'SyntacticSalt'},
		{player = 'SyntacticSalt', opponent = 'SyntacticSalt'},
	}

	local applyConditions = function(rows, conditions)
		local field, value = conditions:match('%[%[(%a+)::(.-)]]')
		if (not field) then
			return {}
		end
		local result = {}
		for _, row in ipairs(rows) do
			if (row[field] == value) then
				table.insert(result, row)
			end
		end
		return result
	end

	local originalLpdb

	local function expectedMediawikiUrl(mediawikiForm, template, queryArg, profile)
		return tostring(mw.uri.fullUrl(
			'Special:RunQuery/' .. mediawikiForm,
			{[template .. '[' .. queryArg .. ']'] = profile}
		)):gsub(' ', '%%20')
	end

	local function expectedPlayerH2HUrl(profile)
		return expectedMediawikiUrl('Match history', 'Head_to_head_query', 'player', profile)
	end

	local function expectedTeamH2HUrl(profile)
		return expectedMediawikiUrl('Head2head', 'Headtohead', 'team', profile)
	end

	local function expectedPlayerStatsUrl(profile)
		return expectedMediawikiUrl('PlayerStats', 'PlayerStatistics', 'player', profile)
	end

	local function expectedPlayerResultsUrl(profile)
		return expectedMediawikiUrl('Player Results', 'Player results', 'player', profile)
	end

	local function expectedPlayerMatchesUrl(profile)
		return expectedMediawikiUrl('Player Matches', 'Player matches', 'player', profile)
	end

	local function expectedTeamResultsUrl(profile)
		return expectedMediawikiUrl('Team Results', 'Team results', 'team', profile)
	end

	local function expectedTeamMatchesUrl(profile)
		return expectedMediawikiUrl('Team Matches', 'Team matches', 'team', profile)
	end

	local function expectedTeamPlayerResultsUrl(profile)
		return expectedMediawikiUrl('Team Player Results', 'Team player results', 'team', profile)
	end

	local function withExistingPages(existingPages, func)
		local existing = {}
		for _, page in ipairs(existingPages) do
			existing[page] = true
		end
		mw.title.new = function(page)
			return {exists = existing[page] == true}
		end
		return func()
	end

	local function withH2HVariable(func)
		mw.ext.VariablesLua.vardefine('h2h', 'true')
		return func()
	end

	local function withStatisticsVariable(func)
		mw.ext.VariablesLua.vardefine('statistics', 'true')
		return func()
	end

	local function withTabsToFormsVariable(func)
		mw.ext.VariablesLua.vardefine('tabsToForms', 'true')
		return func()
	end


	describe('getTabArgs', function()
		before_each(function()
			originalLpdb = mw.ext.LiquipediaDB.lpdb
			---@diagnostic disable-next-line: duplicate-set-field
			mw.ext.LiquipediaDB.lpdb = function(dbTable, params)
				local rows = {}
				if (dbTable == 'match2') then
					rows = match2Data
				end
				return applyConditions(rows, params.conditions)
			end
		end)

		after_each(function()
			---@diagnostic disable-next-line: duplicate-set-field
			mw.ext.LiquipediaDB.lpdb = originalLpdb
		end)

		it('should always include the Overview tab', function()
			withExistingPages({}, function()
				local result = ProfileTabsTabs.getTabArgs('player', 'NoSuchProfile')
				assert.are.equal('Overview', result.name1)
				assert.are.equal('NoSuchProfile', result.link1)
				assert.is_nil(result.name2)
			end)
		end)

		it('should only include tabs whose subpage exists', function()
			withExistingPages({'NoSuchProfile/Results', 'NoSuchProfile/Awards'}, function()
				local result = ProfileTabsTabs.getTabArgs('player', 'NoSuchProfile')
				assert.are.equal('Results', result.name2)
				assert.are.equal('NoSuchProfile/Results', result.link2)
				assert.are.equal('Awards', result.name3)
				assert.are.equal('NoSuchProfile/Awards', result.link3)
				assert.is_nil(result.name4)
			end)
		end)

		it('should preserve the hardcoded tab order for players', function()
			local allTabs = {}
			for _, tabName in ipairs(PROFILE_TYPES.player.tabs) do
				table.insert(allTabs, 'NoSuchProfile/' .. tabName)
			end
			withExistingPages(allTabs, function()
				local result = ProfileTabsTabs.getTabArgs('player', 'NoSuchProfile')
				for index, tabName in ipairs(PROFILE_TYPES.player.tabs) do
					local expectedName = PROFILE_TYPES.player.tabDisplay and PROFILE_TYPES.player.tabDisplay[tabName]
						or tabName
					assert.are.equal(expectedName, result['name' .. (index + 1)])
					assert.are.equal('NoSuchProfile/' .. tabName, result['link' .. (index + 1)])
				end
			end)
		end)

		it('should display Talent for the Broadcasts tab while linking to Broadcasts', function()
			withExistingPages({'NoSuchProfile/Broadcasts'}, function()
				local result = ProfileTabsTabs.getTabArgs('player', 'NoSuchProfile')
				assert.are.equal('Talent', result.name2)
				assert.are.equal('NoSuchProfile/Broadcasts', result.link2)
				assert.is_nil(result.name3)
			end)
		end)

		it('should use the team tab list', function()
			withExistingPages({'NoSuchProfile/Teamkills', 'NoSuchProfile/Results'}, function()
				local result = ProfileTabsTabs.getTabArgs('team', 'NoSuchProfile')
				assert.are.equal('Results', result.name2)
				assert.are.equal('Teamkills', result.name3)
				-- Results exists, but h2h is not set, so no Head to head tab
				assert.is_nil(result.name4)
			end)
		end)

		it('should add a Head to head QueryLink when Results exists and h2h is set', function()
			withExistingPages({'NoSuchProfile/Results'}, function()
				withH2HVariable(function()
					local result = ProfileTabsTabs.getTabArgs('player', 'NoSuchProfile')
					assert.are.equal('table', type(result.name3))
					-- The QueryLink widget provides the link itself, no separate link arg
					assert.is_nil(result.link3)
					assert.is_nil(result.name4)

					local rendered = tostring(result.name3)
					assert.is_true(rendered:find(expectedPlayerH2HUrl('NoSuchProfile'), nil, true) ~= nil)
					assert.is_true(rendered:find('Head to head', nil, true) ~= nil)
				end)
			end)
		end)

		it('should use the team query arg for teams', function()
			withExistingPages({'NoSuchProfile/Results'}, function()
				withH2HVariable(function()
					local result = ProfileTabsTabs.getTabArgs('team', 'NoSuchProfile')
					local rendered = tostring(result.name3)
					assert.is_true(rendered:find(expectedTeamH2HUrl('NoSuchProfile'), nil, true) ~= nil)
				end)
			end)
		end)

		it('should not add the Head to head tab without Results', function()
			withExistingPages({'NoSuchProfile/Awards'}, function()
				withH2HVariable(function()
					local result = ProfileTabsTabs.getTabArgs('player', 'NoSuchProfile')
					assert.are.equal('Awards', result.name2)
					assert.is_nil(result.name3)
				end)
			end)
		end)

		it('should not add the Head to head tab when the h2h variable is not set', function()
			withExistingPages({'NoSuchProfile/Results'}, function()
				local result = ProfileTabsTabs.getTabArgs('player', 'NoSuchProfile')
				assert.are.equal('Results', result.name2)
				assert.is_nil(result.name3)
			end)
		end)

		it('should add a Statistics QueryLink when Results exists and statistics is set', function()
			withExistingPages({'NoSuchProfile/Results'}, function()
				withStatisticsVariable(function()
					local result = ProfileTabsTabs.getTabArgs('player', 'NoSuchProfile')
					assert.are.equal('table', type(result.name3))
					-- The QueryLink widget provides the link itself, no separate link arg
					assert.is_nil(result.link3)
					assert.is_nil(result.name4)

					local rendered = tostring(result.name3)
					assert.is_true(rendered:find(expectedPlayerStatsUrl('NoSuchProfile'), nil, true) ~= nil)
					assert.is_true(rendered:find('Statistics', nil, true) ~= nil)
				end)
			end)
		end)

		it('should not add the Statistics tab when the statistics variable is not set', function()
			withExistingPages({'NoSuchProfile/Results'}, function()
				local result = ProfileTabsTabs.getTabArgs('player', 'NoSuchProfile')
				assert.are.equal('Results', result.name2)
				assert.is_nil(result.name3)
			end)
		end)

		it('should add both the Head to head and Statistics tabs when both variables are set', function()
			withExistingPages({'NoSuchProfile/Results'}, function()
				withH2HVariable(function()
					withStatisticsVariable(function()
						local result = ProfileTabsTabs.getTabArgs('player', 'NoSuchProfile')
						assert.are.equal('table', type(result.name3))
						assert.are.equal('table', type(result.name4))
						assert.is_nil(result.name5)

						local h2h = tostring(result.name3)
						assert.is_true(h2h:find('Head to head', nil, true) ~= nil)
						local stats = tostring(result.name4)
						assert.is_true(stats:find(expectedPlayerStatsUrl('NoSuchProfile'), nil, true) ~= nil)
					end)
				end)
			end)
		end)

		it('should add the Head to head tab when h2h is passed as a template arg', function()
			withExistingPages({'NoSuchProfile/Results'}, function()
				local result = ProfileTabsTabs.getTabArgs('player', 'NoSuchProfile', {h2h = 'true'})
				assert.are.equal('table', type(result.name3))

				local rendered = tostring(result.name3)
				assert.is_true(rendered:find(expectedPlayerH2HUrl('NoSuchProfile'), nil, true) ~= nil)
				assert.is_true(rendered:find('Head to head', nil, true) ~= nil)
			end)
		end)

		it('should let a template arg override a wiki variable false', function()
			withExistingPages({'NoSuchProfile/Results'}, function()
				withH2HVariable(function()
					local result = ProfileTabsTabs.getTabArgs('player', 'NoSuchProfile', {h2h = 'no'})
					assert.are.equal('Results', result.name2)
					assert.is_nil(result.name3)
				end)
			end)
		end)

		it('should add the Head to head tab based on lpdb matches when the Results subpage is missing', function()
			withExistingPages({}, function()
				withH2HVariable(function()
					local result = ProfileTabsTabs.getTabArgs('player', 'SyntacticSalt')
					assert.are.equal('table', type(result.name2))
					assert.is_nil(result.name3)

					local rendered = tostring(result.name2)
					assert.is_true(rendered:find(expectedPlayerH2HUrl('SyntacticSalt'), nil, true) ~= nil)
				end)
			end)
		end)


		it('should replace the Results tab with a Player Results QueryLink when tabsToForms is set', function()
			withExistingPages({'NoSuchProfile/Results'}, function()
				withTabsToFormsVariable(function()
					local result = ProfileTabsTabs.getTabArgs('player', 'NoSuchProfile')
					-- Results slot is taken over by the query form tab: name2 is the QueryLink,
					-- there is no separate link2 argument
					assert.are.equal('table', type(result.name2))
					assert.is_nil(result.link2)

					local rendered = tostring(result.name2)
					assert.is_true(rendered:find(expectedPlayerResultsUrl('NoSuchProfile'), nil, true) ~= nil)
					assert.is_true(rendered:find('Results', nil, true) ~= nil)
				end)
			end)
		end)

		it('should replace the Played Matches tab with a Player Matches QueryLink when tabsToForms is set', function()
			withExistingPages({'NoSuchProfile/Results', 'NoSuchProfile/Played Matches'}, function()
				withTabsToFormsVariable(function()
					local result = ProfileTabsTabs.getTabArgs('player', 'NoSuchProfile')
					assert.are.equal('table', type(result.name3))
					assert.is_nil(result.link3)

					local rendered = tostring(result.name3)
					assert.is_true(rendered:find(expectedPlayerMatchesUrl('NoSuchProfile'), nil, true) ~= nil)
					assert.is_true(rendered:find('Matches', nil, true) ~= nil)
				end)
			end)
		end)

		it('should not replace tabs when the tabsToForms variable is not set', function()
			withExistingPages({'NoSuchProfile/Results'}, function()
				local result = ProfileTabsTabs.getTabArgs('player', 'NoSuchProfile')
				assert.are.equal('Results', result.name2)
				assert.are.equal('NoSuchProfile/Results', result.link2)
				assert.is_nil(result.name3)
			end)
		end)

		it('should replace team tabs with query form tabs when tabsToForms is set', function()
			withExistingPages({'SyntacticSalt/Results'}, function()
				withTabsToFormsVariable(function()
					local result = ProfileTabsTabs.getTabArgs('team', 'SyntacticSalt')
					-- Results, Played Matches and Player Results take over the first three slots
					assert.are.equal('table', type(result.name2))
					assert.are.equal('table', type(result.name3))
					assert.are.equal('table', type(result.name4))
					assert.is_nil(result.name5)

					assert.is_true(tostring(result.name2):find(expectedTeamResultsUrl('SyntacticSalt'), nil, true) ~= nil)
					assert.is_true(tostring(result.name3):find(expectedTeamMatchesUrl('SyntacticSalt'), nil, true) ~= nil)
					assert.is_true(tostring(result.name4):find(expectedTeamPlayerResultsUrl('SyntacticSalt'), nil, true) ~= nil)
				end)
			end)
		end)
	end)
end)
