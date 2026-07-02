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
		}, standingsTable.extradata.tiebreakers)

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

		-- tiebreakerValues are calculated for "full" context tiebreakers
		assert.are_equal(6, bravo2.extradata.tiebreakerValues['full.points'].value)
		assert.are_equal(3, charlie2.extradata.tiebreakerValues['full.points'].value)
		assert.are_equal(1, charlie2.extradata.tiebreakerValues['full.manual'].value)
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
		-- All rounds of an opponent share one cumulative match record;
		-- earlier rounds therefore also show the final totals
		assert.are_same({w = 1, d = 1, l = 1}, alpha1.match)
		assert.are_same({w = 1, d = 1, l = 1}, alpha2.match)
	end)

	it('increments the standingsindex wiki variable per table', function()
		local opponents = {makeOpponent('Alpha', {{points = 3}, {points = 0}})}

		local first = StandingsParser.parse(TWO_FINISHED_ROUNDS, opponents, {}, nil, {}, 'ffa', TIEBREAKERS)
		local second = StandingsParser.parse(TWO_FINISHED_ROUNDS, opponents, {}, nil, {}, 'ffa', TIEBREAKERS)

		assert.are_equal(0, first.standingsindex)
		assert.are_equal(1, second.standingsindex)
	end)
end)
