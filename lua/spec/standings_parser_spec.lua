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

	describe('h2h, h2hlegacy and ml tiebreakers', function()
		local ONE_FINISHED_ROUND = {{roundNumber = 1, started = true, finished = true}}

		---@param spec {id: string, a: string, scoreA: integer, b: string, scoreB: integer, finished: boolean?}
		---@return table
		local function makeMatch(spec)
			local winner = spec.scoreA > spec.scoreB and 1 or spec.scoreA < spec.scoreB and 2 or 0
			return {
				matchId = spec.id,
				finished = spec.finished ~= false,
				winner = winner,
				opponents = {
					{type = 'literal', name = spec.a, score = spec.scoreA, status = 'S',
						placement = winner ~= 2 and 1 or 2},
					{type = 'literal', name = spec.b, score = spec.scoreB, status = 'S',
						placement = winner ~= 1 and 1 or 2},
				},
				games = {},
			}
		end

		---Builds single round opponents, with the matches they played and the scoreboard following from them.
		---@param names string[]
		---@param matchSpecs {id: string, a: string, scoreA: integer, b: string, scoreB: integer,
		---finished: boolean?, points: table<string, number>?}[]
		---@param points table<string, number>? # Overrides the points, for ties that do not follow from the matches
		---@return table[]
		local function makeOpponents(names, matchSpecs, points)
			return Array.map(names, function(name)
				local matches = {}
				local matchPoints = {}
				local matchRecord = {w = 0, d = 0, l = 0}
				local totalPoints = 0
				Array.forEach(matchSpecs, function(spec)
					if spec.a ~= name and spec.b ~= name then
						return
					end
					local match = makeMatch(spec)
					table.insert(matches, match)
					if match.finished then
						local matchOpponent = match.opponents[spec.a == name and 1 or 2]
						local result = match.winner == 0 and 'd' or matchOpponent.placement == 1 and 'w' or 'l'
						matchRecord[result] = matchRecord[result] + 1
					end
					local pointsOfMatch = (spec.points or {})[name]
					if pointsOfMatch then
						matchPoints[spec.id] = pointsOfMatch
						totalPoints = totalPoints + pointsOfMatch
					end
				end)
				return {
					opponent = literal(name),
					rounds = {{
						scoreboard = {points = (points or {})[name] or totalPoints, match = matchRecord},
						specialstatus = '',
						matches = matches,
						matchPoints = matchPoints,
					}},
				}
			end)
		end

		---@param standingsTable table
		---@return string[]
		local function namesBySlot(standingsTable)
			local entries = Array.copy(standingsTable.entries)
			table.sort(entries, function(entryA, entryB) return entryA.slotindex < entryB.slotindex end)
			return Array.map(entries, function(entry) return entry.opponent.name end)
		end

		local function parse(opponents, tiebreakers)
			return StandingsParser.parse(ONE_FINISHED_ROUND, opponents, {}, nil, {}, 'swiss', tiebreakers)
		end

		local function placementOf(standingsTable, name)
			return findEntry(standingsTable.entries, name, 1).placement
		end

		describe('three way tie on points', function()
			-- A, B and C all have 2 points, D and E have 1. Among A, B and C: A beats B and C, B beats C.
			-- Over all matches B has the best match diff (+1), A and C are at 0.
			local MATCHES = {
				{id = 'M1', a = 'A', scoreA = 2, b = 'B', scoreB = 0},
				{id = 'M2', a = 'A', scoreA = 2, b = 'C', scoreB = 0},
				{id = 'M3', a = 'B', scoreA = 2, b = 'C', scoreB = 0},
				{id = 'M4', a = 'B', scoreA = 2, b = 'D', scoreB = 0},
				{id = 'M5', a = 'C', scoreA = 2, b = 'D', scoreB = 0},
				{id = 'M6', a = 'C', scoreA = 2, b = 'E', scoreB = 0},
				{id = 'M7', a = 'D', scoreA = 2, b = 'A', scoreB = 0},
				{id = 'M8', a = 'E', scoreA = 2, b = 'A', scoreB = 0},
			}
			local POINTS = {A = 2, B = 2, C = 2, D = 1, E = 1}
			local NAMES = {'A', 'B', 'C', 'D', 'E'}

			it('orders by the full match diff without h2hlegacy', function()
				local standingsTable = parse(
					makeOpponents(NAMES, MATCHES, POINTS), {'full.points', 'full.matchdiff', 'full.manual'})

				assert.are_equal(1, placementOf(standingsTable, 'B'))
				assert.are_equal(2, placementOf(standingsTable, 'A'))
				assert.are_equal(2, placementOf(standingsTable, 'C'))
			end)

			it('breaks the tie with the matches among the tied opponents for h2hlegacy', function()
				local standingsTable = parse(
					makeOpponents(NAMES, MATCHES, POINTS), {'full.points', 'h2hlegacy.matchdiff', 'full.manual'})

				assert.are_same({'A', 'B', 'C'}, Array.sub(namesBySlot(standingsTable), 1, 3))
				assert.are_equal(1, placementOf(standingsTable, 'A'))
				assert.are_equal(2, placementOf(standingsTable, 'B'))
				assert.are_equal(3, placementOf(standingsTable, 'C'))
				-- D and E have not played each other, so they stay tied
				assert.are_equal(4, placementOf(standingsTable, 'D'))
				assert.are_equal(4, placementOf(standingsTable, 'E'))
			end)

			it('does not add a column or touch the original match data', function()
				local opponents = makeOpponents(NAMES, MATCHES, POINTS)
				local standingsTable = parse(opponents, {'full.points', 'h2hlegacy.matchdiff', 'full.manual'})

				-- h2hlegacy tiebreakers are only listed by id, without a title
				assert.are_same({id = 'h2hlegacy.matchdiff'}, Array.find(
					standingsTable.extradata.additionalStats,
					function(stat) return stat.id == 'h2hlegacy.matchdiff' end
				))
				local alpha = findEntry(standingsTable.entries, 'A', 1)
				assert.is_nil(alpha.extradata.additionalStatsValues['h2hlegacy.matchdiff'])
				assert.are_same({w = 2, d = 0, l = 2}, alpha.match)
				assert.are_equal(4, #alpha.matches)
				assert.are_equal(2, alpha.points)
			end)

			it('uses h2hlegacy for a tie between two opponents', function()
				local opponents = makeOpponents({'A', 'B', 'C'}, {
					{id = 'M1', a = 'A', scoreA = 0, b = 'B', scoreB = 2},
					{id = 'M2', a = 'A', scoreA = 2, b = 'C', scoreB = 0},
					{id = 'M3', a = 'A', scoreA = 2, b = 'C', scoreB = 0},
				}, {A = 1, B = 1, C = 0})
				local standingsTable = parse(opponents, {'full.points', 'h2hlegacy.matchdiff', 'full.manual'})

				-- A has the better match diff overall, but B won the match between the two
				assert.are_same({'B', 'A', 'C'}, namesBySlot(standingsTable))
			end)
		end)

		describe('bigger ties', function()
			-- A, B, C and D are all tied on 3 points.
			-- Among them A has 3 wins and 1 loss (+2), B 2 wins (+2), C and D are at -2 without wins.
			-- A and B never lost to C and D, B beat A once.
			local MATCHES = {
				{id = 'M1', a = 'A', scoreA = 2, b = 'C', scoreB = 0},
				{id = 'M2', a = 'B', scoreA = 2, b = 'D', scoreB = 0},
				{id = 'M3', a = 'B', scoreA = 2, b = 'A', scoreB = 0},
				{id = 'M4', a = 'A', scoreA = 2, b = 'D', scoreB = 0},
				{id = 'M5', a = 'A', scoreA = 2, b = 'C', scoreB = 0},
			}
			local POINTS = {A = 3, B = 3, C = 3, D = 3}
			local NAMES = {'A', 'B', 'C', 'D'}

			it('skips h2hlegacy and continues with the next tiebreaker', function()
				local standingsTable = parse(
					makeOpponents(NAMES, MATCHES, POINTS),
					{'full.points', 'h2hlegacy.matchdiff', 'ml.matchwins', 'full.manual'}
				)

				-- h2hlegacy would have split {A, B} from {C, D} and then let B (who beat A) win
				-- over the whole group A has the most wins
				assert.are_same({'A', 'B'}, Array.sub(namesBySlot(standingsTable), 1, 2))
				assert.are_equal(1, placementOf(standingsTable, 'A'))
				assert.are_equal(2, placementOf(standingsTable, 'B'))
				assert.are_equal(3, placementOf(standingsTable, 'C'))
				assert.are_equal(3, placementOf(standingsTable, 'D'))
			end)

			it('lets ml decide for ties of any size', function()
				local standingsTable = parse(
					makeOpponents(NAMES, MATCHES, POINTS), {'full.points', 'ml.matchdiff', 'full.manual'})

				-- A and B are at +2, C and D at -2
				assert.are_equal(1, placementOf(standingsTable, 'A'))
				assert.are_equal(1, placementOf(standingsTable, 'B'))
				assert.are_equal(3, placementOf(standingsTable, 'C'))
				assert.are_equal(3, placementOf(standingsTable, 'D'))
			end)

			it('continues with the next tiebreaker for the groups ml splits', function()
				local standingsTable = parse(
					makeOpponents(NAMES, MATCHES, POINTS),
					{'full.points', 'ml.matchdiff', 'full.matchwins', 'full.manual'}
				)

				-- ml splits {A, B} from {C, D}, in {A, B} the next tiebreaker puts A (3 wins) above B (2 wins).
				-- Starting over in the group with ml.matchdiff would have put B on top (B beat A).
				assert.are_same({'A', 'B'}, Array.sub(namesBySlot(standingsTable), 1, 2))
				assert.are_equal(1, placementOf(standingsTable, 'A'))
				assert.are_equal(2, placementOf(standingsTable, 'B'))
				assert.are_equal(3, placementOf(standingsTable, 'C'))
				assert.are_equal(3, placementOf(standingsTable, 'D'))
			end)

			it('scopes a following ml tiebreaker to the group it splits', function()
				local standingsTable = parse(
					makeOpponents(NAMES, MATCHES, POINTS),
					{'full.points', 'ml.matchdiff', 'ml.matchwins', 'full.manual'}
				)

				-- Among A and B only the match B won counts
				assert.are_same({'B', 'A'}, Array.sub(namesBySlot(standingsTable), 1, 2))
				assert.are_equal(1, placementOf(standingsTable, 'B'))
				assert.are_equal(2, placementOf(standingsTable, 'A'))
				assert.are_equal(3, placementOf(standingsTable, 'C'))
				assert.are_equal(3, placementOf(standingsTable, 'D'))
			end)
		end)

		describe('h2h', function()
			-- Same ties as above: A, B, C and D are all tied on 3 points.
			-- Pairwise B beat A, A beat C and D, B beat D, while B and C and C and D never played.
			local MATCHES = {
				{id = 'M1', a = 'A', scoreA = 2, b = 'C', scoreB = 0},
				{id = 'M2', a = 'B', scoreA = 2, b = 'D', scoreB = 0},
				{id = 'M3', a = 'B', scoreA = 2, b = 'A', scoreB = 0},
				{id = 'M4', a = 'A', scoreA = 2, b = 'D', scoreB = 0},
				{id = 'M5', a = 'A', scoreA = 2, b = 'C', scoreB = 0},
			}
			local POINTS = {A = 3, B = 3, C = 3, D = 3}
			local NAMES = {'A', 'B', 'C', 'D'}

			it('applies to ties of more than three opponents', function()
				local standingsTable = parse(
					makeOpponents(NAMES, MATCHES, POINTS), {'full.points', 'h2h.matchdiff', 'full.manual'})

				-- B is at least as good as everyone else, C and D are at most as good as everyone else
				assert.are_same({'B', 'A', 'C', 'D'}, namesBySlot(standingsTable))
				assert.are_equal(1, placementOf(standingsTable, 'B'))
				assert.are_equal(2, placementOf(standingsTable, 'A'))
				assert.are_equal(3, placementOf(standingsTable, 'C'))
				assert.are_equal(3, placementOf(standingsTable, 'D'))
			end)

			it('is not applied by h2hlegacy for ties of more than three opponents', function()
				local standingsTable = parse(
					makeOpponents(NAMES, MATCHES, POINTS), {'full.points', 'h2hlegacy.matchdiff', 'full.manual'})

				Array.forEach(NAMES, function(name)
					assert.are_equal(1, placementOf(standingsTable, name))
				end)
			end)

			it('continues with the next tiebreaker for the groups it splits', function()
				local standingsTable = parse(
					makeOpponents(NAMES, MATCHES, POINTS),
					{'full.points', 'h2h.matchdiff', 'ml.matchwins', 'full.manual'}
				)

				-- C and D are still tied after h2h. Both have no wins among the tied opponents.
				assert.are_same({'B', 'A', 'C', 'D'}, namesBySlot(standingsTable))
				assert.are_equal(3, placementOf(standingsTable, 'C'))
				assert.are_equal(3, placementOf(standingsTable, 'D'))
			end)

			it('differs from h2hlegacy for ties of three opponents', function()
				-- A, B and C are tied. Among them A and B each beat C, and A and B drew.
				-- For h2h A and B are level, so only C is split off. The mini league puts B above A,
				-- as B beat C twice.
				local opponents = makeOpponents({'A', 'B', 'C'}, {
					{id = 'M1', a = 'A', scoreA = 2, b = 'C', scoreB = 0},
					{id = 'M2', a = 'B', scoreA = 2, b = 'C', scoreB = 0},
					{id = 'M3', a = 'B', scoreA = 2, b = 'C', scoreB = 0},
					{id = 'M4', a = 'A', scoreA = 1, b = 'B', scoreB = 1},
				}, {A = 1, B = 1, C = 1})

				local h2hTable = parse(opponents, {'full.points', 'h2h.matchdiff', 'full.manual'})
				assert.are_equal(1, placementOf(h2hTable, 'A'))
				assert.are_equal(1, placementOf(h2hTable, 'B'))
				assert.are_equal(3, placementOf(h2hTable, 'C'))

				local legacyTable = parse(opponents, {'full.points', 'h2hlegacy.matchdiff', 'full.manual'})
				assert.are_equal(1, placementOf(legacyTable, 'B'))
				assert.are_equal(2, placementOf(legacyTable, 'A'))
				assert.are_equal(3, placementOf(legacyTable, 'C'))
			end)

			it('is only listed by id, without a title or values', function()
				local standingsTable = parse(
					makeOpponents(NAMES, MATCHES, POINTS), {'full.points', 'h2h.matchdiff', 'full.manual'})

				assert.are_same({id = 'h2h.matchdiff'}, Array.find(standingsTable.extradata.additionalStats, function(stat)
					return stat.id == 'h2h.matchdiff'
				end))
				assert.is_nil(findEntry(standingsTable.entries, 'A', 1).extradata.additionalStatsValues['h2h.matchdiff'])
			end)
		end)

		describe('successive h2h tiebreakers', function()
			-- A, B, C and D are tied on 3 points, and the matches among them follow a strict order A > B > C > D
			local MATCHES = {
				{id = 'M1', a = 'A', scoreA = 2, b = 'B', scoreB = 0},
				{id = 'M2', a = 'A', scoreA = 2, b = 'C', scoreB = 0},
				{id = 'M3', a = 'A', scoreA = 2, b = 'D', scoreB = 0},
				{id = 'M4', a = 'B', scoreA = 2, b = 'C', scoreB = 0},
				{id = 'M5', a = 'B', scoreA = 2, b = 'D', scoreB = 0},
				{id = 'M6', a = 'C', scoreA = 2, b = 'D', scoreB = 0},
			}
			local POINTS = {A = 3, B = 3, C = 3, D = 3}
			local NAMES = {'A', 'B', 'C', 'D'}

			it('only splits the top and the bottom in one pass', function()
				local standingsTable = parse(
					makeOpponents(NAMES, MATCHES, POINTS), {'full.points', 'h2h.matchdiff', 'full.manual'})

				assert.are_same({'A', 'B', 'C', 'D'}, namesBySlot(standingsTable))
				assert.are_equal(1, placementOf(standingsTable, 'A'))
				assert.are_equal(2, placementOf(standingsTable, 'B'))
				assert.are_equal(2, placementOf(standingsTable, 'C'))
				assert.are_equal(4, placementOf(standingsTable, 'D'))
			end)

			it('splits the middle with the same tiebreaker listed again', function()
				local standingsTable = parse(
					makeOpponents(NAMES, MATCHES, POINTS),
					{'full.points', 'h2h.matchdiff', 'h2h.matchdiff', 'full.manual'}
				)

				assert.are_same({'A', 'B', 'C', 'D'}, namesBySlot(standingsTable))
				assert.are_equal(1, placementOf(standingsTable, 'A'))
				assert.are_equal(2, placementOf(standingsTable, 'B'))
				assert.are_equal(3, placementOf(standingsTable, 'C'))
				assert.are_equal(4, placementOf(standingsTable, 'D'))
			end)

			it('continues with a different h2h tiebreaker in the middle', function()
				-- B and C won a match each, but C won more games among them
				local opponents = makeOpponents(NAMES, {
					{id = 'M1', a = 'A', scoreA = 2, b = 'B', scoreB = 0},
					{id = 'M2', a = 'A', scoreA = 2, b = 'C', scoreB = 0},
					{id = 'M3', a = 'A', scoreA = 2, b = 'D', scoreB = 0},
					{id = 'M4', a = 'B', scoreA = 2, b = 'C', scoreB = 1},
					{id = 'M5', a = 'B', scoreA = 2, b = 'D', scoreB = 0},
					{id = 'M6', a = 'C', scoreA = 2, b = 'D', scoreB = 0},
					{id = 'M7', a = 'C', scoreA = 2, b = 'B', scoreB = 0},
				}, POINTS)

				local standingsTable = parse(
					opponents, {'full.points', 'h2h.matchdiff', 'h2h.gamediff', 'full.manual'})

				assert.are_same({'A', 'C', 'B', 'D'}, namesBySlot(standingsTable))
			end)
		end)

		describe('game based tiebreakers', function()
			-- A, B and C are tied on 1 point, D has none.
			-- Among A, B and C the game diffs are A -1, B +1, C 0, over all matches A +1, B -1, C +1.
			local MATCHES = {
				{id = 'M1', a = 'A', scoreA = 2, b = 'B', scoreB = 1},
				{id = 'M2', a = 'B', scoreA = 2, b = 'C', scoreB = 0},
				{id = 'M3', a = 'C', scoreA = 2, b = 'A', scoreB = 0},
				{id = 'M4', a = 'A', scoreA = 2, b = 'D', scoreB = 0},
				{id = 'M5', a = 'D', scoreA = 2, b = 'B', scoreB = 0},
				{id = 'M6', a = 'C', scoreA = 2, b = 'D', scoreB = 1},
			}
			local POINTS = {A = 1, B = 1, C = 1, D = 0}
			local NAMES = {'A', 'B', 'C', 'D'}

			it('only counts games among the tied opponents for h2hlegacy, even if the full value is known', function()
				local standingsTable = parse(
					makeOpponents(NAMES, MATCHES, POINTS),
					{'full.points', 'h2hlegacy.gamediff', 'full.gamediff', 'full.manual'}
				)

				assert.are_same({'B', 'C', 'A', 'D'}, namesBySlot(standingsTable))
				-- the full value is still shown for every opponent
				assert.are_equal(1, findEntry(standingsTable.entries, 'A', 1).extradata
					.additionalStatsValues['full.gamediff'].value)
				assert.are_equal(-1, findEntry(standingsTable.entries, 'B', 1).extradata
					.additionalStatsValues['full.gamediff'].value)
			end)

			it('orders by the full value without h2hlegacy', function()
				local standingsTable = parse(
					makeOpponents(NAMES, MATCHES, POINTS), {'full.points', 'full.gamediff', 'full.manual'})

				assert.are_equal(3, placementOf(standingsTable, 'B'))
				assert.are_equal(1, placementOf(standingsTable, 'A'))
				assert.are_equal(1, placementOf(standingsTable, 'C'))
			end)
		end)

		describe('points', function()
			it('uses the points of the matches among the tied opponents for h2hlegacy', function()
				-- A and B are tied on 5 points. In the matches between them A got 3 and B got 4,
				-- the matches against C do not count.
				local opponents = makeOpponents({'A', 'B', 'C'}, {
					{id = 'M1', a = 'A', scoreA = 2, b = 'B', scoreB = 0, points = {A = 3, B = 0}},
					{id = 'M2', a = 'A', scoreA = 0, b = 'B', scoreB = 2, points = {A = 0, B = 4}},
					{id = 'M3', a = 'A', scoreA = 2, b = 'C', scoreB = 0, points = {A = 2, C = 0}},
					{id = 'M4', a = 'B', scoreA = 2, b = 'C', scoreB = 0, points = {B = 1, C = 0}},
				})
				local standingsTable = parse(opponents, {'full.points', 'h2hlegacy.points', 'full.manual'})

				assert.are_equal(5, findEntry(standingsTable.entries, 'A', 1).points)
				assert.are_equal(5, findEntry(standingsTable.entries, 'B', 1).points)
				assert.are_same({'B', 'A', 'C'}, namesBySlot(standingsTable))
			end)
		end)
	end)

	describe('manual definite statuses', function()
		local THREE_ROUNDS_TWO_FINISHED = {
			{roundNumber = 1, started = true, finished = true},
			{roundNumber = 2, started = true, finished = true},
			{roundNumber = 3, started = true, finished = false},
		}

		---@param definiteStatuses table<integer, string>?
		---@return table[]
		local function makeOpponents(definiteStatuses)
			local alpha = makeOpponent('Alpha', {{points = 0}, {points = 0}, {points = 0}})
			alpha.definiteStatuses = definiteStatuses
			return {
				alpha,
				makeOpponent('Bravo', {{points = 3}, {points = 3}, {points = 3}}),
				makeOpponent('Charlie', {{points = 1}, {points = 1}, {points = 1}}),
			}
		end

		it('applies only from the given round onwards on unfinished standings', function()
			local standingsTable = StandingsParser.parse(
				THREE_ROUNDS_TWO_FINISHED, makeOpponents({[2] = 'down'}), BGS, nil, {}, 'ffa', TIEBREAKERS)

			local alpha1 = findEntry(standingsTable.entries, 'Alpha', 1)
			assert.are_equal('down', alpha1.currentstatus)
			assert.is_nil(alpha1.definitestatus)

			Array.forEach({2, 3}, function(roundIndex)
				local alpha = findEntry(standingsTable.entries, 'Alpha', roundIndex)
				assert.are_equal('down', alpha.definitestatus)
			end)
		end)

		it('does not apply to rounds before the first given round', function()
			local standingsTable = StandingsParser.parse(
				THREE_ROUNDS_TWO_FINISHED, makeOpponents({[3] = 'up'}), BGS, nil, {}, 'ffa', TIEBREAKERS)

			Array.forEach({1, 2}, function(roundIndex)
				local alpha = findEntry(standingsTable.entries, 'Alpha', roundIndex)
				assert.is_nil(alpha.definitestatus)
				assert.are_equal('down', alpha.currentstatus)
			end)
			assert.are_equal('up', findEntry(standingsTable.entries, 'Alpha', 3).definitestatus)
		end)

		it('uses the status with the highest round that has been reached', function()
			local standingsTable = StandingsParser.parse(
				THREE_ROUNDS_TWO_FINISHED, makeOpponents({[1] = 'stayup', [3] = 'up'}),
				BGS, nil, {}, 'ffa', TIEBREAKERS)

			assert.are_equal('stayup', findEntry(standingsTable.entries, 'Alpha', 1).definitestatus)
			assert.are_equal('stayup', findEntry(standingsTable.entries, 'Alpha', 2).definitestatus)
			assert.are_equal('up', findEntry(standingsTable.entries, 'Alpha', 3).definitestatus)
		end)

		it('sets the current status as well', function()
			local standingsTable = StandingsParser.parse(
				THREE_ROUNDS_TWO_FINISHED, makeOpponents({[2] = 'up'}), BGS, nil, {}, 'ffa', TIEBREAKERS)

			local alpha2 = findEntry(standingsTable.entries, 'Alpha', 2)
			assert.are_equal(3, alpha2.placement)
			assert.are_equal('up', alpha2.currentstatus)
			assert.are_equal('up', alpha2.definitestatus)
		end)

		it('overrides the definite status derived from the bgs on finished standings', function()
			local standingsTable = StandingsParser.parse(
				TWO_FINISHED_ROUNDS, makeOpponents({[1] = 'stay'}), BGS, nil, {}, 'ffa', TIEBREAKERS)

			local alpha2 = findEntry(standingsTable.entries, 'Alpha', 2)
			assert.are_equal('stay', alpha2.currentstatus)
			assert.are_equal('stay', alpha2.definitestatus)
		end)

		it('is overridden by a disqualification', function()
			local opponents = makeOpponents({[1] = 'up'})
			opponents[1].disqualifiedFromRound = 2

			local standingsTable = StandingsParser.parse(
				TWO_FINISHED_ROUNDS, opponents, BGS, nil, {}, 'ffa', {'full.disqualified', 'full.points', 'full.manual'})

			local alpha1 = findEntry(standingsTable.entries, 'Alpha', 1)
			assert.are_equal('up', alpha1.currentstatus)
			assert.are_equal('up', alpha1.definitestatus)
			local alpha2 = findEntry(standingsTable.entries, 'Alpha', 2)
			assert.are_equal('dq', alpha2.currentstatus)
			assert.are_equal('dq', alpha2.definitestatus)
		end)

		it('leaves opponents without manual statuses unchanged', function()
			local standingsTable = StandingsParser.parse(
				THREE_ROUNDS_TWO_FINISHED, makeOpponents({[1] = 'up'}), BGS, nil, {}, 'ffa', TIEBREAKERS)

			local bravo2 = findEntry(standingsTable.entries, 'Bravo', 2)
			assert.are_equal('up', bravo2.currentstatus)
			assert.is_nil(bravo2.definitestatus)
			local charlie2 = findEntry(standingsTable.entries, 'Charlie', 2)
			assert.are_equal('stay', charlie2.currentstatus)
			assert.is_nil(charlie2.definitestatus)
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
