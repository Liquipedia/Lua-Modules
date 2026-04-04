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
local Tournament = Lua.import('Module:Tournament')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local TournamentsTickerListItem = Lua.import('Module:Widget/Tournaments/Ticker/ListItem')

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
		children = {
			Div{children = Div{
				classes = {'infobox-header', 'wiki-backgroundcolor-light'},
				children = 'Upcoming Tournaments'
			}},
			self:_getTournaments()
		}
	}
end

---@private
---@return Widget
function UpcomingTournamentsWidget:_getTournaments()
	local conditions = ConditionTree(BooleanOperator.all)
		:add(self.props.opponentConditions)
		:add(ConditionNode(
			ColumnName('date'), Comparator.gt, DateExt.getCurrentTimestamp() - DateExt.daysToSeconds(1)
		))
		:add(ConditionNode(ColumnName('placement'), Comparator.eq, ''))

	local tournaments = Array.map(mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = conditions:toString(),
		order = 'startdate asc',
		query = 'pagename'
	}), function (placement)
		return Tournament.getTournament(placement.pagename)
	end)

	if Logic.isEmpty(tournaments) then
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
	return Div{
		classes = {'tournaments-list-type-list'},
		css = {['margin-bottom'] = 'unset !important'},
		children = Array.map(tournaments, function (tournament)
			return TournamentsTickerListItem{tournament = tournament}
		end)
	}
end

return UpcomingTournamentsWidget
