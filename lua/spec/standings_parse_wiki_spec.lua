--- Triple Comment to Enable our LLS Plugin
describe('Standings Wiki Parser', function()
	local StandingsParseWiki = require('Module:Standings/Parse/Wiki')

	describe('rounds', function()
		it('reads the manual started and finished input', function()
			local round = StandingsParseWiki.parseWikiRound({started = 'true', finished = 'false'}, 1)
			assert.is_true(round.started)
			assert.is_false(round.finished)
		end)

		it('leaves the status unset without manual input, regardless of the dates', function()
			local round = StandingsParseWiki.parseWikiRound({sdate = '2020-01-01', edate = '2020-01-02'}, 1)
			assert.is_nil(round.started)
			assert.is_nil(round.finished)
		end)
	end)

	describe('disqualifications', function()
		it('reads dq input as the first round of disqualification', function()
			assert.are_equal(1, StandingsParseWiki.parseDisqualifiedFromRound('true'))
			assert.are_equal(1, StandingsParseWiki.parseDisqualifiedFromRound(true))
			assert.are_equal(2, StandingsParseWiki.parseDisqualifiedFromRound('2'))
			assert.are_equal(3, StandingsParseWiki.parseDisqualifiedFromRound(3))
			assert.is_nil(StandingsParseWiki.parseDisqualifiedFromRound('false'))
			assert.is_nil(StandingsParseWiki.parseDisqualifiedFromRound(''))
			assert.is_nil(StandingsParseWiki.parseDisqualifiedFromRound(nil))
		end)

		it('stores the disqualification round on the parsed opponent', function()
			local dqAll = StandingsParseWiki.parseWikiOpponent({type = 'literal', 'Alpha', dq = 'true'}, 2)
			local dqFromTwo = StandingsParseWiki.parseWikiOpponent({type = 'literal', 'Bravo', dq = '2'}, 2)
			local notDq = StandingsParseWiki.parseWikiOpponent({type = 'literal', 'Charlie'}, 2)

			assert.are_equal(1, dqAll.disqualifiedFromRound)
			assert.are_equal(2, dqFromTwo.disqualifiedFromRound)
			assert.is_nil(notDq.disqualifiedFromRound)
		end)
	end)

	describe('definite statuses', function()
		it('reads r<round>bg inputs keyed by the round they apply from', function()
			assert.are_same({[3] = 'up'}, StandingsParseWiki.parseDefiniteStatuses({r3bg = 'up'}, 5))
			assert.are_same(
				{[3] = 'stayup', [5] = 'up'},
				StandingsParseWiki.parseDefiniteStatuses({r3bg = 'stayup', r5bg = 'up', r1 = '3'}, 5)
			)
		end)

		it('ignores empty values and rounds beyond the number of rounds', function()
			assert.are_same({[2] = 'down'}, StandingsParseWiki.parseDefiniteStatuses({r1bg = '', r2bg = 'down'}, 3))
			assert.are_same({[1] = 'up'}, StandingsParseWiki.parseDefiniteStatuses({r1bg = 'up', r4bg = 'down'}, 3))
		end)

		it('returns nil when there are none', function()
			assert.is_nil(StandingsParseWiki.parseDefiniteStatuses({}, 3))
			assert.is_nil(StandingsParseWiki.parseDefiniteStatuses({r1bg = '', bg = 'up'}, 3))
			assert.is_nil(StandingsParseWiki.parseDefiniteStatuses({r4bg = 'up'}, 3))
		end)

		it('stores the definite statuses on the parsed opponent without affecting round input', function()
			local withStatuses = StandingsParseWiki.parseWikiOpponent(
				{type = 'literal', 'Alpha', r1 = '3', r2 = '1', r3bg = 'up', r4bg = 'stay'}, 3)
			local without = StandingsParseWiki.parseWikiOpponent({type = 'literal', 'Bravo', r1 = '3'}, 3)

			assert.are_same({[3] = 'up'}, withStatuses.definiteStatuses)
			assert.are_equal(3, withStatuses.rounds[1].scoreboard.points)
			assert.are_equal(1, withStatuses.rounds[2].scoreboard.points)
			assert.is_nil(withStatuses.rounds[3].scoreboard.points)
			assert.is_nil(without.definiteStatuses)
		end)
	end)

	describe('adjustments', function()
		it('reads unprefixed inputs into the final round and r<round> inputs into their round', function()
			assert.are_same({
				[2] = {game = {l = 2}},
				[3] = {points = -1.5, tiebreaker = 1, match = {w = 1, d = 1}, round = {w = 3}},
			}, StandingsParseWiki.parseAdjustments({
				matchwins = '1', r3matchdraws = '1', r2gamelosses = '2', r3points = '-1.5', tiebreaker = '1', roundwins = '3',
			}, 3))
			assert.are_same(
				{[1] = {match = {l = 1}}, [2] = {game = {w = 1, d = -1}, round = {l = 4}}},
				StandingsParseWiki.parseAdjustments(
					{r1matchlosses = '1', r2gamewins = '1', gamedraws = '-1', r2roundlosses = '4'}, 2
				)
			)
		end)

		it('prefers the input of the final round over an unprefixed input', function()
			assert.are_same(
				{[3] = {game = {d = 2}}},
				StandingsParseWiki.parseAdjustments({gamedraws = '1', r3gamedraws = '2'}, 3)
			)
		end)

		it('ignores empty values and rounds beyond the number of rounds', function()
			assert.is_nil(StandingsParseWiki.parseAdjustments({}, 3))
			assert.is_nil(StandingsParseWiki.parseAdjustments({matchlosses = '', r4matchwins = '1', r1 = '3'}, 3))
		end)

		it('ignores values that are not numbers', function()
			assert.is_nil(StandingsParseWiki.parseAdjustments({points = 'abc', r1matchwins = 'x'}, 1))
		end)

		it('stores the adjustments on the parsed opponent without affecting round input', function()
			local alpha = StandingsParseWiki.parseWikiOpponent(
				{type = 'literal', 'Alpha', r1 = '3', r1points = '2', tiebreaker = '1'}, 2)
			local bravo = StandingsParseWiki.parseWikiOpponent({type = 'literal', 'Bravo', r1 = '3'}, 2)

			assert.are_equal(3, alpha.rounds[1].scoreboard.points)
			assert.are_same({[1] = {points = 2}, [2] = {tiebreaker = 1}}, alpha.adjustments)
			assert.is_nil(bravo.adjustments)
		end)
	end)

	describe('tiebreakers', function()
		it('always puts the disqualified tiebreaker first and manual last', function()
			assert.are_same(
				{'full.disqualified', 'full.points', 'full.manual'},
				StandingsParseWiki.parseTiebreakers({}, 'ffa')
			)
			assert.are_same(
				{'full.disqualified', 'full.matchscore', 'full.manual'},
				StandingsParseWiki.parseTiebreakers({}, 'swiss')
			)
			assert.are_same(
				{'full.disqualified', 'full.matchdiff', 'ml.matchwins', 'full.manual'},
				StandingsParseWiki.parseTiebreakers({tiebreakers = '["matchdiff", "ml.matchwins"]'}, 'swiss')
			)
		end)

		it('defaults to points for group tables', function()
			assert.are_same(
				{'full.disqualified', 'full.points', 'full.manual'},
				StandingsParseWiki.parseTiebreakers({}, 'group')
			)
		end)

		it('accepts h2hlegacy and ml tiebreakers for group tables', function()
			assert.are_same(
				{'full.disqualified', 'full.points', 'h2hlegacy.matchdiff', 'ml.gamediff', 'full.manual'},
				StandingsParseWiki.parseTiebreakers(
					{tiebreakers = '["points", "h2hlegacy.matchdiff", "ml.gamediff"]'}, 'group'
				)
			)
		end)

		it('accepts h2hlegacy and ml tiebreakers for swiss tables', function()
			assert.are_same(
				{'full.disqualified', 'full.matchdiff', 'h2hlegacy.matchdiff', 'ml.gamediff', 'full.manual'},
				StandingsParseWiki.parseTiebreakers(
					{tiebreakers = '["matchdiff", "h2hlegacy.matchdiff", "ml.gamediff"]'}, 'swiss'
				)
			)
		end)

		it('rejects h2hlegacy and ml tiebreakers for ffa tables', function()
			assert.error(function()
				StandingsParseWiki.parseTiebreakers({tiebreakers = '["points", "h2hlegacy.matchwins"]'}, 'ffa')
			end)
			assert.error(function()
				StandingsParseWiki.parseTiebreakers({tiebreakers = '["ml.points"]'}, 'ffa')
			end)
		end)
	end)

	describe('walkover games', function()
		it('reads the walkovergames input', function()
			assert.are_equal(2, StandingsParseWiki.parseWalkoverGames{walkovergames = '2'})
			assert.are_equal(0, StandingsParseWiki.parseWalkoverGames{walkovergames = '0'})
			assert.is_nil(StandingsParseWiki.parseWalkoverGames{walkovergames = ''})
			assert.is_nil(StandingsParseWiki.parseWalkoverGames{})
		end)

		it('errors on input that is not a non-negative integer', function()
			for _, input in ipairs({'abc', '-1', '1.5'}) do
				assert.error(function() StandingsParseWiki.parseWalkoverGames{walkovergames = input} end)
			end
		end)
	end)

	describe('walkover rounds', function()
		it('reads the walkoverrounds input', function()
			assert.are_equal(13, StandingsParseWiki.parseWalkoverRounds{walkoverrounds = '13'})
			assert.are_equal(0, StandingsParseWiki.parseWalkoverRounds{walkoverrounds = '0'})
			assert.is_nil(StandingsParseWiki.parseWalkoverRounds{walkoverrounds = ''})
			assert.is_nil(StandingsParseWiki.parseWalkoverRounds{})
		end)

		it('errors on input that is not a non-negative integer', function()
			for _, input in ipairs({'abc', '-1', '1.5'}) do
				assert.error(function() StandingsParseWiki.parseWalkoverRounds{walkoverrounds = input} end)
			end
		end)
	end)

	describe('width', function()
		it('reads the width input in px', function()
			assert.are_equal(600, StandingsParseWiki.parseWidth{width = '600'})
			assert.are_equal(600, StandingsParseWiki.parseWidth{width = '600px'})
			assert.is_nil(StandingsParseWiki.parseWidth{width = ''})
			assert.is_nil(StandingsParseWiki.parseWidth{})
			assert.is_nil(StandingsParseWiki.parseWidth{width = '50%'})
		end)
	end)

	describe('points', function()
		it('defaults to the swiss points', function()
			assert.are_same({w = 1, d = 0.5, l = 0}, StandingsParseWiki.parsePoints(nil))
			assert.are_same({w = 1, d = 0.5, l = 0}, StandingsParseWiki.parsePoints(''))
		end)

		it('defaults to 3 for a win, 1 for a draw and 0 for a loss in group tables', function()
			assert.are_same({w = 3, d = 1, l = 0}, StandingsParseWiki.parsePoints(nil, false, 'group'))
			assert.are_same({w = 3, d = 0, l = 0}, StandingsParseWiki.parsePoints('draw=0', false, 'group'))
		end)

		it('uses the overtime defaults with overtime in group tables', function()
			assert.are_same(
				{w = 3, d = 1.5, l = 0, otw = 2, otl = 1},
				StandingsParseWiki.parsePoints(nil, true, 'group')
			)
		end)

		it('normalizes the result keys and keeps the defaults of omitted ones', function()
			assert.are_same({w = 3, d = 0.5, l = 0}, StandingsParseWiki.parsePoints('win=3'))
			assert.are_same({w = 3, d = 1, l = -1}, StandingsParseWiki.parsePoints('win=3, draw=1, loss=-1'))
		end)

		it('keeps score keys as given', function()
			assert.are_same(
				{w = 3, d = 0.5, l = 0, ['2-0'] = 4, ['0-2'] = 1},
				StandingsParseWiki.parsePoints('win=3, 2-0=4, 0-2=1')
			)
		end)

		it('accepts decimals and tolerates whitespace', function()
			assert.are_same(
				{w = 2.5, d = 0.25, l = 0, ['1-1'] = 0.75},
				StandingsParseWiki.parsePoints('  win = 2.5 ,draw=0.25,   1-1 =  0.75 ')
			)
		end)

		it('ignores empty entries', function()
			assert.are_same({w = 3, d = 1, l = 0}, StandingsParseWiki.parsePoints('win=3,, draw=1,'))
		end)

		it('errors on unknown keys, non-numeric values and malformed entries', function()
			assert.error(function() StandingsParseWiki.parsePoints('won=3') end)
			assert.error(function() StandingsParseWiki.parsePoints('win=three') end)
			assert.error(function() StandingsParseWiki.parsePoints('win=') end)
			assert.error(function() StandingsParseWiki.parsePoints('win') end)
			assert.error(function() StandingsParseWiki.parsePoints('2-=3') end)
			assert.error(function() StandingsParseWiki.parsePoints('a-b=3') end)
		end)
	end)

	describe('swiss scoring function', function()
		---@param score integer?
		---@param placement integer
		---@param status string?
		local function opponent(score, placement, status)
			return {score = score, placement = placement, status = status or 'S'}
		end

		---@param opponents table[]
		---@param winner integer?
		---@param finished boolean?
		local function match(opponents, winner, finished)
			return {opponents = opponents, winner = winner, finished = finished ~= false}
		end

		---@param pointsInput string?
		---@param matchToScore table
		---@return number?, number?
		local function score(pointsInput, matchToScore)
			local scoringFunction = StandingsParseWiki.makeScoringFunction('swiss', {points = pointsInput})
			return scoringFunction(matchToScore.opponents[1], matchToScore),
				scoringFunction(matchToScore.opponents[2], matchToScore)
		end

		local twoNil = match({opponent(2, 1), opponent(0, 2)}, 1)
		local twoOne = match({opponent(2, 1), opponent(1, 2)}, 1)

		it('defaults to 1 for a win, 0.5 for a draw and 0 for a loss', function()
			assert.are_same({1, 0}, {score(nil, twoNil)})
			assert.are_same({0.5, 0.5}, {score(nil, match({opponent(1, 1), opponent(1, 1)}, 0))})
		end)

		it('uses custom result points', function()
			local drawn = match({opponent(1, 1), opponent(1, 1)}, 0)
			assert.are_same({3, 0}, {score('win=3', twoNil)})
			assert.are_same({3, -1}, {score('win=3, loss=-1', twoNil)})
			assert.are_same({1, 1}, {score('win=3, draw=1', drawn)})
		end)

		it('replaces the result points with the points of a score', function()
			assert.are_same({4, 0}, {score('win=3, 2-0=4', twoNil)})
			assert.are_same({3, 0}, {score('win=3, 2-0=4', twoOne)})
		end)

		it('supports scores for the losing side', function()
			assert.are_same({3, 1}, {score('win=3, 1-2=1', twoOne)})
			assert.are_same({3, 0}, {score('win=3, 1-2=1', twoNil)})
			assert.are_same({3, 0.5}, {score('win=3, 0-2=0.5', twoNil)})
		end)

		it('supports scores of draws', function()
			assert.are_same({2, 2}, {score('1-1=2', match({opponent(1, 1), opponent(1, 1)}, 0))})
		end)

		it('gives no points for unfinished matches', function()
			assert.is_nil(score('loss=1', match({opponent(1, 1), opponent(0, 2)}, nil, false)))
		end)

		it('falls back to the result points without a score', function()
			local walkover = match({opponent(nil, 1, 'W'), opponent(nil, 2, 'L')}, 1)
			assert.are_same({3, 0}, {score('win=3, 0-0=9', walkover)})
			-- a numeric score of a non scored opponent is not trusted either
			local forfeit = match({opponent(2, 1), opponent(0, 2, 'FF')}, 1)
			assert.are_same({3, 0}, {score('win=3, 2-0=4', forfeit)})
			local threeWay = match({opponent(2, 1), opponent(0, 2), opponent(0, 2)}, 1)
			local winnerPoints = score('win=3, 2-0=4', threeWay)
			assert.are_equal(3, winnerPoints)
		end)

		it('errors on invalid points input', function()
			assert.error(function() StandingsParseWiki.makeScoringFunction('swiss', {points = 'win=x'}) end)
		end)

		it('scores group matches with the group default points', function()
			local scoringFunction = StandingsParseWiki.makeScoringFunction('group', {})
			assert.are_equal(3, scoringFunction(twoNil.opponents[1], twoNil))
			assert.are_equal(0, scoringFunction(twoNil.opponents[2], twoNil))
			local drawn = match({opponent(1, 1), opponent(1, 1)}, 0)
			assert.are_equal(1, scoringFunction(drawn.opponents[1], drawn))
		end)

		it('scores group matches with custom points', function()
			local scoringFunction = StandingsParseWiki.makeScoringFunction('group', {points = 'win=2, 2-1=1'})
			assert.are_equal(2, scoringFunction(twoNil.opponents[1], twoNil))
			assert.are_equal(1, scoringFunction(twoOne.opponents[1], twoOne))
		end)
	end)
end)
