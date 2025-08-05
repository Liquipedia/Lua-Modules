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
local Logic = Lua.import('Module:Logic')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = Lua.import('Module:Infobox/Widget/All')
local Center = Widgets.Center
local Cell = Widgets.Cell
local Title = Widgets.Title
local WidgetImage = Lua.import('Module:Widget/Image/Icon/Image')
local WidgetUtil = Lua.import('Module:Widget/Util')

local GAME_ABBR_CS1 = 'CS1'

---@class CounterstrikeMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class CounterstrikeMapInfoboxWidgetInjector: WidgetInjector
---@field caller CounterstrikeMapInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)
	map:setWidgetInjector(CustomInjector(map))
	return map:createInfobox()
end

---@param args table
---@return string[]
function CustomMap:getWikiCategories(args)
	local gameAbbreviation = Game.abbreviation{game = args.game, useDefault = false}
	if not gameAbbreviation then return {} end

	-- extra case to match old category
	if gameAbbreviation == GAME_ABBR_CS1 then
		gameAbbreviation = 'CS1.6'
	end

	return {'Maps ' .. gameAbbreviation}
end

---@param widgetId string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(widgetId, widgets)
	local caller = self.caller
	local args = caller.args

	if widgetId == 'custom' then
		return WidgetUtil.collect(
			widgets,
			Cell{name = 'Scenario', content = {args.scenario}},
			Cell{name = 'Terrorists', content = {args.t}},
			Cell{name = 'Counter Terrorists', content = {args.ct}},
			caller:_getAchievements()
		)
	end
	return widgets
end

---@return Widget[]
function CustomMap:_getAchievements()
	local args = self.args
	local achievements = Array.mapIndexes(function(index)
		local input = args['achievement' .. index]
		if Logic.isEmpty(input) then return end
		return WidgetImage{
			imageLight = input .. '.png',
			link = 'Achievements#' .. input,
			alt = input,
			size = '48px',
			caption = input,
		}
	end)
	if Logic.isEmpty(achievements) then return {} end
	return {
		Title{children = {'Achievements'}},
		Center{children = Array.interleave(achievements, ' ')},
	}
end

return CustomMap
