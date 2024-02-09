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

local LpdbMock = Lua.import('Module:Mock/Lpdb')
local PrizePool = Lua.import('Module:PrizePool')
local TournamentMock = Lua.import('Module:Infobox/Mock/League')

local suite = ScribuntoUnit:new()

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
