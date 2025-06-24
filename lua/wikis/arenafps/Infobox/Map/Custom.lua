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
local Title = Widgets.Title
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetImage = Lua.import('Module:Widget/Image/Icon/Image')

---@class ArenafpsMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class ArenafpsMapInfoboxWidgetInjector: WidgetInjector
---@field caller ArenafpsMapInfobox
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
			Cell{name = 'Game', content = {args.game}},
			Cell{name = 'Health Items', content = {args['health-items']}},
			Cell{name = 'Armor Items', content = {args['armor-items']}},
			Cell{name = 'Cooldown Items', content = {args['cooldown-items']}},
			Cell{name = 'Spawns', content = {args.spawns}},
			Cell{name = 'Starting Spawns', content = {args['starting-spawns']}},
			args.minimap and Title{children = {'Minimap'}} or nil,
			args.minimap and HtmlWidgets.Div{
				classes = {'infobox-image'},
				children = {WidgetImage{
					imageLight = args.minimap,
					size = '350px',
					alignment = 'center',
				}}
			} or nil
		)
	end
	return widgets
end

return CustomMap
