--- Triple Comment to Enable our LLS Plugin
describe('prize pool', function()
	local PrizePool = require('Module:PrizePool')
	local InfoboxLeague = require('Module:Infobox/League/Custom')
	local tournamentData = mw.loadData('Module:TestAssets/Tournaments').dummy

	before_each(function()
		InfoboxLeague.run(tournamentData)
		stub(mw.ext.LiquipediaDB, "lpdb_placement")
		stub(mw.ext.LiquipediaDB, "lpdb", {})
	end)

	after_each(function ()
		---@diagnostic disable: undefined-field
		mw.ext.LiquipediaDB.lpdb_placement:revert()
		mw.ext.LiquipediaDB.lpdb:revert()
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

	it('prize pool looks correctly', function()
		GoldenTest('prize pool looks correctly', tostring(PrizePool(prizePoolArgs):create():build()))
	end)
end)
