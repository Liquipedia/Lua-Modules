---
-- @Liquipedia
-- page=Module:Widget/Standings/MatchOverview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Label = Lua.import('Module:Widget/Basic/Label')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

---@class MatchOverviewWidgetProps
---@field match MatchGroupUtilMatch
---@field showOpponent integer

---@class MatchOverviewWidget: Widget
---@operator call(MatchOverviewWidgetProps): MatchOverviewWidget
---@field props MatchOverviewWidgetProps
local MatchOverviewWidget = Class.new(Widget)

---@return Widget?
function MatchOverviewWidget:render()
	local match = self.props.match
	local opponentIndexToShow = tonumber(self.props.showOpponent)
	if not match or not opponentIndexToShow or #match.opponents ~= 2 then
		return
	end

	local opponentToShow = match.opponents[opponentIndexToShow]
	if not opponentToShow then
		return
	end

	local leftOpponent = Array.find(match.opponents, function(op) return op ~= opponentToShow end)
	if not leftOpponent then
		return
	end

	return HtmlWidgets.Div{
		css = {
			display = 'flex',
			['justify-content'] = 'space-between',
			['flex-direction'] = 'column',
			['align-items'] = 'center',
			gap = '0.25rem',
		},
		children = WidgetUtil.collect(
			self:_createResultDisplay(
				OpponentDisplay.InlineScore(leftOpponent),
				OpponentDisplay.InlineScore(opponentToShow)
			),
			OpponentDisplay.InlineOpponent{
				opponent = opponentToShow,
				overflow = 'ellipsis',
				teamStyle = 'icon',
			}
		),
	}
end

---@private
---@param self MatchOverviewWidget
---@return string
MatchOverviewWidget._getMatchResultType = FnUtil.memoize(function (self)
	local match = self.props.match
	local opponentIndexToShow = tonumber(self.props.showOpponent)

	if match.winner == opponentIndexToShow then
		return 'loss'
	elseif match.winner == 0 then
		return 'draw'
	end
	return 'win'
end)

---@private
---@param leftScore string
---@param rightScore string
---@return Widget[]
function MatchOverviewWidget:_createScoreContainer(leftScore, rightScore)
	local resultType = self:_getMatchResultType()
	return {
		HtmlWidgets.Span{
			css = resultType == 'win' and {['font-weight'] = 'bold'} or nil,
			children = leftScore
		},
		HtmlWidgets.Span{children = ':'},
		HtmlWidgets.Span{
			css = resultType == 'loss' and {['font-weight'] = 'bold'} or nil,
			children = rightScore
		}
	}
end

---@private
---@return Widget?
function MatchOverviewWidget:_createResultDisplay(leftScore, rightScore)
	if not self.props.match.finished then
		return
	end
	local resultType = self:_getMatchResultType()
	return Label{
		css = {
			display = 'grid',
			['grid-template-columns'] = '1fr auto 1fr',
			['justify-items'] = 'center',
			padding = '0.25rem',
		},
		labelType = 'result-' .. resultType,
		children = self:_createScoreContainer(leftScore, rightScore)
	}
end

return MatchOverviewWidget
