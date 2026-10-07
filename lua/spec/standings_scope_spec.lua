--- Triple Comment to Enable our LLS Plugin
describe('Standings Tiebreaker Scope', function()
	local TiebreakerScope = require('Module:Standings/Tiebreaker/Scope')
	local Array = require('Module:Array')

	---@param names string[]
	---@param props {id: string, winner: integer?, finished: boolean?}
	---@return table
	local function makeMatch(names, props)
		return {
			matchId = props.id,
			finished = props.finished ~= false,
			winner = props.winner,
			opponents = Array.map(names, function(name, index)
				return {
					type = 'literal',
					name = name,
					status = 'S',
					placement = (props.winner == 0 or props.winner == index) and 1 or 2,
				}
			end),
			games = {},
		}
	end

	---@param name string
	---@param matches table[]
	---@param matchPoints table<string, number>?
	---@return table
	local function makeOpponent(name, matches, matchPoints)
		return {
			opponent = {type = 'literal', name = name},
			points = 100,
			startingPoints = 10,
			matches = matches,
			matchPoints = matchPoints,
			match = {w = 40, d = 41, l = 42},
			extradata = {additionalStatsValues = {}, tiebreakerpoints = 3},
		}
	end

	describe('matchResult', function()
		it('is a win for the first placed opponent, a loss for the others and a draw without winner', function()
			local match = makeMatch({'Alpha', 'Bravo'}, {id = 'M1', winner = 1})
			assert.are_equal('w', TiebreakerScope.matchResult(match, match.opponents[1]))
			assert.are_equal('l', TiebreakerScope.matchResult(match, match.opponents[2]))

			local draw = makeMatch({'Alpha', 'Bravo'}, {id = 'M2', winner = 0})
			assert.are_equal('d', TiebreakerScope.matchResult(draw, draw.opponents[1]))
			assert.are_equal('d', TiebreakerScope.matchResult(draw, draw.opponents[2]))
		end)
	end)

	describe('tally', function()
		it('sums the points of all matches and the record of the finished ones', function()
			local alpha = {type = 'literal', name = 'Alpha'}
			local scoreboard = TiebreakerScope.tally(alpha, {
				makeMatch({'Alpha', 'Bravo'}, {id = 'M1', winner = 1}),
				makeMatch({'Charlie', 'Alpha'}, {id = 'M2', winner = 1}),
				makeMatch({'Alpha', 'Delta'}, {id = 'M3', winner = 0}),
				makeMatch({'Alpha', 'Echo'}, {id = 'M4', winner = 1, finished = false}),
			}, {M1 = 3, M2 = 0, M3 = 1, M4 = 2})

			assert.are_same({points = 6, match = {w = 1, d = 1, l = 1}}, scoreboard)
		end)

		it('has no points if no match gave points', function()
			local alpha = {type = 'literal', name = 'Alpha'}
			local match = makeMatch({'Alpha', 'Bravo'}, {id = 'M1', winner = 1})

			assert.are_same({match = {w = 1, d = 0, l = 0}}, TiebreakerScope.tally(alpha, {match}, nil))
			assert.are_same({match = {w = 0, d = 0, l = 0}}, TiebreakerScope.tally(alpha, {}, {}))
		end)
	end)

	describe('restrictTo', function()
		it('only keeps matches played among the tied opponents', function()
			local alphaBravo = makeMatch({'Alpha', 'Bravo'}, {id = 'M1', winner = 1})
			local alphaCharlie = makeMatch({'Alpha', 'Charlie'}, {id = 'M2', winner = 1})
			local bravoCharlie = makeMatch({'Bravo', 'Charlie'}, {id = 'M3', winner = 2})
			local alpha = makeOpponent('Alpha', {alphaBravo, alphaCharlie})
			local bravo = makeOpponent('Bravo', {alphaBravo, bravoCharlie})

			local scoped = TiebreakerScope.restrictTo{alpha, bravo}

			assert.are_equal(2, #scoped)
			assert.are_same({alphaBravo}, scoped[1].matches)
			assert.are_same({alphaBravo}, scoped[2].matches)
		end)

		it('requires every opponent of a match to be tied', function()
			local threeWay = makeMatch({'Alpha', 'Bravo', 'Charlie'}, {id = 'M1', winner = 1})
			local alpha = makeOpponent('Alpha', {threeWay})
			local bravo = makeOpponent('Bravo', {threeWay})
			local charlie = makeOpponent('Charlie', {threeWay})

			assert.are_equal(0, #TiebreakerScope.restrictTo{alpha, bravo}[1].matches)
			assert.are_equal(1, #TiebreakerScope.restrictTo{alpha, bravo, charlie}[1].matches)
		end)

		it('recounts wins, draws and losses from the finished matches', function()
			local win = makeMatch({'Alpha', 'Bravo'}, {id = 'M1', winner = 1})
			local draw = makeMatch({'Alpha', 'Bravo'}, {id = 'M2', winner = 0})
			local loss = makeMatch({'Bravo', 'Alpha'}, {id = 'M3', winner = 1})
			local unfinished = makeMatch({'Alpha', 'Bravo'}, {id = 'M4', winner = 1, finished = false})
			local external = makeMatch({'Alpha', 'Charlie'}, {id = 'M5', winner = 1})
			local alpha = makeOpponent('Alpha', {win, draw, loss, unfinished, external})
			local bravo = makeOpponent('Bravo', {win, draw, loss, unfinished})

			local scoped = TiebreakerScope.restrictTo{alpha, bravo}

			assert.are_same({w = 1, d = 1, l = 1}, scoped[1].match)
			assert.are_same({w = 1, d = 1, l = 1}, scoped[2].match)
			-- unfinished matches stay in the list (for tiebreakers deciding for themselves), but are not counted
			assert.are_equal(4, #scoped[1].matches)
		end)

		it('sums the points of the remaining matches', function()
			local first = makeMatch({'Alpha', 'Bravo'}, {id = 'M1', winner = 1})
			local second = makeMatch({'Alpha', 'Bravo'}, {id = 'M2', winner = 2})
			local external = makeMatch({'Alpha', 'Charlie'}, {id = 'M3', winner = 1})
			local alpha = makeOpponent('Alpha', {first, second, external}, {M1 = 3, M2 = 0.5, M3 = 7})
			local bravo = makeOpponent('Bravo', {first, second}, {M1 = 0})
			local charlie = makeOpponent('Charlie', {external})

			local scoped = TiebreakerScope.restrictTo{alpha, bravo, charlie}
			assert.are_equal(10.5, scoped[1].points)
			assert.are_equal(0, scoped[2].points)
			assert.are_equal(0, scoped[3].points)

			scoped = TiebreakerScope.restrictTo{alpha, bravo}
			assert.are_equal(3.5, scoped[1].points)
			assert.are_equal(0, scoped[2].points)
		end)

		it('returns new opponents in the same order without touching the input', function()
			local match = makeMatch({'Alpha', 'Bravo'}, {id = 'M1', winner = 1})
			local alpha = makeOpponent('Alpha', {match, makeMatch({'Alpha', 'Charlie'}, {id = 'M2', winner = 1})}, {M1 = 3})
			local bravo = makeOpponent('Bravo', {match})

			local scoped = TiebreakerScope.restrictTo{alpha, bravo}

			assert.are_equal(2, #scoped)
			assert.are_not_equal(alpha, scoped[1])
			assert.are_not_equal(bravo, scoped[2])
			assert.are_not_equal(alpha.matches, scoped[1].matches)
			assert.are_not_equal(alpha.match, scoped[1].match)
			assert.are_equal(alpha.opponent, scoped[1].opponent)
			assert.are_equal(bravo.opponent, scoped[2].opponent)
			assert.are_equal(alpha.extradata, scoped[1].extradata)
			assert.is_nil(scoped[1].startingPoints)

			assert.are_equal(100, alpha.points)
			assert.are_equal(2, #alpha.matches)
			assert.are_same({w = 40, d = 41, l = 42}, alpha.match)
		end)
	end)

	describe('overtime', function()
		local Info = require('Module:Info')
		local originalStandingsConfig

		before_each(function()
			originalStandingsConfig = Info.config.standings
			Info.config.standings = {overtime = {regulationRounds = 12}}
		end)

		after_each(function()
			Info.config.standings = originalStandingsConfig
		end)

		---@param names string[]
		---@param props {id: string, winner: integer?, finished: boolean?}
		---@param rounds integer[]
		---@return table
		local function makeBo1(names, props, rounds)
			local match = makeMatch(names, props)
			match.games = {{winner = props.winner, scores = rounds, status = ''}}
			return match
		end

		it('tallies overtime results apart from regulation results', function()
			local alpha = {type = 'literal', name = 'Alpha'}
			local scoreboard = TiebreakerScope.tally(alpha, {
				makeBo1({'Alpha', 'Bravo'}, {id = 'M1', winner = 1}, {7, 3}),
				makeBo1({'Alpha', 'Charlie'}, {id = 'M2', winner = 1}, {8, 6}),
				makeBo1({'Alpha', 'Delta'}, {id = 'M3', winner = 2}, {6, 8}),
				makeBo1({'Alpha', 'Echo'}, {id = 'M4', winner = 2}, {2, 7}),
			}, nil, true)

			assert.are_same({w = 1, d = 0, l = 1}, scoreboard.match)
			assert.are_same({w = 1, l = 1}, scoreboard.overtime)
		end)

		it('does not tally overtime when it is not enabled', function()
			local alpha = {type = 'literal', name = 'Alpha'}
			local scoreboard = TiebreakerScope.tally(alpha, {
				makeBo1({'Alpha', 'Bravo'}, {id = 'M1', winner = 1}, {8, 6}),
			}, nil)

			assert.are_same({w = 1, d = 0, l = 0}, scoreboard.match)
			assert.is_nil(scoreboard.overtime)
		end)

		it('keeps overtime results for opponents tracking overtime', function()
			local regulation = makeBo1({'Alpha', 'Bravo'}, {id = 'M1', winner = 1}, {7, 2})
			local overtime = makeBo1({'Alpha', 'Bravo'}, {id = 'M2', winner = 2}, {6, 8})
			local alpha = makeOpponent('Alpha', {regulation, overtime})
			local bravo = makeOpponent('Bravo', {regulation, overtime})
			alpha.overtime = {w = 0, l = 1}
			bravo.overtime = {w = 1, l = 0}

			local scoped = TiebreakerScope.restrictTo{alpha, bravo}

			assert.are_same({w = 1, d = 0, l = 0}, scoped[1].match)
			assert.are_same({w = 0, l = 1}, scoped[1].overtime)
			assert.are_same({w = 0, d = 0, l = 1}, scoped[2].match)
			assert.are_same({w = 1, l = 0}, scoped[2].overtime)
		end)

		it('does not add overtime to opponents without it', function()
			local match = makeBo1({'Alpha', 'Bravo'}, {id = 'M1', winner = 1}, {8, 6})
			local scoped = TiebreakerScope.restrictTo{makeOpponent('Alpha', {match}), makeOpponent('Bravo', {match})}

			assert.are_same({w = 1, d = 0, l = 0}, scoped[1].match)
			assert.is_nil(scoped[1].overtime)
		end)
	end)
end)
