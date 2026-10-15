--- Triple Comment to Enable our LLS Plugin
describe('Standings Tiebreakers', function()
	local TiebreakerFactory = require('Module:Standings/Tiebreaker/Factory')
	local Array = require('Module:Array')

	local function literal(name)
		return {type = 'literal', name = name}
	end

	---@param name string
	---@param props {points: number?, matches: table[]?, match: table?, tiebreakerpoints: number?}?
	---@return table
	local function opponent(name, props)
		props = props or {}
		return {
			opponent = literal(name),
			points = props.points or 0,
			matches = props.matches or {},
			match = props.match or {w = 0, d = 0, l = 0},
			extradata = {additionalStatsValues = {}, tiebreakerpoints = props.tiebreakerpoints},
		}
	end

	---@param opponentNames string[]
	---@param props {finished: boolean?, winner: integer?, games: table[]?, statuses: string[]?, scores: integer[]?}?
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
			matchId = 'FakeMatch',
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
			assert.are_equal('full.disqualified', TiebreakerFactory.validateAndNormalizeInput('disqualified'))
			assert.error(function() TiebreakerFactory.validateAndNormalizeInput('bogus') end)
			assert.error(function() TiebreakerFactory.validateAndNormalizeInput('badcontext.points') end)
			assert.error(function() TiebreakerFactory.validateAndNormalizeInput('h2h.points') end)
		end)

		it('rejects non full contexts for tiebreakers not derived from matches among tied opponents', function()
			local names = {
				'buchholz', 'medianbuchholz', 'buchholzpoints', 'medianbuchholzpoints',
				'manual', 'disqualified', 'startingpoints',
			}
			Array.forEach(names, function(name)
				assert.are_equal('full.' .. name, TiebreakerFactory.validateAndNormalizeInput(name))
				assert.error(function() TiebreakerFactory.validateAndNormalizeInput('ml.' .. name) end)
			end)
		end)

		it('accepts the ml context for match based tiebreakers', function()
			assert.are_equal('ml.matchdiff', TiebreakerFactory.validateAndNormalizeInput('ml.matchdiff'))
			assert.are_equal('ml.gamediff', TiebreakerFactory.validateAndNormalizeInput('ml.gamediff'))
			assert.are_equal('ml.matchscore', TiebreakerFactory.validateAndNormalizeInput('ml.matchscore'))
		end)

		it('exposes context', function()
			assert.are_equal('full', TiebreakerFactory.tiebreakerFromId('full.points'):getContextType())
			assert.are_equal('ml', TiebreakerFactory.tiebreakerFromId('ml.matchdiff'):getContextType())
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
