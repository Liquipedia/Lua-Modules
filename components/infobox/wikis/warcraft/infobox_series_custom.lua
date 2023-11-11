---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Widgets = require('Module:Infobox/Widget/All')
local Math = require('Module:MathUtil')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Series = Lua.import('Module:Infobox/Series', {requireDevIfEnabled = true})

local Cell = Widgets.Cell

local Language = mw.language.new('en')

local CustomSeries = {}

local CustomInjector = Class.new(Injector)

local _series

local _totalSeriesPrizepool = 0

---@param frame Frame
---@return string
function CustomSeries.run(frame)
	local series = Series(frame)
	series.addToLpdb = CustomSeries.addToLpdb
	series.createWidgetInjector = CustomSeries.createWidgetInjector
	_series = series

	return series:createInfobox()
end

---@return WidgetInjector
function CustomSeries:createWidgetInjector()
	return CustomInjector()
end

---@param lpdbData table
---@return table
function CustomSeries:addToLpdb(lpdbData)
	lpdbData['prizepool'] = _totalSeriesPrizepool
	return lpdbData
end

---@param series string
---@return string?
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
	return '$' .. Language:formatNum(Math.round(prizemoney))
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell({
		name = 'Total prize money',
		content = {CustomSeries._getSeriesPrizepools(_series.name)}
	}))
	return widgets
end

return CustomSeries
