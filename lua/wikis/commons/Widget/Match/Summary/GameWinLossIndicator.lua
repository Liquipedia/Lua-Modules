---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/GameWinLossIndicator
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

local ICONS = {
	win = Div{classes = {'brkts-result-label', 'result--win'}},
	draw = Div{classes = {'brkts-result-label', 'result--draw'}},
	loss = Div{classes = {'brkts-result-label', 'result--loss'}},
	empty = Div{classes = {'brkts-result-label'}},
}

---@class MatchSummaryGameWinLossIndicator: Widget
---@operator call(table): MatchSummaryGameWinLossIndicator
local MatchSummaryGameWinLossIndicator = Class.new(Widget)

---@return Widget
function MatchSummaryGameWinLossIndicator:render()
	local winner = self.props.winner

	if winner == self.props.opponentIndex then
		return ICONS.win
	elseif winner == 0 then
		return ICONS.draw
	elseif Logic.isNotEmpty(winner) then
		return ICONS.loss
	end

	return ICONS.empty
end

return MatchSummaryGameWinLossIndicator
