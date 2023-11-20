---
-- @Liquipedia
-- wiki=formula1
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Map = Lua.import('Module:Infobox/Map', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomMap = Class.new()

local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local customMap = Map(frame)
	customMap.createWidgetInjector = CustomMap.createWidgetInjector
	_args = customMap.args
	return customMap:createInfobox()
end

---@return WidgetInjector
function CustomMap:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return Array.appendWith(widgets,
		Cell{name = 'Architect', content = {_args.architect}},
		Cell{name = 'Capacity', content = {_args.capacity}},
		Cell{name = 'Location', content = {_args.circuitlocation}},
		Cell{name = 'Opened', content = {_args.opened}},
		Cell{name = 'Turns', content = {_args.turns}},
		Cell{name = 'Laps', content = {_args.laps}},
		Cell{name = 'Direction', content = {_args.direction}},
		Cell{name = 'Length', content = {_args.length}},
		Cell{name = 'Debut', content = {_args.debut}},
		Cell{name = 'Last Race', content = {_args.lastrace}},
		Cell{name = 'Most wins (drivers)', content = {_args.driverwin}},
		Cell{name = 'Most wins (teams)', content = {_args.teamwin}},
		Cell{name = 'Lap Record', content = {_args.laprecord}},
		Cell{name = 'Span', content = {_args.span}}
	)
end

return CustomMap
