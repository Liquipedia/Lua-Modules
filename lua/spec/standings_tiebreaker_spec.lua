--- Triple Comment to Enable our LLS Plugin
describe('Standings Tiebreakers', function()
	local TiebreakerFactory = require('Module:Standings/Tiebreaker/Factory')

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
			extradata = {tiebreakerValues = {}, tiebreakerpoints = props.tiebreakerpoints},
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
			matchId = props.matchId or 'FakeMatch',
			finished = props.finished ~= false,
			winner = props.winner,
			opponents = matchOpponents,
			games = props.games or {},
		}
	end

	describe('factory', function()
		it('normalizes inputs', function()
			assert.are_equal('full.points', TiebreakerFactory.validateAndNormalizeInput('points'))
			assert.are_equal('h2h.points', TiebreakerFactory.validateAndNormalizeInput('h2h.points'))
			assert.error(function() TiebreakerFactory.validateAndNormalizeInput('bogus') end)
			assert.error(function() TiebreakerFactory.validateAndNormalizeInput('badcontext.points') end)
		end)

		it('exposes context', function()
			assert.are_equal('full', TiebreakerFactory.tiebreakerFromId('full.points'):getContextType())
			assert.are_equal('h2h', TiebreakerFactory.tiebreakerFromId('h2h.matchdiff'):getContextType())
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

	describe('matchdiff', function()
		it('uses the match scoreboard', function()
			local matchdiff = TiebreakerFactory.tiebreakerFromId('full.matchdiff')
			local opp = opponent('Alpha', {match = {w = 3, d = 1, l = 1}})
			assert.are_equal(2, matchdiff:valueOf({opp}, opp))
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
end)
