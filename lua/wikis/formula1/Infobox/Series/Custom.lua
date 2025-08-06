---
-- @Liquipedia
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Widget/Injector')
local Series = Lua.import('Module:Infobox/Series')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class Formula1SeriesInfobox: SeriesInfobox
local CustomSeries = Class.new(Series)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return string
function CustomSeries.run(frame)
	local series = CustomSeries(frame)
	series:setWidgetInjector(CustomInjector(series))

	return series:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		return Array.appendWith(widgets,
			Cell{name = 'Races Held', content = {args.races}},
			Cell{name = 'Fastest Lap', content = {args.fastestlap}},
			Cell{name = 'Most wins (drivers)', content = {args.driverwin}},
			Cell{name = 'Most wins (teams)', content = {args.teamwin}},
			Cell{name = 'Span', content = {args.span}}
		)
	end
	return widgets
end

return CustomSeries
