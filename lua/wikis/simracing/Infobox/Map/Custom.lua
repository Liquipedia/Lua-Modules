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

---@class SimracingMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class SimracingMapInfoboxWidgetInjector: WidgetInjector
---@field caller SimracingMapInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)
	map.args.informationType = 'Track'
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
			Cell{name = 'Architect', content = {args.type}},
			Cell{name = 'Opened', content = {args.open}},
			Cell{name = 'Length', content = {args.length}},
			Cell{name = 'Turns', content = {args.turns}}
		)
	end

	return widgets
end

return CustomMap
