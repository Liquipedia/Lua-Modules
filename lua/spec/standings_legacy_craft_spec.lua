--- Triple Comment to Enable our LLS Plugin
describe('Standings Legacy Craft', function()
	local StandingTableLegacyCraft = require('Module:Standings/Table/Legacy/Craft')
	local StandingTableLegacyNext = require('Module:Standings/Table/Legacy/Next')
	local TiebreakerFactory = require('Module:Standings/Tiebreaker/Factory')
	local Variables = require('Module:Variables')

	local UPDATED_DEFAULTS = {'matchscore', 'gamescore', 'ml.matchscore', 'ml.gamescore'}

	after_each(function()
		Variables.varDefine('tournament_startdate', nil)
	end)

	it('uses the updated default tiebreakers', function()
		assert.are_same(UPDATED_DEFAULTS, StandingTableLegacyCraft.defaultTiebreakers{})
		Variables.varDefine('tournament_startdate', '2022-03-20')
		assert.are_same(UPDATED_DEFAULTS, StandingTableLegacyCraft.defaultTiebreakers{})
		assert.are_same(
			{'points', 'matchscore', 'gamescore', 'ml.matchscore', 'ml.gamescore'},
			StandingTableLegacyCraft.defaultTiebreakers{show_p = 'true'}
		)
		for _, tiebreaker in ipairs(UPDATED_DEFAULTS) do
			TiebreakerFactory.validateAndNormalizeInput(tiebreaker)
		end
	end)

	it('keeps the GroupTableLeague default tiebreakers for older tournaments', function()
		Variables.varDefine('tournament_startdate', '2022-03-19')
		assert.are_same(StandingTableLegacyNext.defaultTiebreakers{}, StandingTableLegacyCraft.defaultTiebreakers{})
	end)

	it('only uses the defaults without tiebreaker input', function()
		assert.are_same({'gamediff'}, StandingTableLegacyNext.parseTiebreakers(
			{tiebreaker1 = 'diff'}, StandingTableLegacyCraft.defaultTiebreakers
		))
		assert.are_same(UPDATED_DEFAULTS, StandingTableLegacyNext.parseTiebreakers(
			{}, StandingTableLegacyCraft.defaultTiebreakers
		))
	end)
end)
