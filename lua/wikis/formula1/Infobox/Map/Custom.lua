---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = Lua.import('Module:Widget/All')
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
			Cell{name = 'Architect', children = {args.architect}},
			Cell{name = 'Capacity', children = {args.capacity}},
			Cell{name = 'Opened', children = {args.opened}},
			Cell{name = 'Status', children = {args.status}},
			Cell{name = 'Turns', children = {args.turns}},
			Cell{name = 'Laps', children = {args.laps}},
			Cell{name = 'Direction', children = {args.direction}},
			Cell{name = 'Length', children = {args.length}},
			Cell{name = 'Debut', children = {args.debut}},
			Cell{name = 'Last Race', children = {args.lastrace}},
			Cell{name = 'Most wins (drivers)', children = {args.driverwin}},
			Cell{name = 'Most wins (teams)', children = {args.teamwin}},
			Cell{name = 'Lap Record', children = {args.laprecord}}
		)
	end

	return widgets
end

return CustomMap
