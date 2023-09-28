---
-- @Liquipedia
-- wiki=commons
-- page=Module:PrizePool/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

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
			{id = 'BASE_CURRENCY1', type = 'BASE_CURRENCY', index = 1, data = {roundPrecision = 3}},
			{id = 'LOCAL_CURRENCY1', type = 'LOCAL_CURRENCY', index = 1, data =
				{
					rate = 0.97821993318758,
					roundPrecision = 3,
					currency = 'EUR',
				}
			},
			{id = 'LOCAL_CURRENCY2', type = 'LOCAL_CURRENCY', index = 2, data =
				{
					rate = 0.088712426073718,
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

	self:assertDeepEquals(
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

	self:assertEquals(
		'<div style="overflow-x:auto">$<abbr title="To Be Announced">TBA</abbr>&nbsp;<abbr title="United States Dollar">' ..
		'USD</abbr> are spread among the participants as seen below:<br>' ..
		'<div class="csstable-widget collapsed general-collapsible prizepooltable"' ..
		' style="grid-template-columns:repeat(8, auto);width:max-content">' ..
		'<div class="csstable-widget-row prizepooltable-header"' ..
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


local TEST_DATA = {
	type = {type = 'team'},
	currencyroundprecision = 3,
	lpdb_prefix = 'abc',
	fillPlaceRange = true,
	localcurrency1 = 'EUR',
	import = false,
	[1] = {localprize = '1,000', [1] = {'Team Sweden'}},
}

function suite:testStorage()
	local callbackCalled = false
	local callback = function()
		callbackCalled = true
	end

	local tournamentData = mw.loadData('Module:TestAssets/Tournaments').dummy
	TournamentMock.setUp(tournamentData)
	LpdbMock.setUp(callback)

	-- default, no variable influence
	PrizePool(TEST_DATA):create():build()
	self:assertTrue(callbackCalled)

	callbackCalled = false
	-- variable influence: storage enabled again
	Variables.varDefine('disable_LPDB_storage', 'false')
	PrizePool(TEST_DATA):create():build()
	self:assertTrue(callbackCalled)

	callbackCalled = false
	-- variable influence: storage disabled, but forced via arguments
	Variables.varDefine('disable_LPDB_storage', 'true')
	PrizePool(Table.merge(TEST_DATA, {storelpdb = true})):create():build()
	self:assertTrue(callbackCalled)

	TournamentMock.tearDown()
	LpdbMock.tearDown()
end

function suite:testStorageDisable()
	local callbackCalled = false
	local callback = function()
		callbackCalled = true
	end

	local tournamentData = mw.loadData('Module:TestAssets/Tournaments').dummy
	TournamentMock.setUp(tournamentData)
	LpdbMock.setUp(callback)

	-- storage disabled via arguments
	PrizePool(Table.merge(TEST_DATA, {storelpdb = false})):create():build()
	self:assertFalse(callbackCalled)

	-- variable influence: storage disabled
	Variables.varDefine('disable_LPDB_storage', 'true')
	PrizePool(TEST_DATA):create():build()
	self:assertFalse(callbackCalled)

	-- variable influence: storage enabled, but disabled via arguments
	Variables.varDefine('disable_LPDB_storage', 'false')
	PrizePool(Table.merge(TEST_DATA, {storelpdb = false})):create():build()
	self:assertFalse(callbackCalled)

	TournamentMock.tearDown()
	LpdbMock.tearDown()
end

return suite
