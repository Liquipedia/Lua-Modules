---
-- @Liquipedia
-- wiki=fortnite
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local InfoboxPrizePool = Lua.import('Module:Infobox/Extensions/PrizePool', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Series = Lua.import('Module:Infobox/Series', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local Language = mw.language.new('en')

---@class FortniteSeriesInfobox: SeriesInfobox
---@field totalSeriesPrizepool number?
local CustomSeries = Class.new(Series)

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return string
function CustomSeries.run(frame)
	local series = CustomSeries(frame)
	series:setWidgetInjector(CustomInjector(series))

	series.totalSeriesPrizepool = CustomSeries._getSeriesPrizepools(series.name)

	return series:createInfobox()
end

---@param seriesName string
---@return number?
function CustomSeries._getSeriesPrizepools(seriesName)
	local pagename = mw.title.getCurrentTitle().text:gsub('%s', '_')
	local queryData = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[series::' .. seriesName .. ']] OR [[seriespage::' .. pagename .. ']]',
		query = 'sum::prizepool'
	})

	local prizemoney = tonumber(queryData[1]['sum_prizepool'])

	if prizemoney == nil or prizemoney == 0 then
		return nil
	end
	return prizemoney
end

---@param lpdbData table
---@return table
function CustomSeries:addToLpdb(lpdbData)
	lpdbData['prizepool'] = self.totalSeriesPrizepool
	return lpdbData
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'custom' then
		local totalSeriesPrizepool = self.caller.totalSeriesPrizepool
		table.insert(widgets, Cell({
			name = 'Total prize money',
			content = {totalSeriesPrizepool and InfoboxPrizePool.display{prizepoolusd = totalSeriesPrizepool} or nil}
		}))
	end

	return widgets
end

return CustomSeries
