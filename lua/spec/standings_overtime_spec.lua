--- Triple Comment to Enable our LLS Plugin
describe('Standings overtime', function()
	local Info = require('Module:Info')
	local StandingsOvertime = require('Module:Standings/Overtime')
	local StandingsParseWiki = require('Module:Standings/Parse/Wiki')
	local StandingTableLegacySwiss = require('Module:Standings/Table/Legacy/Swiss')

	local originalStandingsConfig

	---@param regulationRounds integer?
	local function setRegulationRounds(regulationRounds)
		Info.config.standings = regulationRounds and {overtime = {regulationRounds = regulationRounds}} or {}
	end

	---@param scores integer[]
	---@param props {winner: integer?, status: string?}?
	local function makeGame(scores, props)
		props = props or {}
		return {
			scores = scores,
			winner = props.winner or (scores[1] > scores[2] and 1 or 2),
			status = props.status or '',
		}
	end

	---@param games table[]
	---@param finished boolean?
	local function makeMatch(games, finished)
		local lastGame = games[#games]
		return {
			finished = finished ~= false,
			bestof = 1,
			games = games,
			opponents = {
				{score = lastGame and lastGame.winner == 1 and 1 or 0, status = 'S', placement = 1},
				{score = lastGame and lastGame.winner == 2 and 1 or 0, status = 'S', placement = 2},
			},
		}
	end

	before_each(function()
		originalStandingsConfig = Info.config.standings
	end)

	after_each(function()
		Info.config.standings = originalStandingsConfig
	end)

	describe('isOvertimeGame', function()
		it('is overtime when more rounds than regulation were played', function()
			setRegulationRounds(12)
			assert.is_true(StandingsOvertime.isOvertimeGame(makeGame{7, 6}))
			assert.is_true(StandingsOvertime.isOvertimeGame(makeGame{9, 6}))
		end)

		it('is not overtime when only the regulation rounds were played', function()
			setRegulationRounds(12)
			assert.is_false(StandingsOvertime.isOvertimeGame(makeGame{7, 5}))
			assert.is_false(StandingsOvertime.isOvertimeGame(makeGame{7, 2}))
		end)

		it('is not overtime for unplayed games', function()
			setRegulationRounds(12)
			assert.is_false(StandingsOvertime.isOvertimeGame(makeGame({7, 6}, {status = 'notplayed'})))
			-- games without a winner have not been played yet
			local noWinner = {scores = {7, 6}, winner = '', status = ''} --[[@as any]]
			assert.is_false(StandingsOvertime.isOvertimeGame(noWinner))
			local noScores = {scores = {}, winner = nil, status = ''} --[[@as any]]
			assert.is_false(StandingsOvertime.isOvertimeGame(noScores))
		end)

		it('is never overtime without a configured number of regulation rounds', function()
			setRegulationRounds(nil)
			assert.is_nil(StandingsOvertime.regulationRounds())
			assert.is_false(StandingsOvertime.isOvertimeGame(makeGame{7, 6}))
		end)
	end)

	describe('isOvertimeMatch', function()
		it('is overtime when the game is', function()
			setRegulationRounds(12)
			assert.is_true(StandingsOvertime.isOvertimeMatch(makeMatch{makeGame{7, 6}}))
			assert.is_false(StandingsOvertime.isOvertimeMatch(makeMatch{makeGame{7, 5}}))
		end)

		it('is not overtime without games', function()
			setRegulationRounds(12)
			assert.is_false(StandingsOvertime.isOvertimeMatch(makeMatch{}))
		end)

		it('does not depend on the match score', function()
			setRegulationRounds(12)
			-- A Bo1 has a match score of 1-0 in maps, no matter how many rounds were played
			local match = makeMatch{makeGame{7, 6}}
			assert.are_equal(1, match.opponents[1].score + match.opponents[2].score)
			assert.is_true(StandingsOvertime.isOvertimeMatch(match))
		end)

		it('is never overtime without a configured number of regulation rounds', function()
			setRegulationRounds(nil)
			assert.is_false(StandingsOvertime.isOvertimeMatch(makeMatch{makeGame{7, 6}}))
		end)
	end)

	describe('parseOvertime', function()
		it('reads the overtime flag', function()
			setRegulationRounds(12)
			assert.is_true(StandingsParseWiki.parseOvertime{overtime = 'true'})
			assert.is_false(StandingsParseWiki.parseOvertime{overtime = 'false'})
			assert.is_false(StandingsParseWiki.parseOvertime{})
		end)

		it('errors when enabled without regulation rounds being configured', function()
			setRegulationRounds(nil)
			assert.error(function() StandingsParseWiki.parseOvertime{overtime = 'true'} end)
			assert.is_false(StandingsParseWiki.parseOvertime{})
		end)
	end)

	describe('swiss scoring', function()
		local function score(scoreFunction, match, opponentIndex)
			return scoreFunction(match.opponents[opponentIndex], match)
		end

		it('gives 3/2/1/0 points with overtime', function()
			setRegulationRounds(12)
			local scoreFunction = StandingsParseWiki.makeScoringFunction('swiss', {}, true)
			local regulation = makeMatch{makeGame{7, 3}}
			local overtime = makeMatch{makeGame{7, 6}}
			assert.are_equal(3, score(scoreFunction, regulation, 1))
			assert.are_equal(0, score(scoreFunction, regulation, 2))
			assert.are_equal(2, score(scoreFunction, overtime, 1))
			assert.are_equal(1, score(scoreFunction, overtime, 2))
		end)

		it('gives no points for unfinished matches with overtime', function()
			setRegulationRounds(12)
			local scoreFunction = StandingsParseWiki.makeScoringFunction('swiss', {}, true)
			local live = makeMatch({makeGame{7, 6}}, false)
			assert.is_falsy(score(scoreFunction, live, 1))
			assert.is_falsy(score(scoreFunction, live, 2))
		end)

		it('gives 1/0 points without overtime', function()
			setRegulationRounds(12)
			local scoreFunction = StandingsParseWiki.makeScoringFunction('swiss', {})
			local overtime = makeMatch{makeGame{7, 6}}
			assert.are_equal(1, score(scoreFunction, overtime, 1))
			assert.are_equal(0, score(scoreFunction, overtime, 2))
		end)
	end)

	describe('legacy swiss tiebreakers', function()
		it('maps "no ot diff" to gamediffregulation', function()
			assert.are_same({'gamediff', 'gamediffregulation'}, StandingTableLegacySwiss.parseTiebreaker{
				tiebreaker1 = 'diff',
				tiebreaker2 = 'no ot diff',
			})
		end)
	end)
end)
