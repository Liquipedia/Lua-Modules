--- Triple Comment to Enable our LLS Plugin
describe('Standings Tiebreakers', function()
	local TiebreakerFactory = require('Module:Standings/Tiebreaker/Factory')
	local Array = require('Module:Array')

	local function literal(name)
		return {type = 'literal', name = name}
	end

	---@param name string
	---@param props {points: number?, matches: table[]?, match: table?, overtime: table?, tiebreakerpoints: number?}?
	---@return table
	local function opponent(name, props)
		props = props or {}
		return {
			opponent = literal(name),
			points = props.points or 0,
			matches = props.matches or {},
			match = props.match or {w = 0, d = 0, l = 0},
			overtime = props.overtime,
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

	describe('factory', function()
		it('normalizes inputs', function()
			assert.are_equal('full.points', TiebreakerFactory.validateAndNormalizeInput('points'))
			assert.are_equal('h2holdcs.points', TiebreakerFactory.validateAndNormalizeInput('h2holdcs.points'))
			assert.are_equal('h2hlegacy.points', TiebreakerFactory.validateAndNormalizeInput('h2hlegacy.points'))
			assert.are_equal('full.disqualified', TiebreakerFactory.validateAndNormalizeInput('disqualified'))
			assert.error(function() TiebreakerFactory.validateAndNormalizeInput('bogus') end)
			assert.error(function() TiebreakerFactory.validateAndNormalizeInput('badcontext.points') end)
			assert.error(function() TiebreakerFactory.validateAndNormalizeInput('h2h.points') end)
		end)

		it('rejects non full contexts for tiebreakers not derived from matches among tied opponents', function()
			Array.forEach({'buchholz', 'manual', 'disqualified', 'startingpoints'}, function(name)
				assert.are_equal('full.' .. name, TiebreakerFactory.validateAndNormalizeInput(name))
				assert.error(function() TiebreakerFactory.validateAndNormalizeInput('h2holdcs.' .. name) end)
				assert.error(function() TiebreakerFactory.validateAndNormalizeInput('h2hlegacy.' .. name) end)
				assert.error(function() TiebreakerFactory.validateAndNormalizeInput('ml.' .. name) end)
			end)
		end)

		it('accepts h2holdcs, h2hlegacy and ml contexts for match based tiebreakers', function()
			assert.are_equal('h2holdcs.matchdiff', TiebreakerFactory.validateAndNormalizeInput('h2holdcs.matchdiff'))
			assert.are_equal(
				'h2hlegacy.matchdiff', TiebreakerFactory.validateAndNormalizeInput('h2hlegacy.matchdiff')
			)
			assert.are_equal('ml.gamediff', TiebreakerFactory.validateAndNormalizeInput('ml.gamediff'))
			assert.are_equal('ml.points', TiebreakerFactory.validateAndNormalizeInput('ml.points'))
		end)

		it('exposes context', function()
			assert.are_equal('full', TiebreakerFactory.tiebreakerFromId('full.points'):getContextType())
			assert.are_equal('h2holdcs', TiebreakerFactory.tiebreakerFromId('h2holdcs.matchdiff'):getContextType())
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
			assert.are_equal('3', tiebreaker('matchlosses'):display({opp}, opp))
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

	describe('losses', function()
		it('sums match losses from played games', function()
			local matchlosses = TiebreakerFactory.tiebreakerFromId('full.matchlosses')
			local opp = opponent('Alpha', {match = {w = 3, d = 1, l = 1}})
			assert.are_equal(-1, matchlosses:valueOf({opp}, opp))
			assert.are_equal('1', matchlosses:display({opp}, opp))
		end)
	end)
end)
