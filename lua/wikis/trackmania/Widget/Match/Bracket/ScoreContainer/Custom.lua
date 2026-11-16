---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/ScoreContainer/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')

local BracketScoreContainer = Lua.import('Module:Widget/Match/Bracket/ScoreContainer')
local BracketScoreDisplay = Lua.import('Module:Widget/Match/Bracket/Score')
local Component = Lua.import('Module:Widget/Component')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@param props {opponent: standardOpponent}
---@return VNode[]
local function TrackmaniaBracketScoreContainer(props)
	local opponent = props.opponent
	local extradata = opponent.extradata or {}
	if not extradata.additionalScores then
		return BracketScoreContainer(props)
	end

	---@param scoreIndex integer|string
	---@return number|string
	local function InlineScoreSpecial(scoreIndex)
		scoreIndex = scoreIndex or ''
		local status = opponent['status' .. (
			scoreIndex == 1 and '' or scoreIndex
		)] or opponent.extradata['status' .. scoreIndex]
		local score = tonumber(opponent['score' .. scoreIndex] or opponent.extradata['score' .. scoreIndex])

		if Logic.isNotEmpty(status) and status ~= 'S' then
			return status
		end

		score = score or 0
		if (score == 0 and Opponent.isTbd(opponent)) or score == -1 then
			return ''
		end

		return score
	end

	return WidgetUtil.collect(
		BracketScoreDisplay{
			isWinner = extradata.set1win,
			scoreText = InlineScoreSpecial(1),
		},
		(extradata.score2 or opponent.score2) and BracketScoreDisplay{
			isWinner = extradata.set2win,
			scoreText = InlineScoreSpecial(2),
		} or nil,
		extradata.score3 and BracketScoreDisplay{
			isWinner = extradata.set3win,
			scoreText = InlineScoreSpecial(3),
		} or nil
	)
end

return Component.component(TrackmaniaBracketScoreContainer)
