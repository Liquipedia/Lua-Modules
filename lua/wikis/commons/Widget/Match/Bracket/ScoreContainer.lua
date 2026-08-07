---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/ScoreContainer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local OpponentDisplay = Lua.import('Module:OpponentDisplay')

local BracketScoreDisplay = Lua.import('Module:Widget/Match/Bracket/Score')
local Component = Lua.import('Module:Widget/Component')

---@param props {opponent: standardOpponent}
---@return VNode[]
local function BracketScoreContainer(props)
	local opponent = props.opponent
	return {
		BracketScoreDisplay{
			isWinner = opponent.placement == 1 or opponent.advances,
			scoreText = OpponentDisplay.InlineScore(opponent),
		},
		opponent.placement2 and BracketScoreDisplay{
			isWinner = opponent.placement2 == 1,
			scoreText = OpponentDisplay.InlineScore2(opponent),
		} or nil,
	}
end

return Component.component(BracketScoreContainer)
