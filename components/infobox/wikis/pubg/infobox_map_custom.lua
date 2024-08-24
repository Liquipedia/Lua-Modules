---
-- @Liquipedia
-- wiki=pubg
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class PUBGMapInfobox: MapInfobox
local CustomMap = Class.new(Map)

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
	local args = self.caller.args

	if widgetId == 'custom' then
		return Array.append(
			widgets,
			Cell{name = 'Theme', content = {args.theme}},
			Cell{name = 'Size', content = {args.size}},
			Cell{name = 'Competition Span', content = {args.span}},
			Cell{name = 'Release Date', content = {args.release}},
			Cell{name = 'Versions', content = {args.versions}}
		)
	end

	return widgets
end

return CustomMap
