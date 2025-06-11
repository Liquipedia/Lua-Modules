---
-- @Liquipedia
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Series = Lua.import('Module:Infobox/Series')

---@class FightersSeriesInfobox: SeriesInfobox
local CustomSeries = Class.new(Series)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomSeries.run(frame)
	local series = CustomSeries(frame)
	series:setWidgetInjector(CustomInjector(series))

	return series:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'totalprizepool' then return {} end

	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomSeries:addToLpdb(lpdbData, args)
	lpdbData.extradata = {
		parentseries = args.parentseries
	}

	return lpdbData
end

return CustomSeries
