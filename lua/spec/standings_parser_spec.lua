--- Triple Comment to Enable our LLS Plugin
describe('Standings Parser', function()
	local StandingsParser = require('Module:Standings/Parser')
	local Array = require('Module:Array')

	local function literal(name)
		return {type = 'literal', name = name}
	end

	---Builds StandingTableOpponentData analogous to StandingsParseWiki.parseWikiOpponent output
	---@param name string
	---@param roundsSpec {points: number?, status: string?, tiebreaker: number?}[]
	---@param startingPoints number?
	---@return table
	local function makeOpponent(name, roundsSpec, startingPoints)
		return {
			opponent = literal(name),
			startingPoints = startingPoints,
			rounds = Array.map(roundsSpec, function(roundSpec)
				return {
					scoreboard = {points = roundSpec.points},
					specialstatus = roundSpec.status or '',
					tiebreakerPoints = roundSpec.tiebreaker,
				}
			end),
		}
	end

	local function findEntry(entries, name, roundIndex)
		return Array.find(entries, function(entry)
			return entry.opponent.name == name and entry.roundindex == roundIndex
		end)
	end

	local TWO_FINISHED_ROUNDS = {
		{roundNumber = 1, started = true, finished = true, title = 'Round 1'},
		{roundNumber = 2, started = true, finished = true, title = 'Round 2'},
	}
	local BGS = {[1] = 'up', [2] = 'stay', [3] = 'down'}
	local TIEBREAKERS = {'full.points', 'full.manual'}

	it('computes points, placements, statuses and placement changes across rounds', function()
		local opponents = {
			makeOpponent('Alpha', {{points = 3}, {points = 0}}),
			makeOpponent('Bravo', {{points = 3}, {points = 3}}),
			makeOpponent('Charlie', {{points = 0}, {points = 3, tiebreaker = 1}}),
		}

		local standingsTable = StandingsParser.parse(
			TWO_FINISHED_ROUNDS, opponents, BGS, 'My Title', {}, 'ffa', TIEBREAKERS)

		assert.are_equal(0, standingsTable.standingsindex)
		assert.are_equal('My Title', standingsTable.title)
		assert.are_equal('ffa', standingsTable.type)
		assert.are_equal(2, standingsTable.roundcount)
		assert.is_true(standingsTable.finished)
		assert.are_equal(6, #standingsTable.entries)
		assert.are_same({
			{id = 'full.points', title = 'Points'},
			{id = 'full.manual'},
		}, standingsTable.extradata.additionalStats)

		-- Round 1: Alpha and Bravo are fully tied at 3 points (shared placement),
		-- Charlie is last
		local alpha1 = findEntry(standingsTable.entries, 'Alpha', 1)
		local bravo1 = findEntry(standingsTable.entries, 'Bravo', 1)
		local charlie1 = findEntry(standingsTable.entries, 'Charlie', 1)

		assert.are_equal(3, alpha1.points)
		assert.are_equal(1, alpha1.placement)
		assert.are_equal(1, alpha1.slotindex)
		assert.are_equal('up', alpha1.currentstatus)
		assert.is_nil(alpha1.definitestatus)
		assert.is_nil(alpha1.placementchange)

		assert.are_equal(3, bravo1.points)
		assert.are_equal(1, bravo1.placement)
		assert.are_equal(2, bravo1.slotindex)
		assert.are_equal('stay', bravo1.currentstatus)

		assert.are_equal(0, charlie1.points)
		assert.are_equal(3, charlie1.placement)
		assert.are_equal(3, charlie1.slotindex)
		assert.are_equal('down', charlie1.currentstatus)

		-- Round 2 totals: Bravo 6, Charlie 3 (manual tiebreaker 1), Alpha 3 (manual tiebreaker 0)
		local alpha2 = findEntry(standingsTable.entries, 'Alpha', 2)
		local bravo2 = findEntry(standingsTable.entries, 'Bravo', 2)
		local charlie2 = findEntry(standingsTable.entries, 'Charlie', 2)

		assert.are_equal(6, bravo2.points)
		assert.are_equal(1, bravo2.placement)
		assert.are_equal(1, bravo2.slotindex)
		assert.are_equal(0, bravo2.placementchange)
		assert.are_equal('up', bravo2.currentstatus)
		assert.are_equal('up', bravo2.definitestatus)

		assert.are_equal(3, charlie2.points)
		assert.are_equal(2, charlie2.placement)
		assert.are_equal(2, charlie2.slotindex)
		assert.are_equal(1, charlie2.placementchange)
		assert.are_equal('stay', charlie2.definitestatus)

		assert.are_equal(3, alpha2.points)
		assert.are_equal(3, alpha2.placement)
		assert.are_equal(3, alpha2.slotindex)
		assert.are_equal(-2, alpha2.placementchange)
		assert.are_equal('down', alpha2.definitestatus)

		-- extradata on entries
		assert.are_equal(0, alpha2.extradata.pointschange)
		assert.are_equal(3, bravo2.extradata.pointschange)
		assert.are_equal(1, charlie2.extradata.tiebreakerpoints)
		assert.are_equal(0, alpha2.extradata.tiebreakerpoints)

		-- additionalStats are calculated for "full" context tiebreakers
		assert.are_equal(6, bravo2.extradata.additionalStatsValues['full.points'].value)
		assert.are_equal(3, charlie2.extradata.additionalStatsValues['full.points'].value)
		assert.are_equal(1, charlie2.extradata.additionalStatsValues['full.manual'].value)
	end)

	it('applies starting points', function()
		local opponents = {
			makeOpponent('Alpha', {{points = 0}, {points = 0}}, 10),
			makeOpponent('Bravo', {{points = 3}, {points = 3}}),
		}

		local standingsTable = StandingsParser.parse(
			TWO_FINISHED_ROUNDS, opponents, BGS, nil, {}, 'ffa', TIEBREAKERS)

		local alpha2 = findEntry(standingsTable.entries, 'Alpha', 2)
		local bravo2 = findEntry(standingsTable.entries, 'Bravo', 2)
		assert.are_equal(10, alpha2.points)
		assert.are_equal(1, alpha2.placement)
		assert.are_equal(6, bravo2.points)
		assert.are_equal(2, bravo2.placement)
	end)

	it('carries special status into entries', function()
		local opponents = {
			makeOpponent('Alpha', {{points = 3}, {points = 3}}),
			makeOpponent('Bravo', {{points = 0}, {status = 'nc'}}),
		}

		local standingsTable = StandingsParser.parse(
			TWO_FINISHED_ROUNDS, opponents, BGS, nil, {}, 'ffa', TIEBREAKERS)

		local bravo2 = findEntry(standingsTable.entries, 'Bravo', 2)
		assert.are_equal('nc', bravo2.extradata.specialstatus)
		assert.are_equal(0, bravo2.points)
	end)

	it('does not set definite status on unfinished standings', function()
		local rounds = {
			{roundNumber = 1, started = true, finished = true},
			{roundNumber = 2, started = true, finished = false},
		}
		local opponents = {
			makeOpponent('Alpha', {{points = 3}, {points = 3}}),
			makeOpponent('Bravo', {{points = 0}, {points = 0}}),
		}

		local standingsTable = StandingsParser.parse(rounds, opponents, BGS, nil, {}, 'ffa', TIEBREAKERS)

		assert.is_false(standingsTable.finished)
		Array.forEach(standingsTable.entries, function(entry)
			assert.is_nil(entry.definitestatus)
			assert.is_not_nil(entry.currentstatus)
		end)
	end)

	it('accumulates match scoreboard across rounds', function()
		local opponents = {
			{
				opponent = literal('Alpha'),
				rounds = {
					{scoreboard = {points = 3, match = {w = 1, d = 0, l = 0}}, specialstatus = ''},
					{scoreboard = {points = 0, match = {w = 0, d = 1, l = 1}}, specialstatus = ''},
				},
			},
			makeOpponent('Bravo', {{points = 0}, {points = 0}}),
		}

		local standingsTable = StandingsParser.parse(
			TWO_FINISHED_ROUNDS, opponents, BGS, nil, {}, 'ffa', TIEBREAKERS)

		local alpha1 = findEntry(standingsTable.entries, 'Alpha', 1)
		local alpha2 = findEntry(standingsTable.entries, 'Alpha', 2)
		assert.are_same({w = 1, d = 0, l = 0}, alpha1.match)
		assert.are_same({w = 1, d = 1, l = 1}, alpha2.match)
	end)

	describe('match draws', function()
		local MATCHDIFF_TIEBREAKERS = {'full.matchdiff', 'full.manual'}

		---@param drawInRoundTwo boolean
		local function makeOpponents(drawInRoundTwo)
			local secondRound = drawInRoundTwo
				and {w = 0, d = 1, l = 0}
				or {w = 0, d = 0, l = 1}
			return {
				{
					opponent = literal('Alpha'),
					rounds = {
						{scoreboard = {points = 1, match = {w = 1, d = 0, l = 0}}, specialstatus = ''},
						{scoreboard = {points = 0, match = secondRound}, specialstatus = ''},
					},
				},
				{
					opponent = literal('Bravo'),
					rounds = {
						{scoreboard = {points = 0, match = {w = 0, d = 0, l = 1}}, specialstatus = ''},
						{scoreboard = {points = 0, match = drawInRoundTwo
							and {w = 0, d = 1, l = 0}
							or {w = 1, d = 0, l = 0}
						}, specialstatus = ''},
					},
				},
			}
		end

		local function display(standingsTable, name, roundIndex)
			return findEntry(standingsTable.entries, name, roundIndex)
				.extradata.additionalStatsValues['full.matchdiff'].display
		end

		it('shows draws in every round when any match in the table is a draw', function()
			local standingsTable = StandingsParser.parse(
				TWO_FINISHED_ROUNDS, makeOpponents(true), BGS, nil, {}, 'swiss', MATCHDIFF_TIEBREAKERS)

			assert.is_true(standingsTable.hasdraw)
			assert.are_equal('1 - 0 - 0', display(standingsTable, 'Alpha', 1))
			assert.are_equal('1 - 1 - 0', display(standingsTable, 'Alpha', 2))
			assert.are_equal('0 - 0 - 1', display(standingsTable, 'Bravo', 1))
			assert.are_equal('0 - 1 - 1', display(standingsTable, 'Bravo', 2))
		end)

		it('respects an explicit disable even if there are draws', function()
			local standingsTable = StandingsParser.parse(
				TWO_FINISHED_ROUNDS, makeOpponents(true), BGS, nil, {}, 'swiss', MATCHDIFF_TIEBREAKERS, {match = false})

			assert.is_false(standingsTable.hasdraw)
			assert.are_equal('1 - 0', display(standingsTable, 'Alpha', 1))
			assert.are_equal('1 - 0', display(standingsTable, 'Alpha', 2))
		end)

		it('respects an explicit enable even if there are no draws', function()
			local standingsTable = StandingsParser.parse(
				TWO_FINISHED_ROUNDS, makeOpponents(false), BGS, nil, {}, 'swiss', MATCHDIFF_TIEBREAKERS, {match = true})

			assert.is_true(standingsTable.hasdraw)
			assert.are_equal('1 - 0 - 0', display(standingsTable, 'Alpha', 1))
			assert.are_equal('1 - 0 - 1', display(standingsTable, 'Alpha', 2))
		end)

		it('hides draws when there are none and nothing is configured', function()
			local standingsTable = StandingsParser.parse(
				TWO_FINISHED_ROUNDS, makeOpponents(false), BGS, nil, {}, 'swiss', MATCHDIFF_TIEBREAKERS)

			assert.is_false(standingsTable.hasdraw)
			assert.are_equal('1 - 0', display(standingsTable, 'Alpha', 1))
			assert.are_equal('1 - 1', display(standingsTable, 'Alpha', 2))
		end)
	end)

	describe('disqualifications', function()
		local DQ_TIEBREAKERS = {'full.disqualified', 'full.points', 'full.manual'}

		it('puts a disqualified opponent last with dq statuses and a numeric placement', function()
			local dqOpponent = makeOpponent('Alpha', {{points = 5}, {points = 5}})
			dqOpponent.disqualifiedFromRound = 1
			local opponents = {
				dqOpponent,
				makeOpponent('Bravo', {{points = 3}, {points = 0}}),
				makeOpponent('Charlie', {{points = 1}, {points = 0}}),
			}

			local standingsTable = StandingsParser.parse(
				TWO_FINISHED_ROUNDS, opponents, BGS, nil, {}, 'ffa', DQ_TIEBREAKERS)

			Array.forEach({1, 2}, function(roundIndex)
				local alpha = findEntry(standingsTable.entries, 'Alpha', roundIndex)
				assert.is_true(alpha.extradata.disqualified)
				assert.are_equal(3, alpha.slotindex)
				assert.are_equal(3, alpha.placement)
				assert.are_equal('dq', alpha.currentstatus)
				assert.are_equal('dq', alpha.definitestatus)
			end)

			local alpha2 = findEntry(standingsTable.entries, 'Alpha', 2)
			assert.are_equal(0, alpha2.placementchange)

			local bravo2 = findEntry(standingsTable.entries, 'Bravo', 2)
			assert.is_nil(bravo2.extradata.disqualified)
			assert.are_equal(1, bravo2.placement)
			assert.are_equal('up', bravo2.definitestatus)
		end)

		it('sets the definite status even when the standings are unfinished', function()
			local rounds = {
				{roundNumber = 1, started = true, finished = true},
				{roundNumber = 2, started = true, finished = false},
			}
			local dqOpponent = makeOpponent('Alpha', {{points = 5}, {points = 5}})
			dqOpponent.disqualifiedFromRound = 1
			local opponents = {dqOpponent, makeOpponent('Bravo', {{points = 0}, {points = 0}})}

			local standingsTable = StandingsParser.parse(rounds, opponents, BGS, nil, {}, 'ffa', DQ_TIEBREAKERS)

			assert.is_false(standingsTable.finished)
			local alpha2 = findEntry(standingsTable.entries, 'Alpha', 2)
			assert.are_equal('dq', alpha2.currentstatus)
			assert.are_equal('dq', alpha2.definitestatus)
			assert.are_equal(2, alpha2.placement)
			local bravo2 = findEntry(standingsTable.entries, 'Bravo', 2)
			assert.is_nil(bravo2.definitestatus)
		end)

		it('only disqualifies from the given round onwards', function()
			local dqOpponent = makeOpponent('Alpha', {{points = 5}, {points = 5}})
			dqOpponent.disqualifiedFromRound = 2
			local opponents = {
				dqOpponent,
				makeOpponent('Bravo', {{points = 3}, {points = 0}}),
				makeOpponent('Charlie', {{points = 1}, {points = 0}}),
			}

			local standingsTable = StandingsParser.parse(
				TWO_FINISHED_ROUNDS, opponents, BGS, nil, {}, 'ffa', DQ_TIEBREAKERS)

			local alpha1 = findEntry(standingsTable.entries, 'Alpha', 1)
			assert.is_nil(alpha1.extradata.disqualified)
			assert.are_equal(1, alpha1.placement)
			assert.are_equal('up', alpha1.currentstatus)

			local alpha2 = findEntry(standingsTable.entries, 'Alpha', 2)
			assert.is_true(alpha2.extradata.disqualified)
			assert.are_equal(3, alpha2.slotindex)
			assert.are_equal(3, alpha2.placement)
			assert.are_equal('dq', alpha2.currentstatus)
			assert.are_equal('dq', alpha2.definitestatus)
			-- The placement change stays numeric
			assert.are_equal(-2, alpha2.placementchange)
		end)

		it('orders several disqualified opponents by the remaining tiebreakers', function()
			local alpha = makeOpponent('Alpha', {{points = 2}, {points = 2}})
			alpha.disqualifiedFromRound = 1
			local bravo = makeOpponent('Bravo', {{points = 6}, {points = 6}})
			bravo.disqualifiedFromRound = 1
			local opponents = {
				alpha,
				bravo,
				makeOpponent('Charlie', {{points = 0}, {points = 0}}),
			}

			local standingsTable = StandingsParser.parse(
				TWO_FINISHED_ROUNDS, opponents, BGS, nil, {}, 'ffa', DQ_TIEBREAKERS)

			local charlie2 = findEntry(standingsTable.entries, 'Charlie', 2)
			local bravo2 = findEntry(standingsTable.entries, 'Bravo', 2)
			local alpha2 = findEntry(standingsTable.entries, 'Alpha', 2)
			assert.are_equal(1, charlie2.placement)
			assert.are_equal(2, bravo2.placement)
			assert.are_equal(3, alpha2.placement)
			assert.are_equal('dq', bravo2.definitestatus)
			assert.are_equal('dq', alpha2.definitestatus)
			assert.are_equal('up', charlie2.definitestatus)
		end)
	end)

	it('increments the standingsindex wiki variable per table', function()
		local opponents = {makeOpponent('Alpha', {{points = 3}, {points = 0}})}

		local first = StandingsParser.parse(TWO_FINISHED_ROUNDS, opponents, {}, nil, {}, 'ffa', TIEBREAKERS)
		local second = StandingsParser.parse(TWO_FINISHED_ROUNDS, opponents, {}, nil, {}, 'ffa', TIEBREAKERS)

		assert.are_equal(0, first.standingsindex)
		assert.are_equal(1, second.standingsindex)
	end)
end)
