---
-- @Liquipedia
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')
local Tier = Lua.import('Module:Tier/Custom')

local Game = Lua.import('Module:Game')
local Injector = Lua.import('Module:Widget/Injector')
local Series = Lua.import('Module:Infobox/Series')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class CounterstrikeSeriesInfobox: SeriesInfobox
local CustomSeries = Class.new(Series)

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return string
function CustomSeries.run(frame)
	local series = CustomSeries(frame)
	series:setWidgetInjector(CustomInjector(series))

	series.args.liquipediatier = Tier.toNumber(series.args.liquipediatier)

	return series:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'type' then
		return {Cell{
				name = 'Type',
				children = {String.isNotEmpty(args.type) and mw.getContentLanguage():ucfirst(args.type) or nil}
			}}
	elseif id == 'custom' then
		return {
			Cell{name = 'Fate', children = {args.fate}},
			Cell{name = 'Games', children = Array.map(Game.listGames({ordered = true}), function (gameIdentifier)
				return args[gameIdentifier] and Game.text{game = gameIdentifier} or nil
			end)},
		}
	end
	return widgets
end

return CustomSeries
