--- Triple Comment to Enable our LLS Plugin
describe('Standings Table opponent merge', function()
	local StandingsTable = require('Module:Standings/Table')

	local function literal(name)
		return {type = 'literal', name = name}
	end

	---Manual opponents as produced by StandingsParseWiki.parseWikiOpponent
	local function manualOpponent(name, pointsPerRound)
		local rounds = {}
		for _, points in ipairs(pointsPerRound) do
			table.insert(rounds, {scoreboard = {points = points}, specialstatus = ''})
		end
		return {opponent = literal(name), rounds = rounds}
	end

	---Imported opponents as produced by StandingsParseLpdb.importFromMatches
	local function importedOpponent(name, roundsSpec)
		local rounds = {}
		for _, spec in ipairs(roundsSpec) do
			table.insert(rounds, {
				scoreboard = {
					points = spec.points,
					match = spec.match or {w = 0, d = 0, l = 0},
				},
				specialstatus = spec.specialstatus or '',
				matches = spec.matches or {},
				matchId = spec.matchId,
			})
		end
		return {opponent = literal(name), rounds = rounds}
	end

	it('manual data takes priority over imported data', function()
		local fakeMatch = {matchId = 'M1'}
		local merged = StandingsTable.mergeOpponentsData(
			{manualOpponent('Alpha', {10})},
			{importedOpponent('Alpha', {
				{points = 3, match = {w = 1, d = 0, l = 0}, matches = {fakeMatch}, matchId = 'M1'},
			})},
			true
		)

		assert.are_equal(1, #merged)
		local round = merged[1].rounds[1]
		assert.are_equal(10, round.scoreboard.points)
		-- imported-only data survives the merge
		assert.are_same({w = 1, d = 0, l = 0}, round.scoreboard.match)
		assert.are_equal('M1', round.matchId)
		assert.are_equal(1, #round.matches)
		assert.are_equal('M1', round.matches[1].matchId)
	end)

	it('appends imported-only opponents when import of opponents is enabled', function()
		local merged = StandingsTable.mergeOpponentsData(
			{manualOpponent('Alpha', {3})},
			{importedOpponent('Bravo', {{points = 0}})},
			true
		)

		assert.are_equal(2, #merged)
		assert.are_equal('Alpha', merged[1].opponent.name)
		assert.are_equal('Bravo', merged[2].opponent.name)
	end)

	it('drops imported-only opponents when import of opponents is disabled', function()
		local merged = StandingsTable.mergeOpponentsData(
			{manualOpponent('Alpha', {3})},
			{importedOpponent('Bravo', {{points = 0}})},
			false
		)

		assert.are_equal(1, #merged)
		assert.are_equal('Alpha', merged[1].opponent.name)
	end)

	it('keeps manual-only opponents untouched', function()
		local merged = StandingsTable.mergeOpponentsData(
			{manualOpponent('Alpha', {3}), manualOpponent('Charlie', {5})},
			{importedOpponent('Alpha', {{points = 3}})},
			true
		)

		assert.are_equal(2, #merged)
		assert.are_equal('Charlie', merged[2].opponent.name)
		assert.are_equal(5, merged[2].rounds[1].scoreboard.points)
	end)
end)
