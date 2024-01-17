---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Storage/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local LpdbMock = Lua.import('Module:Mock/Lpdb')
local StandingsStorage = Lua.import('Module:Standings/Storage')
local Table = Lua.import('Module:Table')
local TournamentMock = Lua.import('Module:Infobox/Mock/League')

local suite = ScribuntoUnit:new()

function suite:testStorageTable()
	local tournamentData = mw.loadData('Module:TestAssets/Tournaments').dummy
	TournamentMock.setUp(tournamentData)
	LpdbMock.setUp()

	StandingsStorage.run{
		standingsindex = 0,
		title = '',
		type = 'league',
		entries = {},
	}

	local fn = function ()
		StandingsStorage.run{
			standingsindex = 1,
			title = '',
			type = 'ajksd',
			entries = {},
		}
	end
	self:assertThrows(fn)

	TournamentMock.tearDown()
	LpdbMock.tearDown()
end

function suite:testStorageFull()
	local standingsData = Table.deepCopy(mw.loadData('Module:TestAssets/Standings'))
	local tournamentData = mw.loadData('Module:TestAssets/Tournaments').dummy
	TournamentMock.setUp(tournamentData)
	LpdbMock.setUp()

	StandingsStorage.run(standingsData)

	TournamentMock.tearDown()
	LpdbMock.tearDown()
end

return suite
