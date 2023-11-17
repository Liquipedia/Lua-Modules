---
-- @Liquipedia
-- wiki=formula1
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Map = Lua.import('Module:Infobox/Map', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomMap = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomMap.run(frame)
	local customMap = Map(frame)
	customMap.createWidgetInjector = CustomMap.createWidgetInjector
	customMap.addToLpdb = CustomMap.addToLpdb
	_args = customMap.args
	return customMap:createInfobox()
end

function CustomMap:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Architect',
		content = {_args.architect}
	})
	table.insert(widgets, Cell{
		name = 'Capacity',
		content = {_args.capacity}
	})
	table.insert(widgets, Cell{
		name = 'Opened',
		content = {_args.opened}
	})
	table.insert(widgets, Cell{
		name = 'Closed',
		content = {_args.closed}
	})
	table.insert(widgets, Cell{
		name = 'Turns',
		content = {_args.turns}
	})
	table.insert(widgets, Cell{
		name = 'Laps',
		content = {_args.laps}
	})
	table.insert(widgets, Cell{
		name = 'Direction',
		content = {_args.direction}
	})
	table.insert(widgets, Cell{
		name = 'Length',
		content = {_args.length}
	})
	table.insert(widgets, Cell{
		name = 'First Race',
		content = {_args.debut}
	})
	table.insert(widgets, Cell{
		name = 'Last Race',
		content = {_args.lastrace}
	})
	table.insert(widgets, Cell{
		name = 'Most wins (drivers)',
		content = {_args.driverwin}
	})
	table.insert(widgets, Cell{
		name = 'Most wins (teams)',
		content = {_args.teamwin}
	})
	table.insert(widgets, Cell{
		name = 'Lap Record',
		content = {_args.laprecord}
	})
	table.insert(widgets, Cell{
		name = 'Span',
		content = {_args.span}
	})
	return widgets
end



return CustomMap
