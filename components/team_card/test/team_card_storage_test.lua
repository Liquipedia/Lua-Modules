---
-- @Liquipedia
-- wiki=commons
-- page=Module:TeamCard/Storage/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local TCStorage = Lua.import('Module:TeamCard/Storage', {requireDevIfEnabled = true})
local TournamentMock = Lua.import('Module:Infobox/League/Mock', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testStandardFields()
	local tournamentData = mw.loadData('Module:TestAssets/Tournaments').dummy

	TournamentMock.setUp(tournamentData)

	local args = {image1 = 'dummy.png', imagedark1 = 'dummydark.png'}
	local actualData = TCStorage._addStandardLpdbFields({}, 'Team Liquid', args, 'prefix')

	local expectedData = {
		tournament = tournamentData.name,
		series = tournamentData.series,
		parent = 'Module:TeamCard/Storage/testcases',
		startdate = tournamentData.sdate,
		date = tournamentData.edate,
		image = args.image1,
		imagedark = args.imagedark1,
		mode = 'team',
		publishertier = nil,
		icon = tournamentData.icon,
		icondark = tournamentData.icondark,
		game = string.lower(tournamentData.game),
		liquipediatier = tournamentData.liquipediatier,
		liquipediatiertype = tournamentData.liquipediatiertype,
	}

	for field, expectedValue in pairs(expectedData) do
		self:assertEquals(expectedValue, actualData[field], field)
	end

	TournamentMock.tearDown()
end

function suite:testObjectName()
	self:assetEquals('ranking_foo_örban', TCStorage._getLpdbObjectName('Örban', 'foo'))
	self:assetEquals('ranking_tbd_1', TCStorage._getLpdbObjectName('TBD'))
	self:assetEquals('ranking_tbd_2', TCStorage._getLpdbObjectName('TBD'))
end

return suite
