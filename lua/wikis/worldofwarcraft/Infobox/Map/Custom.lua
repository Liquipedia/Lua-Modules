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

---@class WowMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class WowMapInfoboxWidgetInjector: WidgetInjector
---@field caller WowMapInfobox
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

	if widgetId == 'release' then
		table.insert(widgets, Cell{name = 'Updated', content = {args.updated}})
	elseif widgetId == 'custom' then
		table.insert(widgets, Cell{name = 'Size', content = {args.size}})
	end
	return widgets
end

return CustomMap
