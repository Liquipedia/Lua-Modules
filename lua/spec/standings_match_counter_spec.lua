--- Triple Comment to Enable our LLS Plugin
describe('Standings Tiebreaker MatchCounter', function()
	local TiebreakerMatchCounter = require('Module:Standings/Tiebreaker/MatchCounter')

	---@param names string[]
	---@return table
	local function makeMatch(names)
		local opponents = {}
		for _, name in ipairs(names) do
			table.insert(opponents, {type = 'literal', name = name})
		end
		return {opponents = opponents, games = {}}
	end

	---@param matches table[]
	---@param previousRound table?
	---@return table
	local function makeRound(matches, previousRound)
		return {opponent = {type = 'literal', name = 'Alpha'}, matches = matches, previousRound = previousRound}
	end

	---Counts the matches and the sum of the opponent indices, and records which matches were added
	---@return fun(opponent: table): table, table[]
	local function makeCounter()
		local added = {}
		local count = TiebreakerMatchCounter.create({matches = 0, indices = {sum = 0}}, function(counts, match, index)
			table.insert(added, match)
			counts.matches = counts.matches + 1
			counts.indices.sum = counts.indices.sum + index
		end)
		return count, added
	end

	describe('create', function()
		it('counts the matches with the index of the opponent in them', function()
			local count = makeCounter()
			local round = makeRound{makeMatch{'Alpha', 'Bravo'}, makeMatch{'Charlie', 'Alpha'}, makeMatch{'Bravo', 'Delta'}}
			assert.are_same({matches = 3, indices = {sum = 3}}, count(round))
		end)

		it('continues the counts of the round before and only adds the new matches', function()
			local count, added = makeCounter()
			local first, second = makeMatch{'Alpha', 'Bravo'}, makeMatch{'Charlie', 'Alpha'}
			local previousRound = makeRound{first}
			local round = makeRound({first, second}, previousRound)

			assert.are_same({matches = 1, indices = {sum = 1}}, count(previousRound))
			assert.are_same({matches = 2, indices = {sum = 3}}, count(round))
			assert.are_same({first, second}, added)
			-- The counts of the round before are left as they were
			assert.are_same({matches = 1, indices = {sum = 1}}, count(previousRound))
		end)

		it('counts all matches when the round before has other matches', function()
			local count, added = makeCounter()
			local first, second = makeMatch{'Alpha', 'Bravo'}, makeMatch{'Charlie', 'Alpha'}
			local previousRound = makeRound{second}
			local round = makeRound({first}, previousRound)

			assert.are_same({matches = 1, indices = {sum = 1}}, count(round))
			assert.are_same({first}, added)
		end)

		it('memoizes the counts per round', function()
			local count, added = makeCounter()
			local round = makeRound{makeMatch{'Alpha', 'Bravo'}}
			assert.are_equal(count(round), count(round))
			assert.are_equal(1, #added)
		end)
	end)

	describe('continuedRound', function()
		it('is the round before with the index of the first new match', function()
			local first, second = makeMatch{'Alpha', 'Bravo'}, makeMatch{'Charlie', 'Alpha'}
			local previousRound = makeRound{first}
			local previous, firstMatchIndex = TiebreakerMatchCounter.continuedRound(makeRound({first, second}, previousRound))
			assert.are_equal(previousRound, previous)
			assert.are_equal(2, firstMatchIndex)
		end)

		it('is nothing without a round before or when its matches are not the first matches', function()
			local first, second = makeMatch{'Alpha', 'Bravo'}, makeMatch{'Charlie', 'Alpha'}
			assert.are_same({nil, 1}, {TiebreakerMatchCounter.continuedRound(makeRound{first})})
			assert.are_same({nil, 1}, {TiebreakerMatchCounter.continuedRound(makeRound({first}, makeRound{second}))})
			assert.are_same({nil, 1}, {TiebreakerMatchCounter.continuedRound(makeRound({first}, makeRound{first, second}))})
		end)
	end)
end)
