---
-- @Liquipedia
-- wiki=commons
-- page=Module:PrizePool/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local LpdbMock = Lua.import('Module:Mock/Lpdb', {requireDevIfEnabled = true})
local PrizePool = Lua.import('Module:PrizePool', {requireDevIfEnabled = true})
local Table = Lua.import('Module:Table', {requireDevIfEnabled = true})
local TournamentMock = Lua.import('Module:Infobox/Mock/League', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testHeaderInput()
	local tournamentData = mw.loadData('Module:TestAssets/Tournaments').dummy
	TournamentMock.setUp(tournamentData)
	LpdbMock.setUp()

	local ppt = PrizePool{
		type = {type = 'team'},
		currencyRoundPrecision = 3,
		lpdbPrefix = 'abc',
		fillPlaceRange = true,
		localcurrency1 = 'EUR',
		localcurrency2 = 'sek',
		points1 = 'points',
		points1link = 'A Page',
		qualifies1 = 'A Tournament',
		qualifies1title = 'A Display',
		freetext = 'A title',
	}:create()

	self:assertDeepEquals(
		{
			{id = 'USD1', type = 'USD', index = '1', data = {roundPrecision = 3}},
			{id = 'LOCAL_CURRENCY1', type = 'LOCAL_CURRENCY', index = '1', data =
				Table.merge(Table.deepCopy(mw.loadData('Module:Currency/Data').eur), {
					rate = 0.97821993318758, roundPrecision = 3,
				})
			},
			{id = 'LOCAL_CURRENCY2', type = 'LOCAL_CURRENCY', index = '2', data =
				Table.merge(Table.deepCopy(mw.loadData('Module:Currency/Data').sek), {
					rate = 0.088712426073718, roundPrecision = 3,
				})
			},
			{id = 'QUALIFIES1', type = 'QUALIFIES', index = '1', data = {title = 'A Display', link = 'A_Tournament'}},
			{id = 'POINTS1', type = 'POINTS', index = '1', data = {title = 'Points', link = 'A Page'}},
			{id = 'FREETEXT1', type = 'FREETEXT', index = '1', data = {title = 'A title'}},
		},
		ppt.prizes
	)
	self:assertDeepEquals(
		{
			abbreviateTbd = true,
			autoUSD = true,
			currencyRatePerOpponent = false,
			currencyRoundPrecision = 3,
			cutafter = 4,
			exchangeInfo = true,
			fillPlaceRange = true,
			lpdbPrefix = 'abc',
			prizeSummary = true,
			resolveRedirect = false,
			showUSD = true,
			storeLpdb = true,
			storeSmw = true,
			syncPlayers = false,
		},
		ppt.options
	)

	TournamentMock.tearDown()
	LpdbMock.tearDown()
end

return suite
