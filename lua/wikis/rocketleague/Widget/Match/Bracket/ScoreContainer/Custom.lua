---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/ScoreContainer/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Opponent = Lua.import('Module:Opponent/Custom')

local BracketScoreContainer = Lua.import('Module:Widget/Match/Bracket/ScoreContainer')
local BracketScoreDisplay = Lua.import('Module:Widget/Match/Bracket/Score')
local Component = Lua.import('Module:Widget/Component')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@param props {opponent: standardOpponent}
---@return VNode[]
local function RocketLeagueBracketScoreContainer(props)
	local opponent = props.opponent
	local extradata = opponent.extradata or {}
	if not extradata.additionalScores then
		return BracketScoreContainer(props)
	end

	---Displays a score or status of the opponent, as a string.
	---@param score number?
	---@return string
	local function InlineScoreSpecial(score)
		if score == -1 then
			return ''
		elseif score == 0 and Opponent.isTbd(opponent) then
			return ''
		end
		return tostring(score)
	end

	return WidgetUtil.collect(
		BracketScoreDisplay{
			isWinner = extradata.set1win,
			scoreText = InlineScoreSpecial(extradata.score1),
		},
		(extradata.score2 or opponent.score2) and BracketScoreDisplay{
			isWinner = extradata.set2win,
			scoreText = InlineScoreSpecial(extradata.score2),
		} or nil,
		extradata.score3 and BracketScoreDisplay{
			isWinner = extradata.set3win,
			scoreText = InlineScoreSpecial(extradata.score3),
		} or nil
	)
end

return Component.component(RocketLeagueBracketScoreContainer)
