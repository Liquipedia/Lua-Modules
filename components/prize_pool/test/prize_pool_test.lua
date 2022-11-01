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

function suite:testStorageTable()
	local tournamentData = mw.loadData('Module:TestAssets/Tournaments').dummy
	TournamentMock.setUp(tournamentData)
	LpdbMock.setUp()

	local ppt = PrizePool{
		type = {type = 'team'},
		currencyRoundPrecision = 3,
	}

	self:assertDeepEquals(
		{
			{id = 'LOCAL_CURRENCY1', type = 'LOCAL_CURRENCY', index = '1', data =
				Table.merge(mw.loadData('Module:Currency/Data').eur, {
					rate = 0.97821993318758, roundPrecision = 3,
				})
			},
			{id = 'LOCAL_CURRENCY2', type = 'LOCAL_CURRENCY', index = '2', data =
				Table.merge(mw.loadData('Module:Currency/Data').sek, {
					rate = 0.088712426073718, roundPrecision = 3,
				})
			},
			{id = 'POINTS1', type = 'POINTS', index = '1', data = {title = 'Points', link = 'A Page'}},
			{id = 'QUALIFIES1', type = 'QUALIFIES', index = '1', data = {title = 'A Display', link = 'A_Tournament'}},
			{id = 'FREETEXT1', type = 'FREETEXT', index = '1', data = {title = 'A title'}},
		},
		ppt:_readConfig{
			localcurrency1 = 'EUR',
			localcurrency2 = 'sek',
			points1 = 'points',
			points1link = 'A Page',
			qualifies1 = 'A Tournament',
			qualifies1title = 'A Display',
			freetext = 'A title'
		}
	)

	TournamentMock.tearDown()
	LpdbMock.tearDown()
end

return suite
