---
-- @Liquipedia
-- page=Module:Widget/BasePrizePoolTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Currency = Lua.import('Module:Currency')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Operator = Lua.import('Module:Operator')
local Placement = Lua.import('Module:Placement')
local Table = Lua.import('Module:Table')

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

local BASE_CURRENCY = 'USD'

---@class BasePrizePoolTable: Widget
---@operator call(table): BasePrizePoolTable
---@field props table<string|number, string>
local BasePrizePoolTable = Class.new(Widget)
BasePrizePoolTable.defaultProps = {
	title = 'Base prize money',
	currency = BASE_CURRENCY,
	pointsheader = 'Points',
	points2header = 'Points',
}

---@return Widget?
function BasePrizePoolTable:render()
	local placements, settings = self:_parse()

	local headerRow = TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = WidgetUtil.collect(
			TableWidgets.CellHeader{children = 'Place'},
			settings.autoExchange and TableWidgets.CellHeader{children = Currency.display(BASE_CURRENCY)} or nil,
			TableWidgets.CellHeader{children = Currency.display(settings.currency)},
			settings.showPoints and TableWidgets.CellHeader{children = settings.pointsHeader} or nil,
			settings.showPoints2 and TableWidgets.CellHeader{children = settings.points2Header} or nil
		)}
	}}

	return TableWidgets.Table{
		caption = settings.title,
		tableClasses = settings.cutAfter and {'prizepooltable', 'collapsed'} or nil,
		tableAttributes = settings.cutAfter and {
			['data-cutafter'] = settings.cutAfter,
			['data-opentext'] = 'Show more',
			['data-closetext'] = 'Show less',
		} or nil,
		sortable = not settings.cutAfter,
		columns = WidgetUtil.collect(
			{
				align = 'center',
			},
			settings.autoExchange and {
				align = 'right',
				sortType = 'number',
			} or nil,
			{
				align = 'right',
				sortType = 'number',
			},
			settings.showPoints and {
				align = 'right',
				sortType = 'number',
			} or nil,
			settings.showPoints2 and {
				align = 'right',
				sortType = 'number',
			} or nil
		),
		children = {
			headerRow,
			TableWidgets.TableBody{children = Array.map(placements, FnUtil.curry(BasePrizePoolTable._row, settings))}
		},
	}
end

---@private
---@return {place: table, prize: number, usdPrize: number, points: number, points2: number, sort: integer}[]
---@return {showPoints: boolean, showPoints2: boolean, pointsHeader: string, points2Header: string,
---currency: string, title: string, autoExchange: boolean, cutAfter: integer?}
function BasePrizePoolTable:_parse()
	local props = self.props
	local currency = props.currency:upper()
	local settings = {
		showPoints = Logic.readBool(props.points),
		showPoints2 = Logic.readBool(props.points2),
		currency = currency,
		title = props.title,
		pointsHeader = props.pointsheader,
		points2Header = props.points2header,
		autoExchange = Logic.nilOr(Logic.readBoolOrNil(props.autoexchange), currency ~= BASE_CURRENCY),
		cutAfter = MathUtil.toInteger(props.cutafter),
	}
	assert(not settings.cutAfter or settings.cutAfter > 0, 'Invalid |cutafter=')
	local currencyRate = settings.autoExchange and Currency.getExchangeRate{
		currency = currency,
		date = DateExt.toYmdInUtc(props.edate or DateExt.getContextualDateOrNow()),
		setVariables = false
	} or 1

	---@type {place: string, prize: number, usdPrize: number, points: number, sort: integer}[]
	local placements = {}
	Table.iter.forEachPair(self.props, function(key, value)
		if not string.match(key, '^%d+%-?%d*$') then
			return
		end
		local place = Placement.raw(key)
		if place.unknown == true then
			return
		end
		local prizeString = mw.getContentLanguage():parseFormattedNumber(value)
		local prize = tonumber(prizeString)
		assert(prize, 'Invalid entry "|' .. key .. '=' .. value .. '"')

		local pointsString = mw.getContentLanguage():parseFormattedNumber(props[key .. '_points'] or '')

		local points2String = mw.getContentLanguage():parseFormattedNumber(props[key .. '_points2'] or '')

		table.insert(placements, {
			place = place,
			prize = prize,
			usdPrize = prize * currencyRate,
			points = tonumber(pointsString) or 0,
			points2 = tonumber(points2String) or 0,
		})
	end)

	Array.sortInPlaceBy(placements, Operator.property('place.sort'))

	return placements, settings
end

---@private
---@param settings {showPoints: boolean, showPoints2: boolean, pointsHeader: string, points2Header: string,
---currency: string, title: string, autoExchange: boolean, cutAfter: integer?}
---@param placementInfo {place: table, prize: number, usdPrize: number, points: number, points2: number, sort: integer}
---@return Widget
function BasePrizePoolTable._row(settings, placementInfo)
	local currencyDisplayConfig = {
		displaySymbol = true,
		formatValue = true,
		displayCurrencyCode = false,
		dashIfZero = true,
	}

	return TableWidgets.Row{children = WidgetUtil.collect(
		TableWidgets.Cell{
			children = Placement.renderRawInWidget(placementInfo.place),
			['data-sort-value'] = placementInfo.place.sort,
		},
		settings.autoExchange and TableWidgets.Cell{
			children = Currency.display(BASE_CURRENCY, placementInfo.usdPrize, currencyDisplayConfig),
			['data-sort-value'] = placementInfo.usdPrize,
		} or nil,
		TableWidgets.Cell{
			children = Currency.display(settings.currency, placementInfo.prize, currencyDisplayConfig),
			['data-sort-value'] = placementInfo.prize,
		},
		settings.showPoints and TableWidgets.Cell{
			children = Currency.formatMoney(placementInfo.points, 2, false, true),
			['data-sort-value'] = placementInfo.points,
		} or nil,
		settings.showPoints2 and TableWidgets.Cell{
			children = Currency.formatMoney(placementInfo.points2, 2, false, true),
			['data-sort-value'] = placementInfo.points2,
		} or nil
	)}
end

return BasePrizePoolTable
