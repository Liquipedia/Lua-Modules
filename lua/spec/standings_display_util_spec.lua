--- Triple Comment to Enable our LLS Plugin
describe('Standings display util', function()
	local Array = require('Module:Array')
	local StandingsDisplayUtil = require('Module:Standings/DisplayUtil')

	---@param additionalStats StandingsAdditionalStat[]
	---@return StandingsModel
	local function makeStandings(additionalStats)
		---@diagnostic disable-next-line: missing-fields
		return {additionalStats = additionalStats}
	end

	describe('rounds to show', function()
		---@param startedRounds boolean[]
		---@return StandingsModel
		local function makeRounds(startedRounds)
			---@diagnostic disable-next-line: missing-fields
			return {rounds = Array.map(startedRounds, function(started, index)
				return {round = index, started = started}
			end)}
		end

		it('shows every started round', function()
			assert.are_equal(2, StandingsDisplayUtil.roundsToShow(makeRounds{true, true, false}))
		end)

		it('shows the first round before any round has started', function()
			assert.are_equal(1, StandingsDisplayUtil.roundsToShow(makeRounds{false, false}))
		end)
	end)

	describe('bold stat title', function()
		it('is the column of the first tiebreaker, not of a stat that is always shown', function()
			local standings = makeStandings{
				{id = 'full.matchdiff', title = 'Matches'},
				{id = 'full.gamediff', title = 'Games'},
				{id = 'full.disqualified', tiebreaker = true},
				{id = 'full.points', title = 'Points', tiebreaker = true},
				{id = 'full.manual', tiebreaker = true},
			}
			assert.are_equal('Points', StandingsDisplayUtil.boldStatTitle(standings))
		end)

		it('is the shared column when the first tiebreaker shares it with a stat that is always shown', function()
			local standings = makeStandings{
				{id = 'full.matchdiff', title = 'Matches'},
				{id = 'full.gamediff', title = 'Games'},
				{id = 'full.matchscore', title = 'Matches', tiebreaker = true},
				{id = 'full.manual', tiebreaker = true},
			}
			assert.are_equal('Matches', StandingsDisplayUtil.boldStatTitle(standings))
		end)

		it('skips tiebreakers without a column', function()
			local standings = makeStandings{
				{id = 'full.matchdiff', title = 'Matches'},
				{id = 'ml.matchscore', tiebreaker = true},
				{id = 'full.gamediff', title = 'Games', tiebreaker = true},
			}
			assert.are_equal('Games', StandingsDisplayUtil.boldStatTitle(standings))
		end)

		it('is nil when no tiebreaker has a column', function()
			local standings = makeStandings{
				{id = 'full.matchdiff', title = 'Matches'},
				{id = 'full.manual', tiebreaker = true},
			}
			assert.is_nil(StandingsDisplayUtil.boldStatTitle(standings))
		end)

		it('is the first column for standings stored before tiebreakers were marked', function()
			local standings = makeStandings{
				{id = 'full.disqualified'},
				{id = 'full.matchdiff', title = 'Matches'},
				{id = 'full.points', title = 'Points'},
			}
			assert.are_equal('Matches', StandingsDisplayUtil.boldStatTitle(standings))
		end)
	end)
end)
