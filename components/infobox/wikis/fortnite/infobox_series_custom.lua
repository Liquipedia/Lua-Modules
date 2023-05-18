---
-- @Liquipedia
-- wiki=fortnite
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Series = Lua.import('Module:Infobox/Series', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local Language = mw.language.new('en')

local CustomSeries = {}

local CustomInjector = Class.new(Injector)

local _series

local _totalSeriesPrizepool = 0

function CustomSeries.run(frame)
	local series = Series(frame)
	series.addToLpdb = CustomSeries.addToLpdb
	series.createWidgetInjector = CustomSeries.createWidgetInjector
	_series = series

	return series:createInfobox()
end

function CustomSeries:createWidgetInjector()
	return CustomInjector()
end

function CustomSeries.addToLpdb(series, lpdbData)
	lpdbData['prizepool'] = _totalSeriesPrizepool
	return lpdbData
end

function CustomSeries._getSeriesPrizepools(series)
	local queryData = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[series::' .. series .. ']]',
		query = 'sum::prizepool'
	})

	local prizemoney = tonumber(queryData[1]['sum_prizepool'])

	if prizemoney == nil or prizemoney == 0 then
		return nil
	end

	_totalSeriesPrizepool = prizemoney
	return '$' .. Language:formatNum(math.floor(prizemoney + 0.5))
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell({
		name = 'Total prize money',
		content = {CustomSeries._getSeriesPrizepools(_series.name)}
	}))
	return widgets
end

return CustomSeries
