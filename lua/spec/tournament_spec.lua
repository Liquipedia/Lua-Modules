describe('tournament', function()
	local InfoboxLeague = require('Module:Infobox/League/Custom')
	local Tournament = require('Module:Tournament')
	local tournamentData = require('test_assets.tournaments').dummy

	local EXPECTED_PARTIAL = {
		displayName = 'Test Tourney',
		tickerName = 'Test Tourney',
		shortName = 'Test',
		fullName = 'Test Tournament',
		pageName = 'FakePage',
		liquipediaTier = '1',
		liquipediaTierType = 'Qualifier',
		icon = 'test.png',
		iconDark = 'test dark.png',
		series = 'Test Series',
		game = 'commons',
		publisherTier = nil,
		type = 'Offline',
	}

	before_each(function()
		local dataSaved = {}

		stub(mw.ext.LiquipediaDB, "lpdb", function(tbl, options)
			if tbl == 'tournament' then
				return dataSaved
			end
			return {}
		end)
		stub(mw.ext.LiquipediaDB, "lpdb_tournament", function(objName, data)
			data.pagename = 'FakePage'
			table.insert(dataSaved, data)
			return objName
		end)
		InfoboxLeague.run(tournamentData)
	end)

	it('loads tournament data from page variables', function()
		assert.are_same(
			EXPECTED_PARTIAL,
			Tournament.partialTournamentFromContext()
		)
	end)

	it('loads tournament data from LPDB', function()
		local tournament = Tournament.getTournament('FakePage')
		---@cast tournament -nil
		for expectedKey, expectedVal in pairs(EXPECTED_PARTIAL) do
			assert.are_equal(expectedVal, tournament[expectedKey])
		end
	end)
end)
