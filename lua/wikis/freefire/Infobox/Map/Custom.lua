---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class FreefireMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class FreefireMapInfoboxWidgetInjector: WidgetInjector
---@field caller FreefireMapInfobox
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
		Array.appendWith(widgets,
			Cell{name = 'Theme', content = {args.theme}},
			Cell{name = 'Span', content = {args.span}}
		)
	end
	return widgets
end

return CustomMap
