-- luacheck: ignore
--- Triple Comment to Enable our LLS Plugin
describe('ProfileTabs Api', function()
	local ProfileTabsApiDisplayTitle = require('Module:Features/ProfileTabs/Api/DisplayTitle')
	local ProfileTabsApiMatches = require('Module:Features/ProfileTabs/Api/Matches')

	local playerData = {
		{pagename = 'SyntacticSalt', id = 'SyntacticSalt'},
	}
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
	before_each(function()
		originalLpdb = mw.ext.LiquipediaDB.lpdb
		---@diagnostic disable-next-line: duplicate-set-field
		mw.ext.LiquipediaDB.lpdb = function(dbTable, params)
			local rows = {}
			if (dbTable == 'player') then
				rows = playerData
			elseif (dbTable == 'match2') then
				rows = match2Data
			end
			return applyConditions(rows, params.conditions)
		end
	end)

	after_each(function()
		---@diagnostic disable-next-line: duplicate-set-field
		mw.ext.LiquipediaDB.lpdb = originalLpdb
	end)

	describe('DisplayTitle.get', function()
		it('should return the stored display field (id) for a player', function()
			assert.are.equal('SyntacticSalt', ProfileTabsApiDisplayTitle.get('player', 'SyntacticSalt'))
		end)

		it('should return nil when the player does not exist', function()
			assert.is_nil(ProfileTabsApiDisplayTitle.get('player', 'NoSuchProfile'))
		end)
	end)

	describe('Matches.has', function()
		it('should return true when the player has lpdb matches', function()
			assert.is_true(ProfileTabsApiMatches.has('player', 'SyntacticSalt'))
		end)

		it('should return false when the player has no lpdb matches', function()
			assert.is_false(ProfileTabsApiMatches.has('player', 'NoSuchProfile'))
		end)

		it('should match teams by the opponent field', function()
			assert.is_true(ProfileTabsApiMatches.has('team', 'SyntacticSalt'))
			assert.is_false(ProfileTabsApiMatches.has('team', 'NoSuchProfile'))
		end)
	end)
end)
