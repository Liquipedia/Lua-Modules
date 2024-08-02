--- Triple Comment to Enable our LLS Plugin
describe('prize pool', function()
	local PrizePool = require('Module:PrizePool')
	local InfoboxLeague = require('Module:Infobox/League/Custom')
	local Table = require('Module:Table')
	local Variables = require('Module:Variables')
	local tournamentData = require('test_assets.tournaments').dummy

	local LpdbPlacementStub

	before_each(function()
		stub(mw.ext.LiquipediaDB, "lpdb", {})
		stub(mw.ext.LiquipediaDB, "lpdb_tournament")
		LpdbPlacementStub = stub(mw.ext.LiquipediaDB, "lpdb_placement")
		InfoboxLeague.run(tournamentData)
	end)

	after_each(function ()
		LpdbPlacementStub:revert()
		---@diagnostic disable-next-line: undefined-field
		mw.ext.LiquipediaDB.lpdb:revert()
		mw.ext.LiquipediaDB.lpdb_tournament:revert()
	end)

	local prizePoolArgs = {
		type = {type = 'solo'},
		currencyroundprecision = 3,
		lpdb_prefix = 'abc',
		fillPlaceRange = true,
		localcurrency1 = 'EUR',
		localcurrency2 = 'sek',
		points1 = 'points',
		points1link = 'A Page',
		qualifies1 = 'A Tournament',
		qualifies1name = 'A Display',
		freetext = 'A title',
		import = false,
		[1] = {localprize = '1,000', [1] = {'Rathoz', flag='se'}},
	}

	it('parameters are correctly parsed', function()
		local ppt = PrizePool(prizePoolArgs):create()

		assert.are_same(
			{
				{id = 'BASE_CURRENCY1', type = 'BASE_CURRENCY', index = 1, data = {roundPrecision = 3}},
				{
					id = 'LOCAL_CURRENCY1',
					type = 'LOCAL_CURRENCY',
					index = 1,
					data =
					{
						rate = 0.97097276906869001145,
						roundPrecision = 3,
						currency = 'EUR',
					}
				},
				{
					id = 'LOCAL_CURRENCY2',
					type = 'LOCAL_CURRENCY',
					index = 2,
					data =
					{
						rate = 0.97097276906869001145,
						roundPrecision = 3,
						currency = 'SEK',
					}
				},
				{id = 'QUALIFIES1', type = 'QUALIFIES', index = 1, data = {title = 'A Display', link = 'A_Tournament'}},
				{id = 'POINTS1', type = 'POINTS', index = 1, data = {title = 'Points', link = 'A Page'}},
				{id = 'FREETEXT1', type = 'FREETEXT', index = 1, data = {title = 'A title'}},
			},
			ppt.prizes
		)

		assert.are_same(
			{
				abbreviateTbd = true,
				autoExchange = true,
				currencyRatePerOpponent = false,
				currencyRoundPrecision = 3,
				cutafter = 4,
				exchangeInfo = true,
				fillPlaceRange = true,
				lpdbPrefix = 'abc',
				prizeSummary = true,
				resolveRedirect = false,
				showBaseCurrency = true,
				storeLpdb = true,
				syncPlayers = true,
			},
			ppt.options
		)
	end)

	describe('prize pool is correct', function()
		it('display', function()
			GoldenTest('prize_pool', tostring(PrizePool(prizePoolArgs):create():build()))
		end)

		it('lpdb storage', function()
			PrizePool(prizePoolArgs):create():build()
			assert.stub(LpdbPlacementStub).was.called_with('ranking_abc1_Rathoz', {
				date = '2022-10-15',
				extradata = '{"prizepoints":""}',
				game = 'commons',
				icon = 'test.png',
				icondark = 'test dark.png',
				individualprizemoney = 970.97276906869001323,
				lastvsdata = '[]',
				liquipediatier = '1',
				liquipediatiertype = 'Qualifier',
				opponentname = 'Rathoz',
				opponentplayers = '{"p1":"Rathoz","p1dn":"Rathoz","p1flag":"Sweden"}',
				opponenttype = 'solo',
				parent = 'FakePage',
				participant = 'Rathoz', -- Legacy
				participantflag = 'Sweden', -- Legacy
				participantlink = 'Rathoz', -- Legacy
				placement = 1,
				players = '{"p1":"Rathoz","p1dn":"Rathoz","p1flag":"Sweden"}', -- Legacy
				prizemoney = 970.97276906869001323,
				prizepoolindex = 1,
				series = 'Test Series',
				shortname = 'Test Tourney',
				startdate = '2022-10-13',
				tournament = 'Test Tournament',
				type = 'Offline',
			})
		end)
	end)

	describe('enabling/disabling lpdb storage', function()
		it('normal behavior', function()
			PrizePool(prizePoolArgs):create():build()
			assert.stub(LpdbPlacementStub).called(1)
		end)

		it('disabled', function()
			PrizePool(Table.merge(prizePoolArgs, {storelpdb = false})):create():build()
			assert.stub(LpdbPlacementStub).called(0)
		end)

		it('wiki-var enabled', function()
			Variables.varDefine('disable_LPDB_storage', 'false')
			PrizePool(prizePoolArgs):create():build()
			assert.stub(LpdbPlacementStub).called(1)
		end)

		it('wiki-var enabled with override', function()
			Variables.varDefine('disable_LPDB_storage', 'false')
			PrizePool(Table.merge(prizePoolArgs, {storelpdb = false})):create():build()
			assert.stub(LpdbPlacementStub).called(0)
		end)


		it('wiki-var disable with override', function()
			Variables.varDefine('disable_LPDB_storage', 'true')
			PrizePool(Table.merge(prizePoolArgs, {storelpdb = true})):create():build()
			assert.stub(LpdbPlacementStub).called(1)
		end)

		it('wiki-var disable without override', function()
			Variables.varDefine('disable_LPDB_storage', 'true')
			PrizePool(prizePoolArgs):create():build()
			assert.stub(LpdbPlacementStub).called(0)
		end)
	end)
end)
