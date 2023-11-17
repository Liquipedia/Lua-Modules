---
-- @Liquipedia
-- wiki=formula1
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	_args.driver_number = _args.participants_number
	league.addToLpdb = CustomLeague.addToLpdb
	league.createWidgetInjector = CustomLeague.createWidgetInjector

	return league:createInfobox()
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Race Number',
		content = {_args.race}
	})
	table.insert(widgets, Cell{
		name = 'Total Laps',
		content = {_args.laps}
	})
	table.insert(widgets, Cell{
		name = 'Pole Position',
		content = {_args.pole}
	})
	table.insert(widgets, Cell{
		name = 'Fastest Lap',
		content = {_args.fastestlap}
	})
	table.insert(widgets, Cell{
		name = 'Number of Races',
		content = {_args.numberofraces}
	})
	table.insert(widgets, Cell{
		name = 'Number of Drivers',
		content = {_args.driver_number}
	})
	table.insert(widgets, Cell{
		name = 'Number of Teams',
		content = {_args.team_number}
	})
	return widgets
end
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.participantsnumber = args.driver_number or args.team_number
	return lpdbData
end

return CustomLeague
