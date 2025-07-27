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

local Widgets = Lua.import('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class SideswipeMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class SideswipeMapInfoboxWidgetInjector: WidgetInjector
---@field caller SideswipeMapInfobox
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
		Array.appendWith(widgets,
			Cell{name = 'Playlists', content = {args.playlists}},
			Cell{name = 'Gamemodes', content = {args.gamemodes}},
			Cell{name = 'Versions', content = {args.versions}},
			Cell{name = 'Layout', content = {args.layout}}
		)
	end
	return widgets
end

return CustomMap
