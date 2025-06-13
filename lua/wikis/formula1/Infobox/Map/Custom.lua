---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class Formula1MapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class Formula1MapInfoboxWidgetInjector: WidgetInjector
---@field caller Formula1MapInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)
	map:setWidgetInjector(CustomInjector(map))

	return map:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		return Array.appendWith(widgets,
			Cell{name = 'Architect', content = {args.architect}},
			Cell{name = 'Capacity', content = {args.capacity}},
			Cell{name = 'Opened', content = {args.opened}},
			Cell{name = 'Status', content = {args.status}},
			Cell{name = 'Turns', content = {args.turns}},
			Cell{name = 'Laps', content = {args.laps}},
			Cell{name = 'Direction', content = {args.direction}},
			Cell{name = 'Length', content = {args.length}},
			Cell{name = 'Debut', content = {args.debut}},
			Cell{name = 'Last Race', content = {args.lastrace}},
			Cell{name = 'Most wins (drivers)', content = {args.driverwin}},
			Cell{name = 'Most wins (teams)', content = {args.teamwin}},
			Cell{name = 'Lap Record', content = {args.laprecord}},
			Cell{name = 'Span', content = {args.span}}
		)
	end

	return widgets
end

return CustomMap
