---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class TrackmaniaMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class TrackmaniaMapInfoboxWidgetInjector: WidgetInjector
---@field caller TrackmaniaMapInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)
	map:setWidgetInjector(CustomInjector(map))
	return map:createInfobox()
end

---@param widgetId string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(widgetId, widgets)
	local caller = self.caller
	local args = caller.args

	if widgetId == 'custom' then
		table.insert(widgets, Cell{name = 'Style', content = {args.style}})
	end
	return widgets
end

return CustomMap
