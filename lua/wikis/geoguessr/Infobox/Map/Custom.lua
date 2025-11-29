---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Map = Lua.import('Module:Infobox/Map')
local Injector = Lua.import('Module:Infobox/Widget/Injector')
local String = Lua.import('Module:StringUtils')

local Link = require('Module:Widget/Basic/Link')
local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class GeoguessrMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class GeoguessrMapInfoboxWidgetInjector: WidgetInjector
---@field caller GeoguessrMapInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Widget
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
		Array.appendWith(
			widgets,
			Cell{name = 'Level', children = {args.level}},
			Cell{name = 'Tags', children = {args.tags}},
			Cell{name = 'Map Link', children = {tostring(Link{
				linktype = 'external',
				link = args.maplink,
				children = {args.map},
			})}}
		)
	end
	return widgets
end

return CustomMap
