--- Triple Comment to Enable our LLS Plugin
describe('Standings model round trip', function()
	local StandingsParser = require('Module:Standings/Parser')
	local StandingsStorage = require('Module:Standings/Storage')
	local Standings = require('Module:Standings')
	local Array = require('Module:Array')

	local function literal(name)
		return {type = 'literal', name = name}
	end

	local function makeOpponent(name, pointsPerRound)
		return {
			opponent = literal(name),
			rounds = Array.map(pointsPerRound, function(points)
				return {scoreboard = {points = points}, specialstatus = ''}
			end),
		}
	end

	---Parses a standings table and stores it to page variables (as Standings/Table does),
	---then reads the model back through Standings.getStandingsTable
	local function buildAndFetchStandings()
		local rounds = {
			{roundNumber = 1, started = true, finished = true, title = 'Day 1'},
			{roundNumber = 2, started = true, finished = true, title = 'Day 2'},
		}
		local opponents = {
			makeOpponent('Alpha', {3, 0}),
			makeOpponent('Bravo', {1, 4}),
			makeOpponent('Charlie', {0, 1}),
		}
		local standingsTable = StandingsParser.parse(
			rounds, opponents, {[1] = 'up', [3] = 'down'}, 'League Standings', {}, 'ffa', {'full.points', 'full.manual'})
		StandingsStorage.run(standingsTable, {saveVars = true})

		return Standings.getStandingsTable('FakePage', 0)
	end

	before_each(function()
		stub(mw.ext.LiquipediaDB, 'lpdb', {})
		stub(mw.ext.LiquipediaDB, 'lpdb_standingstable')
		stub(mw.ext.LiquipediaDB, 'lpdb_standingsentry')
	end)

	after_each(function()
		---@diagnostic disable-next-line: undefined-field
		mw.ext.LiquipediaDB.lpdb:revert()
		---@diagnostic disable-next-line: undefined-field
		mw.ext.LiquipediaDB.lpdb_standingstable:revert()
		---@diagnostic disable-next-line: undefined-field
		mw.ext.LiquipediaDB.lpdb_standingsentry:revert()
	end)

	it('reads the stored standings back from page variables', function()
		local standings = buildAndFetchStandings()

		assert.is_not_nil(standings)
		---@cast standings -nil
		assert.are_equal('ffa', standings.type)
		assert.are_equal('League Standings', standings.title)
		assert.are_equal(0, standings.standingsIndex)
		assert.are_equal('full.points', standings.tiebreakers[1].id)
		assert.are_equal('Points', standings.tiebreakers[1].title)

		assert.are_equal(2, #standings.rounds)
		assert.are_equal('Day 1', standings.rounds[1].title)
		assert.is_true(standings.rounds[1].finished)
		assert.are_equal(3, #standings.rounds[1].opponents)
		assert.are_equal(3, #standings.rounds[2].opponents)
	end)

	it('exposes entries ordered by position with model fields mapped', function()
		local standings = buildAndFetchStandings()
		---@cast standings -nil

		-- Round 2 totals: Bravo 5, Alpha 3, Charlie 1
		local round2 = standings.rounds[2].opponents
		assert.are_same(
			{'Bravo', 'Alpha', 'Charlie'},
			Array.map(round2, function(entry) return entry.opponent.name end)
		)

		local bravo = round2[1]
		assert.are_equal(5, bravo.points)
		assert.are_equal(1, bravo.position)
		assert.are_equal(1, tonumber(bravo.placement))
		assert.are_equal(1, bravo.positionChangeFromPreviousRound)
		assert.are_equal(4, bravo.pointsChangeFromPreviousRound)
		assert.are_equal('up', bravo.positionStatus)
		assert.are_equal('up', bravo.definitiveStatus)
		assert.are_equal('', bravo.specialStatus)
		assert.are_equal(5, bravo.tiebreakerValues['full.points'].value)

		local charlie = round2[3]
		assert.are_equal(1, charlie.points)
		assert.are_equal(3, charlie.position)
		assert.are_equal('down', charlie.positionStatus)
		assert.are_equal(0, charlie.positionChangeFromPreviousRound)
	end)

	it('renders the ffa standings widget from the model', function()
		buildAndFetchStandings() -- stores the standings into page variables
		local StandingsDisplay = require('Module:Widget/Standings')
		local html = tostring(StandingsDisplay{pageName = 'FakePage', standingsIndex = 0})

		assert.is_truthy(html:find('standings-ffa', 1, true))
		assert.is_truthy(html:find('League Standings', 1, true))
		assert.is_truthy(html:find('Day 1', 1, true))
		assert.is_truthy(html:find('Day 2', 1, true))

		-- Round 2 rows in standings order: Bravo, Alpha, Charlie
		local bravoPos = html:find('Bravo', 1, true)
		local alphaPos = html:find('Alpha', bravoPos, true)
		local charliePos = html:find('Charlie', alphaPos, true)
		assert.is_truthy(bravoPos)
		assert.is_truthy(alphaPos)
		assert.is_truthy(charliePos)

		GoldenTest('standings_ffa', html)
	end)

	it('direct-path render matches var-path render', function()
		local StandingsDisplay = require('Module:Widget/Standings')

		local rounds = {
			{roundNumber = 1, started = true, finished = true, title = 'Day 1'},
			{roundNumber = 2, started = true, finished = true, title = 'Day 2'},
		}
		local opponents = {
			makeOpponent('Alpha', {3, 0}),
			makeOpponent('Bravo', {1, 4}),
			makeOpponent('Charlie', {0, 1}),
		}
		local standingsTable = StandingsParser.parse(
			rounds, opponents, {[1] = 'up', [3] = 'down'}, 'Dir Standings', {}, 'ffa', {'full.points'})

		-- Direct path: use the returned record/entries from StandingsStorage.run
		local stored = StandingsStorage.run(standingsTable, {saveVars = true})
		local directModel = Standings.standingsFromRecord(stored.record, stored.entries)
		local htmlDirect = tostring(StandingsDisplay{standings = directModel})

		-- Var path: read back from page variables (the same wiki-var write)
		local htmlVar = tostring(StandingsDisplay{pageName = 'FakePage', standingsIndex = standingsTable.standingsindex})

		assert.are_equal(htmlDirect, htmlVar)
	end)

	it('renders the swiss standings widget from the model', function()
		local SwissStandings = require('Module:Widget/Standings/Swiss')

		local rounds = {
			{roundNumber = 1, started = true, finished = true, title = 'Round 1'},
			{roundNumber = 2, started = true, finished = true, title = 'Round 2'},
		}
		local opponents = {
			{
				opponent = literal('Alpha'),
				rounds = {
					{scoreboard = {points = 1, match = {w = 1, d = 0, l = 0}}, specialstatus = ''},
					{scoreboard = {points = 1, match = {w = 1, d = 0, l = 0}}, specialstatus = ''},
				},
			},
			{
				opponent = literal('Bravo'),
				rounds = {
					{scoreboard = {points = 0, match = {w = 0, d = 0, l = 1}}, specialstatus = ''},
					{scoreboard = {points = 0, match = {w = 0, d = 0, l = 1}}, specialstatus = ''},
				},
			},
		}
		local standingsTable = StandingsParser.parse(
			rounds, opponents, {}, 'Swiss Stage', {}, 'swiss', {'full.matchdiff', 'full.manual'})
		StandingsStorage.run(standingsTable, {saveVars = true})

		local standings = Standings.getStandingsTable('FakePage', 0)
		assert.is_not_nil(standings)

		local html = tostring(SwissStandings{standings = standings})
		assert.is_truthy(html:find('standings-swiss', 1, true))
		assert.is_truthy(html:find('Swiss Stage', 1, true))
		local alphaPos = html:find('Alpha', 1, true)
		local bravoPos = html:find('Bravo', alphaPos, true)
		assert.is_truthy(alphaPos)
		assert.is_truthy(bravoPos)

		GoldenTest('standings_swiss', html)
	end)
end)
