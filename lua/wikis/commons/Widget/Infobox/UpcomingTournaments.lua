---
-- @Liquipedia
-- page=Module:Widget/Infobox/UpcomingTournaments
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Tournament = Lua.import('Module:Tournament')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local TournamentsTickerListItem = Lua.import('Module:Widget/Tournaments/Ticker/ListItem')

local UpcomingTournamentsWidget = {}

---@param props {opponentConditions: AbstractConditionNode?}
---@return Widget
function UpcomingTournamentsWidget.render(props)
	return Div{
		classes = {'fo-nttax-infobox', 'wiki-bordercolor-light', 'noincludereddit'},
		css = {['border-top'] = 'none'},
		children = {
			Div{children = Div{
				classes = {'infobox-header', 'wiki-backgroundcolor-light'},
				children = 'Upcoming Tournaments'
			}},
			UpcomingTournamentsWidget._getTournaments(props.opponentConditions)
		}
	}
end

---@private
---@param opponentConditions AbstractConditionNode?
---@return VNode
function UpcomingTournamentsWidget._getTournaments(opponentConditions)
	local conditions = ConditionTree(BooleanOperator.all)
		:add(opponentConditions)
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

return Component.component(UpcomingTournamentsWidget.render)
