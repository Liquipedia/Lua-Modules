---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = Lua.import('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class CrossfireMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class CrossfireMapInfoboxWidgetInjector: WidgetInjector
---@field caller CrossfireMapInfobox
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
			Cell{name = 'Scenario', content = {args.scenario}},
			Cell{name = 'Terrorists', content = {args.t}},
			Cell{name = 'Counter Terrorists', content = {args.ct}}
		)
	end
	return widgets
end

---@param args table
---@return string[]
function CustomMap:getWikiCategories(args)
	local gameAbbreviation = Game.abbreviation{game = args.game, useDefault = false}
	return {gameAbbreviation and ('Maps ' .. gameAbbreviation) or nil}
end

return CustomMap
