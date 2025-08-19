---
-- @Liquipedia
-- page=Module:Widget/Standings/MatchOverview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

---@class MatchOverviewWidget: Widget
---@operator call(table): MatchOverviewWidget

local MatchOverviewWidget = Class.new(Widget)

---@return Widget?
function MatchOverviewWidget:render()
	---@type MatchGroupUtilMatch
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
			['display'] = 'flex',
			['justify-content'] = 'space-between',
			['flex-direction'] = 'column',
			['align-items'] = 'center',
		},
		children = {
			HtmlWidgets.Span{
				children = OpponentDisplay.BlockOpponent{
					opponent = opponentToShow,
					overflow = 'ellipsis',
					teamStyle = 'icon',
				}
			},
			HtmlWidgets.Span{
				css = {
					['font-size'] = '0.8em',
				},
				children = leftOpponent.score .. ' - ' .. opponentToShow.score,
			},
		},
	}
end

return MatchOverviewWidget
