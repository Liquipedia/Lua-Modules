--- Triple Comment to Enable our LLS Plugin
describe('Standings Storage', function()
	local StandingsStorage = require('Module:Standings/Storage')
	local InfoboxLeague = require('Module:Infobox/League/Custom')

	it('storage of table', function()
		local stubLpdb = stub(mw.ext.LiquipediaDB, "lpdb", {})
		local stubLpdbTournament = stub(mw.ext.LiquipediaDB, "lpdb_tournament")
		local stubLpdbStandingsTable = stub(mw.ext.LiquipediaDB, "lpdb_standingstable")

		local tournamentDatas = require('test_assets.tournaments')
		local tournamentData = tournamentDatas.dummy
		InfoboxLeague.run(tournamentData)

		StandingsStorage.run{
			standingsindex = 0,
			title = '',
			type = 'swiss',
			entries = {},
		}

		assert.stub(stubLpdbStandingsTable).was.called_with('standingsTable_0', {
			parent = 'FakePage',
			section = '',
			standingsindex = 0,
			title = '',
			tournament = 'Test Tournament',
			type = 'swiss',
		})

		stubLpdb:revert()
		stubLpdbTournament:revert()
		stubLpdbStandingsTable:revert()
	end)

	it('storage full', function()
		local standingsData = require('test_assets.standings')
		local stubLpdb = stub(mw.ext.LiquipediaDB, "lpdb", {})
		local stubLpdbTournament = stub(mw.ext.LiquipediaDB, "lpdb_tournament")
		local stubLpdbStandingsTable = stub(mw.ext.LiquipediaDB, "lpdb_standingstable")
		local stubLpdbStandingsEntry = stub(mw.ext.LiquipediaDB, "lpdb_standingsentry")

		local tournamentDatas = require('test_assets.tournaments')
		local tournamentData = tournamentDatas.dummy
		InfoboxLeague.run(tournamentData)

		StandingsStorage.run(standingsData)

		assert.stub(stubLpdbStandingsTable).was.called_with('standingsTable_0', {
			parent = 'FakePage',
			section = '',
			standingsindex = 0,
			title = '',
			tournament = 'Test Tournament',
			type = 'league',
		})

		assert.stub(stubLpdbStandingsEntry).was.called(70)

		assert.stub(stubLpdbStandingsEntry).was.called_with('standing_0_7_10', {
			currentstatus = 'stay',
			definitestatus = 'stay',
			opponentname = 'tt9 esports 2022',
			opponenttemplate = 'tt9 esports 2022',
			opponenttype = 'team',
			parent = 'FakePage',
			placement = 10,
			placementchange = 0,
			roundindex = 7,
			slotindex = 10,
			standingsindex = 0,
		})

		stubLpdb:revert()
		stubLpdbTournament:revert()
		stubLpdbStandingsTable:revert()
		stubLpdbStandingsEntry:revert()
	end)
end)
