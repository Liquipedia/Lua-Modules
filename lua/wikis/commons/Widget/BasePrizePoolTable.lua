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
local Json = Lua.import('Module:Json')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Placement = Lua.import('Module:Placement')
local Points = Lua.import('Module:Points/data', {loadData = true})
local Table = Lua.import('Module:Table')

local Link = Lua.import('Module:Widget/Basic/Link')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

local BASE_CURRENCY = 'USD'
local NON_BREAKING_SPACE = '&nbsp;'

---@class BasePrizePoolWidgetSettings
---@field showPrizes boolean
---@field points {title: string, icon: string?, iconDark: string?, link: string?, titleLong: string?}?
---@field points2 {title: string, icon: string?, iconDark: string?, link: string?, titleLong: string?}?
---@field currency string
---@field title string
---@field autoExchange boolean
---@field cutAfter integer?

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
			settings.showPrizes and settings.autoExchange
				and TableWidgets.CellHeader{children = Currency.display(BASE_CURRENCY)} or nil,
			settings.showPrizes and TableWidgets.CellHeader{children = Currency.display(settings.currency)} or nil,
			self:_pointsHeader(settings.points),
			self:_pointsHeader(settings.points2)
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
			settings.showPrizes and settings.autoExchange and {
				align = 'right',
				sortType = 'number',
			} or nil,
			settings.showPrizes and {
				align = 'right',
				sortType = 'number',
			} or nil,
			settings.points and {
				align = 'right',
				sortType = 'number',
			} or nil,
			settings.points2 and {
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
---@return {place: rawPlacement, prize: number, usdPrize: number, points: number, points2: number, sort: integer}[]
---@return BasePrizePoolWidgetSettings
function BasePrizePoolTable:_parse()
	local props = self.props

	---@param prefix string
	---@return {title: string, icon: string?, iconDark: string?, link: string?, titleLong: string?}?
	local parsePoints = function(prefix)
		if Logic.isEmpty(props[prefix]) then
			return
		end

		local pointsData = Table.copy(Points[props[prefix]] or {})
		pointsData.title = pointsData.title or props[prefix]
		pointsData.link = props[prefix .. 'link']

		return pointsData
	end

	local currency = props.currency:upper()
	local settings = {
		points = parsePoints('points'),
		points2 = parsePoints('points2'),
		showPrizes = Logic.nilOr(Logic.readBoolOrNil(props.prizes), true),
		currency = currency,
		title = props.title,
		autoExchange = Logic.nilOr(Logic.readBoolOrNil(props.autoexchange), currency ~= BASE_CURRENCY),
		cutAfter = MathUtil.toInteger(props.cutafter),
	}
	assert(not settings.cutAfter or settings.cutAfter > 0, 'Invalid |cutafter=')
	local currencyRate = settings.autoExchange and Currency.getExchangeRate{
		currency = currency,
		date = DateExt.toYmdInUtc(props.edate or DateExt.getContextualDateOrNow()),
		setVariables = false
	} or 1

	---@type {place: rawPlacement, prize: number, usdPrize: number, points: number, points2: number, sort: integer}[]
	local placements = Array.mapIndexes(function(index)
		if Logic.isEmpty( props[index]) then return end

		local input = Json.parseIfTable(props[index])
		if Logic.isEmpty(input) then return end
		---@cast input -nil

		local place = Placement.raw(input.place)
		if place.unknown == true then return end

		local prize = mw.getContentLanguage():parseFormattedNumber(input.prize) or 0

		return {
			place = place,
			prize = prize,
			usdPrize = prize * currencyRate,
			points = mw.getContentLanguage():parseFormattedNumber(input.points) or 0,
			points2 = mw.getContentLanguage():parseFormattedNumber(input.points2) or 0,
			sort = tonumber(place.placement[1]),
		}
	end)

	return placements, settings
end

---@private
---@param settings BasePrizePoolWidgetSettings
---@param placementInfo {place: rawPlacement, prize: number, usdPrize: number,
---points: number, points2: number, sort: integer}
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
		settings.showPrizes and settings.autoExchange and TableWidgets.Cell{
			children = Currency.display(BASE_CURRENCY, placementInfo.usdPrize, currencyDisplayConfig),
			['data-sort-value'] = placementInfo.usdPrize,
		} or nil,
		settings.showPrizes and TableWidgets.Cell{
			children = Currency.display(settings.currency, placementInfo.prize, currencyDisplayConfig),
			['data-sort-value'] = placementInfo.prize,
		} or nil,
		settings.points and TableWidgets.Cell{
			children = Currency.formatMoney(placementInfo.points, 2, false, true),
			['data-sort-value'] = placementInfo.points,
		} or nil,
		settings.points2 and TableWidgets.Cell{
			children = Currency.formatMoney(placementInfo.points2, 2, false, true),
			['data-sort-value'] = placementInfo.points2,
		} or nil
	)}
end

---@private
---@param data {title: string, icon: string?, iconDark: string?, link: string?, titleLong: string?}?
---@return Widget?
function BasePrizePoolTable:_pointsHeader(data)
	if not data then
		return
	end

	local titleText = Logic.isNotEmpty(data.titleLong) and HtmlWidgets.Abbr{
		children = data.title, title = data.titleLong
	} or data.title

	return TableWidgets.CellHeader{children = WidgetUtil.collect(
		Logic.isNotEmpty(data.icon) and {
			LeagueIcon.display{link = data.link, icon = data.icon, iconDark = data.iconDark, name = data.title},
			NON_BREAKING_SPACE,
		} or nil,
		Logic.isNotEmpty(data.link) and Link{link = data.link, children = titleText} or titleText
	)}
end

return BasePrizePoolTable
