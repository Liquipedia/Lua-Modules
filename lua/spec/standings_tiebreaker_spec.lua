--- Triple Comment to Enable our LLS Plugin
describe('Standings Tiebreakers', function()
	local TiebreakerFactory = require('Module:Standings/Tiebreaker/Factory')
	local Array = require('Module:Array')

	local function literal(name)
		return {type = 'literal', name = name}
	end

	---@param name string
	---@param props {points: number?, matches: table[]?, matchPoints: table<string, number>?, match: table?,
	---overtime: table?, tiebreakerpoints: number?}?
	---@return table
	local function opponent(name, props)
		props = props or {}
		return {
			opponent = literal(name),
			points = props.points or 0,
			matches = props.matches or {},
			matchPoints = props.matchPoints,
			match = props.match or {w = 0, d = 0, l = 0},
			overtime = props.overtime,
			extradata = {additionalStatsValues = {}, tiebreakerpoints = props.tiebreakerpoints},
		}
	end

	---@param opponentNames string[]
	---@param props {matchId: string?, finished: boolean?, winner: integer?, games: table[]?, statuses: string[]?,
	---scores: integer[]?}?
	---@return table
	local function makeMatch(opponentNames, props)
		props = props or {}
		local statuses = props.statuses or {}
		local scores = props.scores or {}
		local matchOpponents = {}
		for index, name in ipairs(opponentNames) do
			table.insert(matchOpponents, {
				type = 'literal',
				name = name,
				score = scores[index],
				status = statuses[index] or 'S',
			})
		end
		return {
			matchId = props.matchId or 'FakeMatch',
			finished = props.finished ~= false,
			winner = props.winner,
			opponents = matchOpponents,
			games = props.games or {},
		}
	end

	---Alpha plus one opponent per score, each faced by Alpha in a finished match.
	---The scores are the match diffs of the faced opponents, or their points with `scoreType` 'points'.
	---Opponents with points all have a 1-0 record, so a match diff based score gives another answer.
	---@param scores number[]
	---@param scoreType 'matchdiff'|'points'?
	---@return table[] state, table alpha
	local function stateWithFacedOpponents(scores, scoreType)
		local names = {'Bravo', 'Charlie', 'Delta', 'Echo', 'Foxtrot'}
		local matches = {}
		local others = {}
		for index, score in ipairs(scores) do
			table.insert(matches, makeMatch({'Alpha', names[index]}, {winner = 1}))
			local props = scoreType == 'points'
				and {points = score, match = {w = 1, d = 0, l = 0}}
				or {match = {w = math.max(score, 0), d = 0, l = math.max(-score, 0)}}
			table.insert(others, opponent(names[index], props))
		end
		local alpha = opponent('Alpha', {matches = matches})
		return Array.extend({alpha}, others), alpha
	end

	describe('factory', function()
		it('normalizes inputs', function()
			assert.are_equal('full.points', TiebreakerFactory.validateAndNormalizeInput('points'))
			assert.are_equal('ml.points', TiebreakerFactory.validateAndNormalizeInput('ml.points'))
			assert.are_equal('h2hlegacy.points', TiebreakerFactory.validateAndNormalizeInput('h2hlegacy.points'))
			assert.are_equal('full.disqualified', TiebreakerFactory.validateAndNormalizeInput('disqualified'))
			assert.error(function() TiebreakerFactory.validateAndNormalizeInput('bogus') end)
			assert.error(function() TiebreakerFactory.validateAndNormalizeInput('badcontext.points') end)
			assert.error(function() TiebreakerFactory.validateAndNormalizeInput('h2h.points') end)
		end)

		it('rejects non full contexts for tiebreakers not derived from matches among tied opponents', function()
			local names = {
				'buchholz', 'medianbuchholz', 'buchholzpoints', 'medianbuchholzpoints', 'sonnebornberger',
				'manual', 'disqualified', 'startingpoints',
			}
			Array.forEach(names, function(name)
				assert.are_equal('full.' .. name, TiebreakerFactory.validateAndNormalizeInput(name))
				assert.error(function() TiebreakerFactory.validateAndNormalizeInput('ml.' .. name) end)
				assert.error(function() TiebreakerFactory.validateAndNormalizeInput('h2hlegacy.' .. name) end)
			end)
		end)

		it('accepts the h2hlegacy and ml contexts for match based tiebreakers', function()
			assert.are_equal('ml.matchdiff', TiebreakerFactory.validateAndNormalizeInput('ml.matchdiff'))
			assert.are_equal('h2hlegacy.matchdiff', TiebreakerFactory.validateAndNormalizeInput('h2hlegacy.matchdiff'))
			assert.are_equal('ml.gamediff', TiebreakerFactory.validateAndNormalizeInput('ml.gamediff'))
			assert.are_equal('ml.matchscore', TiebreakerFactory.validateAndNormalizeInput('ml.matchscore'))
		end)

		it('exposes context', function()
			assert.are_equal('full', TiebreakerFactory.tiebreakerFromId('full.points'):getContextType())
			assert.are_equal('ml', TiebreakerFactory.tiebreakerFromId('ml.matchdiff'):getContextType())
			assert.are_equal('h2hlegacy', TiebreakerFactory.tiebreakerFromId('h2hlegacy.matchdiff'):getContextType())
		end)
	end)

	describe('points and manual', function()
		it('read from the opponent', function()
			local points = TiebreakerFactory.tiebreakerFromId('full.points')
			local manual = TiebreakerFactory.tiebreakerFromId('full.manual')
			local opp = opponent('Alpha', {points = 7, tiebreakerpoints = 2})
			assert.are_equal(7, points:valueOf({opp}, opp))
			assert.are_equal('7', points:display({opp}, opp))
			assert.are_equal(2, manual:valueOf({opp}, opp))
		end)
	end)

	describe('disqualified', function()
		it('is 0 for disqualified opponents and 1 otherwise, and has no column', function()
			local disqualified = TiebreakerFactory.tiebreakerFromId('full.disqualified')
			local dqOpponent = opponent('Alpha')
			dqOpponent.extradata.disqualified = true
			local okOpponent = opponent('Bravo')
			okOpponent.extradata.disqualified = false
			local untouchedOpponent = opponent('Charlie')

			assert.are_equal(0, disqualified:valueOf({dqOpponent, okOpponent, untouchedOpponent}, dqOpponent))
			assert.are_equal(1, disqualified:valueOf({dqOpponent, okOpponent, untouchedOpponent}, okOpponent))
			assert.are_equal(1, disqualified:valueOf({dqOpponent, okOpponent, untouchedOpponent}, untouchedOpponent))
			assert.is_nil(disqualified:headerTitle())
		end)
	end)

	describe('matchdiff', function()
		it('uses the match scoreboard', function()
			local matchdiff = TiebreakerFactory.tiebreakerFromId('full.matchdiff')
			local opp = opponent('Alpha', {match = {w = 3, d = 1, l = 1}})
			assert.are_equal(2, matchdiff:valueOf({opp}, opp))
			assert.are_equal('3 - 1', matchdiff:display({opp}, opp))
		end)

		it('displays draws when enabled for the match level', function()
			local matchdiff = TiebreakerFactory.tiebreakerFromId('full.matchdiff', {draws = {match = true}})
			local opp = opponent('Alpha', {match = {w = 3, d = 1, l = 1}})
			assert.are_equal(2, matchdiff:valueOf({opp}, opp))
			assert.are_equal('3 - 1 - 1', matchdiff:display({opp}, opp))
		end)

		it('does not display draws when only other levels have them enabled', function()
			local matchdiff = TiebreakerFactory.tiebreakerFromId('full.matchdiff', {draws = {game = true}})
			local opp = opponent('Alpha', {match = {w = 3, d = 1, l = 1}})
			assert.are_equal('3 - 1', matchdiff:display({opp}, opp))
		end)
	end)

	describe('matchdiff with overtime', function()
		-- regulation: 2 wins, 1 loss; overtime: 1 win, 2 losses
		local alphaProps = {match = {w = 2, d = 1, l = 1}, overtime = {w = 1, l = 2}}

		it('counts overtime results as wins and losses', function()
			local matchdiff = TiebreakerFactory.tiebreakerFromId('full.matchdiff')
			local opp = opponent('Alpha', alphaProps)
			assert.are_equal(0, matchdiff:valueOf({opp}, opp))
		end)

		it('displays regulation and overtime results separately', function()
			local matchdiff = TiebreakerFactory.tiebreakerFromId('full.matchdiff')
			local opp = opponent('Alpha', alphaProps)
			assert.are_equal('2 - 1 - 2 - 1', matchdiff:display({opp}, opp))
		end)

		it('never displays draws', function()
			local matchdiff = TiebreakerFactory.tiebreakerFromId('full.matchdiff', {draws = {match = true}})
			local opp = opponent('Alpha', alphaProps)
			assert.are_equal('2 - 1 - 2 - 1', matchdiff:display({opp}, opp))
		end)

		it('is counted by the other match tiebreakers', function()
			local opp = opponent('Alpha', alphaProps)
			local function tiebreaker(name)
				return TiebreakerFactory.tiebreakerFromId('full.' .. name)
			end
			assert.are_equal(3, tiebreaker('matchwins'):valueOf({opp}, opp))
			assert.are_equal(-3, tiebreaker('matchlosses'):valueOf({opp}, opp))
			-- matchlosses shares the matches column, which shows overtime separately
			assert.are_equal('2 - 1 - 2 - 1', tiebreaker('matchlosses'):display({opp}, opp))
			assert.are_equal(7, tiebreaker('matchcount'):valueOf({opp}, opp))
			assert.are_equal(3 / 7, tiebreaker('matchwinrate'):valueOf({opp}, opp))
			-- draws are unaffected
			assert.are_equal(1, tiebreaker('matchdraws'):valueOf({opp}, opp))
		end)
	end)

	describe('buchholz', function()
		it('sums match diff of faced opponents from finished matches', function()
			local buchholz = TiebreakerFactory.tiebreakerFromId('full.buchholz')
			local alpha = opponent('Alpha', {
				match = {w = 2, d = 0, l = 0},
				matches = {
					makeMatch({'Alpha', 'Bravo'}, {winner = 1}),
					makeMatch({'Alpha', 'Charlie'}, {winner = 1}),
					makeMatch({'Alpha', 'Delta'}, {finished = false}),
				},
			})
			local bravo = opponent('Bravo', {match = {w = 1, d = 0, l = 1}})
			local charlie = opponent('Charlie', {match = {w = 0, d = 0, l = 2}})
			local delta = opponent('Delta', {match = {w = 5, d = 0, l = 0}})
			local state = {alpha, bravo, charlie, delta}

			-- Bravo (1-1 = 0) + Charlie (0-2 = -2); Delta excluded as the match is unfinished
			assert.are_equal(-2, buchholz:valueOf(state, alpha))
		end)

		it('includes overtime results of faced opponents', function()
			local buchholz = TiebreakerFactory.tiebreakerFromId('full.buchholz')
			local alpha = opponent('Alpha', {
				match = {w = 1, d = 0, l = 0},
				matches = {makeMatch({'Alpha', 'Bravo'}, {winner = 1})},
			})
			local bravo = opponent('Bravo', {match = {w = 0, d = 0, l = 1}, overtime = {w = 3, l = 0}})

			-- Bravo: (0 + 3) - (1 + 0)
			assert.are_equal(2, buchholz:valueOf({alpha, bravo}, alpha))
		end)
	end)

	describe('medianbuchholz', function()
		it('drops the highest and lowest score', function()
			local medianBuchholz = TiebreakerFactory.tiebreakerFromId('full.medianbuchholz')
			local state, alpha = stateWithFacedOpponents({3, 1, 0, -2})

			-- 3 + 1 + 0 + -2 minus the highest (3) and the lowest (-2)
			assert.are_equal(1, medianBuchholz:valueOf(state, alpha))
			assert.are_equal('Median-Buchholz', medianBuchholz:headerTitle())
		end)

		it('drops only one of tied extremes', function()
			local medianBuchholz = TiebreakerFactory.tiebreakerFromId('full.medianbuchholz')
			local state, alpha = stateWithFacedOpponents({2, 2, 0, 0})

			-- 2 + 2 + 0 + 0 minus one 2 and one 0
			assert.are_equal(2, medianBuchholz:valueOf(state, alpha))
		end)

		it('is 0 with fewer than three faced opponents', function()
			local medianBuchholz = TiebreakerFactory.tiebreakerFromId('full.medianbuchholz')
			local buchholz = TiebreakerFactory.tiebreakerFromId('full.buchholz')
			local state, alpha = stateWithFacedOpponents({3, 1})

			assert.are_equal(0, medianBuchholz:valueOf(state, alpha))
			assert.are_equal(4, buchholz:valueOf(state, alpha))
		end)

		it('ignores unfinished matches', function()
			local medianBuchholz = TiebreakerFactory.tiebreakerFromId('full.medianbuchholz')
			local state, alpha = stateWithFacedOpponents({3, 1, 0})
			table.insert(alpha.matches, makeMatch({'Alpha', 'Echo'}, {finished = false}))
			table.insert(state, opponent('Echo', {match = {w = 2, d = 0, l = 0}}))

			-- Counting Echo (2) would keep it as a middle score: 3 + 2 + 1 + 0 - 3 - 0 = 3
			assert.are_equal(1, medianBuchholz:valueOf(state, alpha))
		end)
	end)

	describe('buchholzpoints', function()
		it('sums the points of faced opponents', function()
			local buchholzPoints = TiebreakerFactory.tiebreakerFromId('full.buchholzpoints')
			local buchholz = TiebreakerFactory.tiebreakerFromId('full.buchholz')
			-- 6 represents an opponent that has starting points
			local state, alpha = stateWithFacedOpponents({3, 2, 6}, 'points')

			assert.are_equal(11, buchholzPoints:valueOf(state, alpha))
			assert.are_equal('Buchholz (Pts)', buchholzPoints:headerTitle())
			-- The plain buchholz still scores by match diff: 3 opponents with 1-0
			assert.are_equal(3, buchholz:valueOf(state, alpha))
		end)

		it('ignores unfinished matches', function()
			local buchholzPoints = TiebreakerFactory.tiebreakerFromId('full.buchholzpoints')
			local state, alpha = stateWithFacedOpponents({3, 2, 6}, 'points')
			table.insert(alpha.matches, makeMatch({'Alpha', 'Echo'}, {finished = false}))
			table.insert(state, opponent('Echo', {points = 100}))

			-- Counting Echo (100) would give 111
			assert.are_equal(11, buchholzPoints:valueOf(state, alpha))
		end)
	end)

	describe('medianbuchholzpoints', function()
		it('drops the highest and lowest points', function()
			local medianBuchholzPoints = TiebreakerFactory.tiebreakerFromId('full.medianbuchholzpoints')
			local state, alpha = stateWithFacedOpponents({6, 3, 2, 0.5}, 'points')

			-- 6 + 3 + 2 + 0.5 minus the highest (6) and the lowest (0.5)
			assert.are_equal(5, medianBuchholzPoints:valueOf(state, alpha))
			assert.are_equal('Median-Buchholz (Pts)', medianBuchholzPoints:headerTitle())
		end)

		it('drops only one of tied extremes', function()
			local medianBuchholzPoints = TiebreakerFactory.tiebreakerFromId('full.medianbuchholzpoints')
			local state, alpha = stateWithFacedOpponents({4, 4, 1, 1}, 'points')

			-- 4 + 4 + 1 + 1 minus one 4 and one 1
			assert.are_equal(5, medianBuchholzPoints:valueOf(state, alpha))
		end)

		it('is 0 with fewer than three faced opponents', function()
			local medianBuchholzPoints = TiebreakerFactory.tiebreakerFromId('full.medianbuchholzpoints')
			local buchholzPoints = TiebreakerFactory.tiebreakerFromId('full.buchholzpoints')
			local state, alpha = stateWithFacedOpponents({3, 1}, 'points')

			assert.are_equal(0, medianBuchholzPoints:valueOf(state, alpha))
			assert.are_equal(4, buchholzPoints:valueOf(state, alpha))
		end)

		it('ignores unfinished matches', function()
			local medianBuchholzPoints = TiebreakerFactory.tiebreakerFromId('full.medianbuchholzpoints')
			local state, alpha = stateWithFacedOpponents({6, 3, 2}, 'points')
			table.insert(alpha.matches, makeMatch({'Alpha', 'Echo'}, {finished = false}))
			table.insert(state, opponent('Echo', {points = 4}))

			-- Echo (4) would be a middle score if counted: 6 + 4 + 3 + 2 - 6 - 2 = 7, instead of 6 + 3 + 2 - 6 - 2 = 3
			assert.are_equal(3, medianBuchholzPoints:valueOf(state, alpha))
		end)
	end)

	describe('sonnebornberger', function()
		---Round robin with default swiss points (win 1, draw 0.5, loss 0),
		---where Alpha and Bravo are tied on everything but Sonneborn-Berger
		---@return table[] state, table alpha, table bravo
		local function roundRobin()
			local alphaBravo = makeMatch({'Alpha', 'Bravo'}, {matchId = 'AB'})
			local alphaCharlie = makeMatch({'Alpha', 'Charlie'}, {matchId = 'AC'})
			local alphaDelta = makeMatch({'Alpha', 'Delta'}, {matchId = 'AD'})
			local bravoCharlie = makeMatch({'Bravo', 'Charlie'}, {matchId = 'BC'})
			local bravoDelta = makeMatch({'Bravo', 'Delta'}, {matchId = 'BD'})
			local charlieDelta = makeMatch({'Charlie', 'Delta'}, {matchId = 'CD'})
			local alpha = opponent('Alpha', {
				points = 2, match = {w = 1, d = 2, l = 0}, matches = {alphaBravo, alphaCharlie, alphaDelta},
				matchPoints = {AB = 0.5, AC = 1, AD = 0.5},
			})
			local bravo = opponent('Bravo', {
				points = 2, match = {w = 1, d = 2, l = 0}, matches = {alphaBravo, bravoCharlie, bravoDelta},
				matchPoints = {AB = 0.5, BC = 0.5, BD = 1},
			})
			local charlie = opponent('Charlie', {
				points = 1.5, match = {w = 1, d = 1, l = 1}, matches = {alphaCharlie, bravoCharlie, charlieDelta},
				matchPoints = {AC = 0, BC = 0.5, CD = 1},
			})
			local delta = opponent('Delta', {
				points = 0.5, match = {w = 0, d = 1, l = 2}, matches = {alphaDelta, bravoDelta, charlieDelta},
				matchPoints = {AD = 0.5, BD = 0, CD = 0},
			})
			return {alpha, bravo, charlie, delta}, alpha, bravo
		end

		it('weighs the points of faced opponents by the points gained against them', function()
			local sonnebornBerger = TiebreakerFactory.tiebreakerFromId('full.sonnebornberger')
			local state, alpha, bravo = roundRobin()

			-- Bravo (2) * 0.5 + Charlie (1.5) * 1 + Delta (0.5) * 0.5
			assert.are_equal(2.75, sonnebornBerger:valueOf(state, alpha))
			-- Alpha (2) * 0.5 + Charlie (1.5) * 0.5 + Delta (0.5) * 1
			assert.are_equal(2.25, sonnebornBerger:valueOf(state, bravo))
			assert.are_equal('2.75', sonnebornBerger:display(state, alpha))
			assert.are_equal('Sonneborn-Berger', sonnebornBerger:headerTitle())
		end)

		it('splits a tie that buchholz cannot split', function()
			local buchholzPoints = TiebreakerFactory.tiebreakerFromId('full.buchholzpoints')
			local state, alpha, bravo = roundRobin()

			assert.are_equal(4, buchholzPoints:valueOf(state, alpha))
			assert.are_equal(4, buchholzPoints:valueOf(state, bravo))
		end)

		it('uses custom points such as overtime results', function()
			local sonnebornBerger = TiebreakerFactory.tiebreakerFromId('full.sonnebornberger')
			local alpha = opponent('Alpha', {
				matches = {
					makeMatch({'Alpha', 'Bravo'}, {matchId = 'AB'}),
					makeMatch({'Alpha', 'Charlie'}, {matchId = 'AC'}),
				},
				-- Overtime win against Bravo, overtime loss against Charlie
				matchPoints = {AB = 2, AC = 1},
			})
			local state = {alpha, opponent('Bravo', {points = 6}), opponent('Charlie', {points = 4})}

			assert.are_equal(16, sonnebornBerger:valueOf(state, alpha))
		end)

		it('counts every match against the same opponent', function()
			local sonnebornBerger = TiebreakerFactory.tiebreakerFromId('full.sonnebornberger')
			local buchholzPoints = TiebreakerFactory.tiebreakerFromId('full.buchholzpoints')
			local alpha = opponent('Alpha', {
				matches = {
					makeMatch({'Alpha', 'Bravo'}, {matchId = 'M1'}),
					makeMatch({'Bravo', 'Alpha'}, {matchId = 'M2'}),
					makeMatch({'Alpha', 'Bravo'}, {matchId = 'M3'}),
				},
				matchPoints = {M1 = 1, M2 = 1, M3 = 0},
			})
			local state = {alpha, opponent('Bravo', {points = 3})}

			-- Two wins against Bravo (3), the loss adds nothing
			assert.are_equal(6, sonnebornBerger:valueOf(state, alpha))
			-- Buchholz counts Bravo once
			assert.are_equal(3, buchholzPoints:valueOf(state, alpha))
		end)

		it('ignores unfinished matches and opponents outside of the standings', function()
			local sonnebornBerger = TiebreakerFactory.tiebreakerFromId('full.sonnebornberger')
			local alpha = opponent('Alpha', {
				matches = {
					makeMatch({'Alpha', 'Bravo'}, {matchId = 'AB'}),
					makeMatch({'Alpha', 'Charlie'}, {matchId = 'AC', finished = false}),
					makeMatch({'Alpha', 'Outsider'}, {matchId = 'AO'}),
				},
				matchPoints = {AB = 1, AC = 1, AO = 1},
			})
			local state = {alpha, opponent('Bravo', {points = 2}), opponent('Charlie', {points = 5})}

			assert.are_equal(2, sonnebornBerger:valueOf(state, alpha))
		end)

		it('ignores matches without exactly two opponents', function()
			local sonnebornBerger = TiebreakerFactory.tiebreakerFromId('full.sonnebornberger')
			local alpha = opponent('Alpha', {
				matches = {makeMatch({'Alpha', 'Bravo', 'Charlie'}, {matchId = 'ABC'})},
				matchPoints = {ABC = 1},
			})
			local state = {alpha, opponent('Bravo', {points = 2}), opponent('Charlie', {points = 5})}

			assert.are_equal(0, sonnebornBerger:valueOf(state, alpha))
		end)
	end)

	describe('gamediff', function()
		it('sums game scores of finished non-walkover matches', function()
			local gamediff = TiebreakerFactory.tiebreakerFromId('full.gamediff')
			local alpha = opponent('Alpha', {
				matches = {
					makeMatch({'Alpha', 'Bravo'}, {winner = 1, scores = {2, 1}}),
					makeMatch({'Alpha', 'Charlie'}, {winner = 2, scores = {0, 2}}),
				},
			})
			-- games: (2-1) + (0-2) => w 2, l 3
			assert.are_equal(-1, gamediff:valueOf({alpha}, alpha))
			assert.are_equal('2 - 3', gamediff:display({alpha}, alpha))
		end)

		it('excludes walkover matches from the game count', function()
			local gamediff = TiebreakerFactory.tiebreakerFromId('full.gamediff')
			local alpha = opponent('Alpha', {
				matches = {
					makeMatch({'Alpha', 'Bravo'}, {winner = 1, scores = {2, 0}}),
					makeMatch({'Alpha', 'Charlie'}, {winner = 1, statuses = {'W', 'FF'}}),
				},
			})
			assert.are_equal(2, gamediff:valueOf({alpha}, alpha))
		end)
	end)

	describe('games with walkover games', function()
		local options = {walkoverGames = 2}

		-- Played: 2-1 win. Walkovers: win (W-FF), loss (DQ-W), double forfeit (FF-FF, no winner).
		local function makeAlpha()
			return opponent('Alpha', {
				matches = {
					makeMatch({'Alpha', 'Bravo'}, {winner = 1, scores = {2, 1}}),
					makeMatch({'Alpha', 'Charlie'}, {winner = 1, statuses = {'W', 'FF'}}),
					makeMatch({'Alpha', 'Delta'}, {winner = 2, statuses = {'DQ', 'W'}}),
					makeMatch({'Alpha', 'Echo'}, {winner = 0, statuses = {'FF', 'FF'}}),
				},
			})
		end

		it('credits the winner of a walkover with game wins and the loser with game losses', function()
			local TiebreakerGameUtil = require('Module:Standings/Tiebreaker/Game/Util')
			local games = TiebreakerGameUtil.getGames(makeAlpha(), 2)
			-- w: 2 + 2, l: 1 + 2 + 2
			assert.are_equal(4, games.w)
			assert.are_equal(5, games.l)
			assert.are_equal(9, games.games)
		end)

		it('does not count walkovers when unset or 0', function()
			local TiebreakerGameUtil = require('Module:Standings/Tiebreaker/Game/Util')
			local alpha = makeAlpha()
			local expected = {w = 2, l = 1, games = 3}
			Array.forEach({TiebreakerGameUtil.getGames(alpha), TiebreakerGameUtil.getGames(alpha, 0)}, function(games)
				assert.are_same(expected, {w = games.w, l = games.l, games = games.games})
			end)
		end)

		it('applies to the game tiebreakers', function()
			local alpha = makeAlpha()
			local function valueOf(name)
				local tiebreaker = TiebreakerFactory.tiebreakerFromId('full.' .. name, options)
				return tiebreaker:valueOf({alpha}, alpha)
			end
			assert.are_equal(-1, valueOf('gamediff'))
			assert.are_equal(4, valueOf('gamewins'))
			assert.are_equal(-5, valueOf('gamelosses'))
			assert.are_equal(9, valueOf('gamecount'))
			assert.are_equal(4 / 9, valueOf('gamewinrate'))
			assert.are_same({4, -5}, valueOf('gamescore'))
			assert.are_equal(-1, valueOf('gamediffregulation'))
			assert.are_equal('4 - 5', TiebreakerFactory.tiebreakerFromId('full.gamediff', options):display({alpha}, alpha))
		end)

		it('only counts finished matches decided by FF, DQ or L as walkovers', function()
			local TiebreakerGameUtil = require('Module:Standings/Tiebreaker/Game/Util')
			local alpha = opponent('Alpha', {
				matches = {
					makeMatch({'Alpha', 'Bravo'}, {winner = 1, scores = {2, 1}}),
					-- Upcoming match without statuses
					makeMatch({'Alpha', 'Charlie'}, {finished = false, statuses = {'', ''}}),
					-- Draw without a score
					makeMatch({'Alpha', 'Delta'}, {winner = 0, statuses = {'D', 'D'}}),
					-- Walkover that is not finished yet
					makeMatch({'Alpha', 'Echo'}, {finished = false, winner = 2, statuses = {'FF', 'W'}}),
					makeMatch({'Alpha', 'Foxtrot'}, {winner = 1, statuses = {'W', 'L'}}),
				},
			})
			local games = TiebreakerGameUtil.getGames(alpha, 2)
			assert.are_same({w = 4, l = 1, games = 5}, {w = games.w, l = games.l, games = games.games})
		end)

		it('reads the walkover result from the status of the opponent, not the winner of the match', function()
			local TiebreakerGameUtil = require('Module:Standings/Tiebreaker/Game/Util')
			local alpha = opponent('Alpha', {
				matches = {
					-- W without the winner set
					makeMatch({'Alpha', 'Bravo'}, {statuses = {'W', 'FF'}}),
					-- DQ while the winner points to Alpha
					makeMatch({'Alpha', 'Charlie'}, {winner = 1, statuses = {'DQ', 'W'}}),
				},
			})
			local games = TiebreakerGameUtil.getGames(alpha, 2)
			assert.are_same({w = 2, l = 2, games = 4}, {w = games.w, l = games.l, games = games.games})
		end)

		it('counts a double forfeit as a walkover loss for both opponents', function()
			local TiebreakerGameUtil = require('Module:Standings/Tiebreaker/Game/Util')
			local doubleForfeit = makeMatch({'Alpha', 'Bravo'}, {winner = -1, statuses = {'FF', 'FF'}})
			Array.forEach({'Alpha', 'Bravo'}, function(name)
				local games = TiebreakerGameUtil.getGames(opponent(name, {matches = {doubleForfeit}}), 2)
				assert.are_same({w = 0, l = 2, games = 2}, {w = games.w, l = games.l, games = games.games})
			end)
		end)

		it('gives no walkover result to an opponent with a score against a walkover loss', function()
			local TiebreakerGameUtil = require('Module:Standings/Tiebreaker/Game/Util')
			local match = makeMatch({'Alpha', 'Bravo'}, {winner = 1, statuses = {'S', 'FF'}, scores = {1, 0}})
			local alphaGames = TiebreakerGameUtil.getGames(opponent('Alpha', {matches = {match}}), 2)
			local bravoGames = TiebreakerGameUtil.getGames(opponent('Bravo', {matches = {match}}), 2)
			assert.are_same({w = 0, l = 0, games = 0}, {w = alphaGames.w, l = alphaGames.l, games = alphaGames.games})
			assert.are_same({w = 0, l = 2, games = 2}, {w = bravoGames.w, l = bravoGames.l, games = bravoGames.games})
		end)

		it('does not change the round tiebreakers', function()
			local alpha = opponent('Alpha', {
				matches = {
					makeMatch({'Alpha', 'Bravo'}, {winner = 1, statuses = {'W', 'FF'}}),
				},
			})
			local rounddiff = TiebreakerFactory.tiebreakerFromId('full.rounddiff', options)
			assert.are_equal(0, rounddiff:valueOf({alpha}, alpha))
		end)
	end)

	describe('games with overtime', function()
		local Info = require('Module:Info')
		local originalStandingsConfig

		before_each(function()
			originalStandingsConfig = Info.config.standings
			Info.config.standings = {overtime = {regulationRounds = 12}}
		end)

		after_each(function()
			Info.config.standings = originalStandingsConfig
		end)

		---Bo1 matches, where the match score is 1-0 in maps
		---@param opponentName string
		---@param otherName string
		---@param roundScores integer[]
		local function makeBo1(opponentName, otherName, roundScores)
			local ownWin = roundScores[1] > roundScores[2]
			return makeMatch({opponentName, otherName}, {
				winner = ownWin and 1 or 2,
				scores = ownWin and {1, 0} or {0, 1},
				games = {{winner = ownWin and 1 or 2, status = '', scores = roundScores}},
			})
		end

		-- Regulation: win (7-3), loss (5-7). Overtime: win (7-6), loss (6-7), loss (6-7).
		local function makeAlpha(props)
			props = props or {}
			return opponent('Alpha', {
				overtime = props.overtime,
				matches = {
					makeBo1('Alpha', 'Bravo', {7, 3}),
					makeBo1('Alpha', 'Charlie', {5, 7}),
					makeBo1('Alpha', 'Delta', {7, 6}),
					makeBo1('Alpha', 'Echo', {6, 7}),
					makeBo1('Alpha', 'Foxtrot', {6, 7}),
				},
			})
		end

		it('counts the overtime games', function()
			local TiebreakerGameUtil = require('Module:Standings/Tiebreaker/Game/Util')
			assert.are_same({w = 1, l = 2}, TiebreakerGameUtil.getOvertimeGames(makeAlpha()))
		end)

		it('ignores walkovers when counting the overtime games', function()
			local TiebreakerGameUtil = require('Module:Standings/Tiebreaker/Game/Util')
			local alpha = opponent('Alpha', {
				matches = {
					makeMatch({'Alpha', 'Bravo'}, {winner = 1, statuses = {'S', 'FF'}, scores = {1, 0}, games = {
						{winner = 1, status = '', scores = {7, 6}},
					}}),
				},
			})
			assert.are_same({w = 0, l = 0}, TiebreakerGameUtil.getOvertimeGames(alpha))
		end)

		it('does not change the gamediff value, but splits the display when overtime is tracked', function()
			local gamediff = TiebreakerFactory.tiebreakerFromId('full.gamediff')
			-- 2 map wins, 3 map losses
			local withoutOvertime = makeAlpha()
			assert.are_equal(-1, gamediff:valueOf({withoutOvertime}, withoutOvertime))
			assert.are_equal('2 - 3', gamediff:display({withoutOvertime}, withoutOvertime))

			local withOvertime = makeAlpha{overtime = {w = 1, l = 2}}
			assert.are_equal(-1, gamediff:valueOf({withOvertime}, withOvertime))
			-- regulation wins - overtime wins - overtime losses - regulation losses
			assert.are_equal('1 - 1 - 2 - 1', gamediff:display({withOvertime}, withOvertime))
		end)

		it('gamediffregulation only counts the regulation games', function()
			local gamediffregulation = TiebreakerFactory.tiebreakerFromId('full.gamediffregulation')
			local alpha = makeAlpha()
			-- Regulation: 1 win, 1 loss
			assert.are_equal(0, gamediffregulation:valueOf({alpha}, alpha))
			assert.are_equal('1 - 1', gamediffregulation:display({alpha}, alpha))
			assert.are_equal('Games (Reg.)', gamediffregulation:headerTitle())
		end)

		it('gamediffregulation is not affected by overtime being tracked', function()
			local gamediffregulation = TiebreakerFactory.tiebreakerFromId('full.gamediffregulation')
			local alpha = makeAlpha{overtime = {w = 1, l = 2}}
			assert.are_equal('1 - 1', gamediffregulation:display({alpha}, alpha))
		end)

		it('gamediffregulation behaves like gamediff without regulation rounds configured', function()
			Info.config.standings = {}
			local gamediff = TiebreakerFactory.tiebreakerFromId('full.gamediff')
			local gamediffregulation = TiebreakerFactory.tiebreakerFromId('full.gamediffregulation')
			local alpha = makeAlpha()
			assert.are_equal(gamediff:valueOf({alpha}, alpha), gamediffregulation:valueOf({alpha}, alpha))
			assert.are_equal('2 - 3', gamediffregulation:display({alpha}, alpha))
		end)

		it('gamediffregulation excludes walkover matches', function()
			local gamediffregulation = TiebreakerFactory.tiebreakerFromId('full.gamediffregulation')
			local alpha = opponent('Alpha', {
				matches = {
					makeBo1('Alpha', 'Bravo', {7, 3}),
					makeMatch({'Alpha', 'Charlie'}, {winner = 1, statuses = {'W', 'FF'}}),
				},
			})
			assert.are_equal(1, gamediffregulation:valueOf({alpha}, alpha))
		end)
	end)

	describe('rounddiff', function()
		it('sums round scores from played games', function()
			local rounddiff = TiebreakerFactory.tiebreakerFromId('full.rounddiff')
			local alpha = opponent('Alpha', {
				matches = {
					makeMatch({'Alpha', 'Bravo'}, {winner = 1, games = {
						{winner = 1, status = '', scores = {13, 7}},
						{winner = 2, status = '', scores = {5, 13}},
						{winner = 1, status = 'notplayed', scores = {}},
						{winner = '', status = '', scores = {0, 0}},
					}}),
				},
			})
			-- played games only: 13+5 = 18 won rounds, (13+7)+(5+13) = 38 total
			assert.are_equal(-2, rounddiff:valueOf({alpha}, alpha))
			assert.are_equal('18 - 20', rounddiff:display({alpha}, alpha))
		end)
	end)

	describe('rounds with walkover rounds', function()
		local options = {walkoverRounds = 13}

		-- Played: 13-7 game win. Walkovers: win (W-FF), loss (DQ-W), double forfeit (FF-FF, no winner).
		local function makeAlpha()
			return opponent('Alpha', {
				matches = {
					makeMatch({'Alpha', 'Bravo'}, {winner = 1, scores = {1, 0}, games = {
						{winner = 1, status = '', scores = {13, 7}},
					}}),
					makeMatch({'Alpha', 'Charlie'}, {winner = 1, statuses = {'W', 'FF'}}),
					makeMatch({'Alpha', 'Delta'}, {winner = 2, statuses = {'DQ', 'W'}}),
					makeMatch({'Alpha', 'Echo'}, {winner = 0, statuses = {'FF', 'FF'}}),
				},
			})
		end

		it('credits the winner of a walkover with round wins and the loser with round losses', function()
			local TiebreakerRoundUtil = require('Module:Standings/Tiebreaker/Game/Rounds/Util')
			-- w: 13 + 13, l: 7 + 13 + 13
			assert.are_same({rounds = 59, w = 26, l = 33}, TiebreakerRoundUtil.getRounds(makeAlpha(), 13))
		end)

		it('does not count walkovers when unset or 0', function()
			local TiebreakerRoundUtil = require('Module:Standings/Tiebreaker/Game/Rounds/Util')
			local alpha = makeAlpha()
			local expected = {rounds = 20, w = 13, l = 7}
			assert.are_same(expected, TiebreakerRoundUtil.getRounds(alpha))
			assert.are_same(expected, TiebreakerRoundUtil.getRounds(alpha, 0))
		end)

		it('applies to the round tiebreakers', function()
			local alpha = makeAlpha()
			local function valueOf(name)
				local tiebreaker = TiebreakerFactory.tiebreakerFromId('full.' .. name, options)
				return tiebreaker:valueOf({alpha}, alpha)
			end
			assert.are_equal(-7, valueOf('rounddiff'))
			assert.are_equal(26, valueOf('roundwins'))
			assert.are_equal(-33, valueOf('roundlosses'))
			assert.are_equal(26 / 59, valueOf('roundwinrate'))
			assert.are_same({26, -33}, valueOf('roundscore'))
			assert.are_equal('26 - 33', TiebreakerFactory.tiebreakerFromId('full.rounddiff', options):display({alpha}, alpha))
		end)

		it('does not change the game tiebreakers', function()
			local alpha = makeAlpha()
			local gamediff = TiebreakerFactory.tiebreakerFromId('full.gamediff', options)
			assert.are_equal(1, gamediff:valueOf({alpha}, alpha))
		end)

		it('counts a walkover of the match as the maps needed to win the match', function()
			local TiebreakerRoundUtil = require('Module:Standings/Tiebreaker/Game/Rounds/Util')
			local match = makeMatch({'Alpha', 'Bravo'}, {winner = 1, statuses = {'W', 'FF'}})
			match.bestof = 3
			local alpha = opponent('Alpha', {matches = {match}})
			local bravo = opponent('Bravo', {matches = {match}})
			assert.are_same({rounds = 26, w = 26, l = 0}, TiebreakerRoundUtil.getRounds(alpha, 13))
			assert.are_same({rounds = 26, w = 0, l = 26}, TiebreakerRoundUtil.getRounds(bravo, 13))
		end)

		it('counts the maps needed to win an even best-of', function()
			local TiebreakerRoundUtil = require('Module:Standings/Tiebreaker/Game/Rounds/Util')
			local match = makeMatch({'Alpha', 'Bravo'}, {winner = 1, statuses = {'W', 'FF'}})
			match.bestof = 2
			local alpha = opponent('Alpha', {matches = {match}})
			assert.are_same({rounds = 26, w = 26, l = 0}, TiebreakerRoundUtil.getRounds(alpha, 13))
		end)

		it('counts a walkover of the match as walkovergames maps when set', function()
			local TiebreakerRoundUtil = require('Module:Standings/Tiebreaker/Game/Rounds/Util')
			local match = makeMatch({'Alpha', 'Bravo'}, {winner = 1, statuses = {'W', 'FF'}})
			match.bestof = 3
			local alpha = opponent('Alpha', {matches = {match}})
			assert.are_same({rounds = 39, w = 39, l = 0}, TiebreakerRoundUtil.getRounds(alpha, 13, 3))
			assert.are_same({rounds = 0, w = 0, l = 0}, TiebreakerRoundUtil.getRounds(alpha, 13, 0))

			local rounddiff = TiebreakerFactory.tiebreakerFromId('full.rounddiff', {walkoverRounds = 13, walkoverGames = 3})
			assert.are_equal(39, rounddiff:valueOf({alpha}, alpha))
		end)

		---Bo3 won 2-1, with the second map a walkover won by Bravo
		local function makeMapWalkoverMatch()
			return makeMatch({'Alpha', 'Bravo'}, {winner = 1, scores = {2, 1}, games = {
				{winner = 1, status = '', scores = {13, 7}, opponents = {{status = 'S'}, {status = 'S'}}},
				{winner = 2, status = '', scores = {-1, -1}, opponents = {{status = 'FF'}, {status = 'W'}}},
				{winner = 1, status = '', scores = {13, 11}, opponents = {{status = 'S'}, {status = 'S'}}},
			}})
		end

		it('counts a walkover of a single map', function()
			local TiebreakerRoundUtil = require('Module:Standings/Tiebreaker/Game/Rounds/Util')
			local match = makeMapWalkoverMatch()
			local alpha = opponent('Alpha', {matches = {match}})
			local bravo = opponent('Bravo', {matches = {match}})
			-- Alpha w: 13 + 13, l: 7 + 11 + 13
			assert.are_same({rounds = 57, w = 26, l = 31}, TiebreakerRoundUtil.getRounds(alpha, 13))
			assert.are_same({rounds = 57, w = 31, l = 26}, TiebreakerRoundUtil.getRounds(bravo, 13))
		end)

		it('does not use walkovergames for walkovers of a single map', function()
			local TiebreakerRoundUtil = require('Module:Standings/Tiebreaker/Game/Rounds/Util')
			local alpha = opponent('Alpha', {matches = {makeMapWalkoverMatch()}})
			assert.are_same({rounds = 57, w = 26, l = 31}, TiebreakerRoundUtil.getRounds(alpha, 13, 2))
		end)

		it('does not count the scores of a walkover of a map as rounds', function()
			local TiebreakerRoundUtil = require('Module:Standings/Tiebreaker/Game/Rounds/Util')
			local alpha = opponent('Alpha', {matches = {makeMapWalkoverMatch()}})
			assert.are_same({rounds = 44, w = 26, l = 18}, TiebreakerRoundUtil.getRounds(alpha))
		end)

		it('does not count walkovers of maps on top of the walkover of the match', function()
			local TiebreakerRoundUtil = require('Module:Standings/Tiebreaker/Game/Rounds/Util')
			local match = makeMatch({'Alpha', 'Bravo'}, {winner = 1, statuses = {'W', 'FF'}, games = {
				{winner = 1, status = '', scores = {-1, -1}, opponents = {{status = 'W'}, {status = 'FF'}}},
			}})
			local alpha = opponent('Alpha', {matches = {match}})
			assert.are_same({rounds = 13, w = 13, l = 0}, TiebreakerRoundUtil.getRounds(alpha, 13))
		end)
	end)

	describe('roundwinrate', function()
		it('is the share of rounds won in played games', function()
			local roundwinrate = TiebreakerFactory.tiebreakerFromId('full.roundwinrate')
			local alpha = opponent('Alpha', {
				matches = {
					makeMatch({'Alpha', 'Bravo'}, {winner = 1, games = {
						{winner = 1, status = '', scores = {13, 7}},
						{winner = 2, status = '', scores = {7, 13}},
						{winner = 1, status = 'notplayed', scores = {}},
					}}),
				},
			})
			-- 20 of 40 rounds won
			assert.are_equal(0.5, roundwinrate:valueOf({alpha}, alpha))
			assert.are_equal('50.00%', roundwinrate:display({alpha}, alpha))
		end)

		it('displays a dash when no rounds have been played', function()
			local roundwinrate = TiebreakerFactory.tiebreakerFromId('full.roundwinrate')
			local alpha = opponent('Alpha')
			assert.are_equal(0.5, roundwinrate:valueOf({alpha}, alpha))
			assert.are_equal('-', roundwinrate:display({alpha}, alpha))
		end)

		it('can be used in the head-to-head context', function()
			assert.are_equal('ml.roundwinrate', TiebreakerFactory.validateAndNormalizeInput('ml.roundwinrate'))
		end)
	end)

	describe('gamewinrate', function()
		it('displays the game win rate', function()
			local gamewinrate = TiebreakerFactory.tiebreakerFromId('full.gamewinrate')
			local alpha = opponent('Alpha', {
				matches = {
					makeMatch({'Alpha', 'Bravo'}, {winner = 1, scores = {2, 1}}),
					makeMatch({'Alpha', 'Charlie'}, {winner = 2, scores = {1, 2}}),
				},
			})
			assert.are_equal('50.00%', gamewinrate:display({alpha}, alpha))
		end)

		it('displays a dash when no games have been played', function()
			local gamewinrate = TiebreakerFactory.tiebreakerFromId('full.gamewinrate')
			local alpha = opponent('Alpha')
			assert.are_equal(0.5, gamewinrate:valueOf({alpha}, alpha))
			assert.are_equal('-', gamewinrate:display({alpha}, alpha))
		end)
	end)

	describe('losses', function()
		it('sums match losses from played games', function()
			local matchlosses = TiebreakerFactory.tiebreakerFromId('full.matchlosses')
			local opp = opponent('Alpha', {match = {w = 3, d = 1, l = 1}})
			assert.are_equal(-1, matchlosses:valueOf({opp}, opp))
			assert.are_equal('3 - 1', matchlosses:display({opp}, opp))
		end)
	end)

	describe('shared columns', function()
		local GAMES_AND_ROUNDS = {
			makeMatch({'Alpha', 'Bravo'}, {winner = 1, scores = {2, 1}, games = {
				{winner = 1, status = '', scores = {13, 7}},
				{winner = 2, status = '', scores = {5, 13}},
				{winner = 1, status = '', scores = {13, 11}},
			}}),
		}

		---@param ids string[]
		---@param opp table
		---@param options table?
		local function assertSameColumn(ids, opp, options)
			local first = TiebreakerFactory.tiebreakerFromId(ids[1], options)
			Array.forEach(ids, function(id)
				local tiebreaker = TiebreakerFactory.tiebreakerFromId(id, options)
				assert.are_equal(first:headerTitle(), tiebreaker:headerTitle(), id)
				assert.are_equal(first:display({opp}, opp), tiebreaker:display({opp}, opp), id)
			end)
		end

		it('shows all match record tiebreakers in the matches column', function()
			local opp = opponent('Alpha', {match = {w = 3, d = 1, l = 1}})
			local ids = {'full.matchdiff', 'full.matchwins', 'full.matchdraws', 'full.matchlosses', 'full.matchscore'}
			assertSameColumn(ids, opp)
			assertSameColumn(ids, opp, {draws = {match = true}})
			assert.are_equal('Matches', TiebreakerFactory.tiebreakerFromId('full.matchscore'):headerTitle())
			assert.are_equal('3 - 1 - 1',
				TiebreakerFactory.tiebreakerFromId('full.matchscore', {draws = {match = true}}):display({opp}, opp))
		end)

		it('shows all game record tiebreakers in the games column', function()
			local opp = opponent('Alpha', {matches = GAMES_AND_ROUNDS})
			assertSameColumn({'full.gamediff', 'full.gamewins', 'full.gamelosses', 'full.gamescore'}, opp)
			assert.are_equal('Games', TiebreakerFactory.tiebreakerFromId('full.gamescore'):headerTitle())
			assert.are_equal('2 - 1', TiebreakerFactory.tiebreakerFromId('full.gamescore'):display({opp}, opp))
		end)

		it('shows all round record tiebreakers in the rounds column', function()
			local opp = opponent('Alpha', {matches = GAMES_AND_ROUNDS})
			assertSameColumn({'full.rounddiff', 'full.roundwins', 'full.roundlosses', 'full.roundscore'}, opp)
			assert.are_equal('Rounds', TiebreakerFactory.tiebreakerFromId('full.roundscore'):headerTitle())
			assert.are_equal('31 - 31', TiebreakerFactory.tiebreakerFromId('full.roundscore'):display({opp}, opp))
		end)
	end)

	describe('score', function()
		it('is the wins followed by the negated losses on match level', function()
			local matchscore = TiebreakerFactory.tiebreakerFromId('full.matchscore')
			local opp = opponent('Alpha', {match = {w = 3, d = 1, l = 2}})
			assert.are_same({3, -2}, matchscore:valueOf({opp}, opp))
		end)

		it('is the wins followed by the negated losses on game level', function()
			local gamescore = TiebreakerFactory.tiebreakerFromId('full.gamescore')
			local alpha = opponent('Alpha', {
				matches = {
					makeMatch({'Alpha', 'Bravo'}, {winner = 1, scores = {2, 1}}),
					makeMatch({'Alpha', 'Charlie'}, {winner = 2, scores = {1, 2}}),
					makeMatch({'Alpha', 'Delta'}, {winner = 1, statuses = {'W', 'FF'}}),
				},
			})
			assert.are_same({3, -3}, gamescore:valueOf({alpha}, alpha))
		end)

		it('is the wins followed by the negated losses on round level', function()
			local roundscore = TiebreakerFactory.tiebreakerFromId('full.roundscore')
			local alpha = opponent('Alpha', {
				matches = {
					makeMatch({'Alpha', 'Bravo'}, {winner = 1, games = {
						{winner = 1, status = '', scores = {13, 7}},
						{winner = 2, status = '', scores = {5, 13}},
					}}),
				},
			})
			assert.are_same({18, -20}, roundscore:valueOf({alpha}, alpha))
		end)
	end)
end)
