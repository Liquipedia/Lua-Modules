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
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
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
}

---@return Widget?
function BasePrizePoolTable:render()
	local placements, settings = self:_parse()

	local headerRow = TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = WidgetUtil.collect(
			TableWidgets.CellHeader{children = {'Place'}},
			TableWidgets.CellHeader{children = {'Prize'}},
			settings.showPoints and TableWidgets.CellHeader{children = {'Points'}} or nil
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
			{
				align = 'right',
				sortType = 'number',
			},
			settings.showPoints and {
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
---@return {place: string, prize: number, points: number, sort: integer}[]
---@return {showPoints: boolean, currency: string, title: string, cutAfter: integer?}
function BasePrizePoolTable:_parse()
	local props = self.props
	local settings = {
		showPoints = Logic.readBool(props.points),
		currency = props.currency,
		title = props.title,
		cutAfter = tonumber(props.cutafter),
	}

	---@type {place: string, prize: number, points: number, sort: integer}[]
	local placements = {}
	Table.iter.forEachPair(self.props, function(key, value)
		if not string.match(key, '^%d+%-?%d*$') then
			return
		end
		local sortValue = tonumber(Array.parseCommaSeparatedString(tostring(key), '-')[1])
		if not sortValue then
			return
		end
		local prizeString = mw.getContentLanguage():parseFormattedNumber(value)
		local prize = tonumber(prizeString)
		assert(prize, 'Invalid entry "|' .. key .. '=' .. value .. '"')

		local pointsString = mw.getContentLanguage():parseFormattedNumber(props[key .. '_points'] or '')

		table.insert(placements, {
			place = key,
			prize = prize,
			points = tonumber(pointsString) or 0,
			sort = sortValue,
		})
	end)

	Array.sortInPlaceBy(placements, Operator.property('sort'))

	return placements, settings
end

---@private
---@param settings {showPoints: boolean, currency: string, title: string, cutAfter: integer?}
---@param placementInfo {place: string, prize: number, points: number, sort: integer}
---@return Widget
function BasePrizePoolTable._row(settings, placementInfo)
	local rawPlacement = Placement.raw(placementInfo.place or '')

	return TableWidgets.Row{children = WidgetUtil.collect(
		TableWidgets.Cell{
			children = Placement.renderInWidget{placement = placementInfo.place},
			['data-sort-value'] = rawPlacement.sort,
		},
		TableWidgets.Cell{
			children = Currency.display(settings.currency, placementInfo.prize, {
				formatValue = true,
				dashIfZero = true,
				displaySymbol = true,
			}),
			['data-sort-value'] = placementInfo.prize,
		},
		settings.showPoints and TableWidgets.Cell{
			children = Currency.formatMoney(placementInfo.points, 2, false, true),
			['data-sort-value'] = placementInfo.points,
		} or nil
	)}
end

return BasePrizePoolTable
