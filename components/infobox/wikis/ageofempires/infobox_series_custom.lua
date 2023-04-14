---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Cell = require('Module:Infobox/Widget/Cell')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Tier = require('Module:Tier/Custom')

local InfoboxPrizePool = Lua.import('Module:Infobox/Extensions/PrizePool', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Series = Lua.import('Module:Infobox/Series', {requireDevIfEnabled = true})

local CustomSeries = {}
local CustomInjector = Class.new(Injector)

local _series
local _totalSeriesPrizepool = 0

function CustomSeries.run(frame)
	local series = Series(frame)
	series.addToLpdb = CustomSeries.addToLpdb
	series.createWidgetInjector = CustomSeries.createWidgetInjector
	series.createLiquipediaTierDisplay = CustomSeries.createLiquipediaTierDisplay
	_series = series

	return series:createInfobox()
end

function CustomSeries:createWidgetInjector()
	return CustomInjector()
end

function CustomSeries.addToLpdb(series, lpdbData)
	lpdbData.prizepool = _totalSeriesPrizepool
	return lpdbData
end

function CustomSeries._getSeriesPrizepools(seriesName)
	local pagename = mw.title.getCurrentTitle().text:gsub('%s', '_')
	local prizemoney = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[series::' .. seriesName .. ']] OR [[seriespage::' .. pagename .. ']]',
		query = 'sum::prizepool'
	})

	prizemoney = tonumber(prizemoney[1]['sum_prizepool'])

	if prizemoney == nil or prizemoney == 0 then
		return nil
	end

	_totalSeriesPrizepool = prizemoney
	return InfoboxPrizePool.display{prizepoolusd = prizemoney}
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell({
		name = 'Total prize money',
		content = {CustomSeries._getSeriesPrizepools(_series.name)}
	}))
	return widgets
end

function CustomSeries:createLiquipediaTierDisplay(args)
	return (Tier.display(
		args.liquipediatier,
		args.liquipediatiertype
	) or '') .. self.appendLiquipediatierDisplay(args)
end

return CustomSeries
