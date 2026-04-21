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
local Label = Lua.import('Module:Widget/Basic/Label')

local LABELS = {
	win = Label{labelType = 'result-win'},
	draw = Label{labelType = 'result-draw'},
	loss = Label{labelType = 'result-loss'},
	empty = Label{labelType = 'result-empty'},
}

---@class MatchSummaryGameWinLossIndicator: Widget
---@operator call(table): MatchSummaryGameWinLossIndicator
local MatchSummaryGameWinLossIndicator = Class.new(Widget)

---@return Widget
function MatchSummaryGameWinLossIndicator:render()
	local winner = self.props.winner

	if winner == self.props.opponentIndex then
		return LABELS.win
	elseif winner == 0 then
		return LABELS.draw
	elseif Logic.isNotEmpty(winner) then
		return LABELS.loss
	end

	return LABELS.empty
end

return MatchSummaryGameWinLossIndicator
