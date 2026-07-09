---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/GameWinLossIndicator
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Label = Lua.import('Module:Widget/Basic/Label')

local LABELS = {
	win = Label{labelType = 'result-win'},
	draw = Label{labelType = 'result-draw'},
	loss = Label{labelType = 'result-loss'},
	empty = Label{labelType = 'result-empty'},
}

---@param props {winner: integer?, opponentIndex: integer?}
---@return VNode
local function MatchSummaryGameWinLossIndicator(props)
	local winner = props.winner

	if winner == props.opponentIndex then
		return LABELS.win
	elseif winner == 0 then
		return LABELS.draw
	elseif Logic.isNotEmpty(winner) then
		return LABELS.loss
	end

	return LABELS.empty
end

return Component.component(MatchSummaryGameWinLossIndicator)
