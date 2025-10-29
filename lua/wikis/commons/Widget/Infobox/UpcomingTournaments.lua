---
-- @Liquipedia
-- page=Module:Widget/Infobox/UpcomingTournaments
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Header = Lua.import('Module:Widget/Infobox/UpcomingTournaments/Header')
local Row = Lua.import('Module:Widget/Infobox/UpcomingTournaments/Row')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class UpcomingTournamentsWidgetParameters
---@field opponentConditions AbstractConditionNode
---@field options table?

---@class UpcomingTournamentsWidget: Widget
---@operator call(UpcomingTournamentsWidgetParameters): UpcomingTournamentsWidget
---@field props UpcomingTournamentsWidgetParameters
local UpcomingTournamentsWidget = Class.new(Widget)

---@return Widget
function UpcomingTournamentsWidget:render()
	return Div{
		classes = {'fo-nttax-infobox', 'wiki-bordercolor-light', 'noincludereddit'},
		css = {['border-top'] = 'none'},
		children = WidgetUtil.collect(
			Header{},
			self:_getTournaments()
		)
	}
end

---@private
---@return Widget|Widget[]
function UpcomingTournamentsWidget:_getTournaments()
	local conditions = ConditionTree(BooleanOperator.all)
		:add(self.props.opponentConditions)
		:add(ConditionNode(ColumnName('date'), Comparator.gt, DateExt.getCurrentTimestamp() - 86400))
		:add(ConditionNode(ColumnName('placement'), Comparator.eq, ''))

	local placements = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = conditions:toString(),
		order = 'startdate asc',
		query = 'tournament, date, startdate, pagename, icon, icondark, publishertier, extradata'
	})

	if Logic.isEmpty(placements) then
		return Div{
			classes = {'text-center'},
			css = {
				display = 'flex',
				height = '3.75rem',
				['align-items'] = 'center',
				['flex-direction'] = 'row',
				['justify-content'] = 'center'
			},
			children = 'No Upcoming Tournaments'
		}
	end
	return Array.map(placements, function (placement)
		return Row{data = placement, options = self.props.options}
	end)
end

return UpcomingTournamentsWidget
