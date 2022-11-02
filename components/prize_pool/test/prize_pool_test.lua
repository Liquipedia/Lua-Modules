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
local TournamentMock = Lua.import('Module:Infobox/Mock/League', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testHeaderInput()
	local tournamentData = mw.loadData('Module:TestAssets/Tournaments').dummy
	TournamentMock.setUp(tournamentData)
	LpdbMock.setUp()

	local ppt = PrizePool{
		type = {type = 'team'},
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
	}:create()

	self:assertDeepEquals(
		{
			{id = 'USD1', type = 'USD', index = 1, data = {roundPrecision = 3}},
			{id = 'LOCAL_CURRENCY1', type = 'LOCAL_CURRENCY', index = 1, data =
				{
					rate = 0.97821993318758, roundPrecision = 3,
					currency = 'EUR', currencyText = '€&nbsp;<abbr title="Euro">EUR</abbr>',
					symbol = "€", symbolFirst = true
				}
			},
			{id = 'LOCAL_CURRENCY2', type = 'LOCAL_CURRENCY', index = 2, data =
				{
					rate = 0.088712426073718, roundPrecision = 3,
					currency = 'SEK', currencyText = '&nbsp;kr&nbsp;<abbr title="Swedish krona">SEK</abbr>',
					symbol = " kr", symbolFirst = false
				}
			},
			{id = 'QUALIFIES1', type = 'QUALIFIES', index = 1, data = {title = 'A Display', link = 'A_Tournament'}},
			{id = 'POINTS1', type = 'POINTS', index = 1, data = {title = 'Points', link = 'A Page'}},
			{id = 'FREETEXT1', type = 'FREETEXT', index = 1, data = {title = 'A title'}},
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

	self:assertEquals(
		'<div style="overflow-x:auto">$<abbr title="To Be Announced">TBA</abbr>&nbsp;<abbr title="United States Dollar">' ..
		'USD</abbr> are spread among the participants as seen below:<br>' ..
		'<div class="csstable-widget collapsed general-collapsible prizepooltable"' ..
		' style="grid-template-columns:repeat(8, auto);width:max-content"><div class="csstable-widget-row"' ..
		' style="font-weight:bold"><div class="csstable-widget-cell" style="min-width:80px">Place</div>' ..
		'<div class="csstable-widget-cell"><div>$&nbsp;<abbr title="United States Dollar">USD</abbr></div></div>' ..
		'<div class="csstable-widget-cell"><div>€&nbsp;<abbr title="Euro">EUR</abbr></div></div>' ..
		'<div class="csstable-widget-cell"><div>&nbsp;kr&nbsp;<abbr title="Swedish krona">SEK</abbr></div></div>' ..
		'<div class="csstable-widget-cell">Qualifies To</div><div class="csstable-widget-cell"><div>[[A Page|Points]]' ..
		'</div></div><div class="csstable-widget-cell"><div>A title</div></div>'..
		'<div class="csstable-widget-cell prizepooltable-col-team">Participant</div></div></div></div>',
		tostring(ppt:build())
	)

	TournamentMock.tearDown()
	LpdbMock.tearDown()
end

return suite
