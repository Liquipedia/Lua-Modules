---
-- @Liquipedia
-- page=Module:OpponentDisplay/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Opponent = Lua.import('Module:Opponent')
local OpponentDisplay = Lua.import('Module:OpponentDisplay')

local OpponentDisplayCustom = Table.deepCopy(OpponentDisplay)

local SCORE_STATUS = 'S'
local NO_SCORE = -1
local ZERO_SCORE = 0

OpponentDisplayCustom.BracketOpponentEntry = Class.new(OpponentDisplay.BracketOpponentEntry)

---@class TrackmaniaStandardOpponent:standardOpponent
---@field score3 number?
---@field status3 string?
---@field extradata table?

---@param opponent TrackmaniaStandardOpponent
function OpponentDisplayCustom.BracketOpponentEntry:addScores(opponent)
	local extradata = opponent.extradata or {}
	if not extradata.additionalScores then
		OpponentDisplay.BracketOpponentEntry.addScores(self, opponent)
		return
	end
	self.root:node(OpponentDisplay.BracketScore{
		isWinner = extradata.set1win,
		scoreText = OpponentDisplayCustom.InlineScore(opponent, 1),
	})
	if opponent.extradata.score2 or opponent.score2 then
		self.root:node(OpponentDisplay.BracketScore{
			isWinner = extradata.set2win,
			scoreText = OpponentDisplayCustom.InlineScore(opponent, 2),
		})
	end
	if opponent.extradata.score3 then
		self.root:node(OpponentDisplay.BracketScore{
			isWinner = extradata.set3win,
			scoreText = OpponentDisplayCustom.InlineScore(opponent, 3)
		})
	end
	if (opponent.placement2 or opponent.placement or 0) == 1
		or opponent.advances then
		self.content:addClass('brkts-opponent-win')
	end
end

---@param opponent TrackmaniaStandardOpponent
---@param scoreIndex integer|string
---@return number|string
function OpponentDisplayCustom.InlineScore(opponent, scoreIndex)
	scoreIndex = scoreIndex or ''
	local status = opponent['status' .. scoreIndex] or opponent.extradata['status' .. scoreIndex]
	local score = tonumber(opponent['score' .. scoreIndex] or opponent.extradata['score' .. scoreIndex])

	if Logic.isNotEmpty(status) and status ~= SCORE_STATUS then
		return status
	end

	score = score or 0
	if (score == ZERO_SCORE and Opponent.isTbd(opponent)) or score == NO_SCORE then
		return ''
	end

	return score
end

return OpponentDisplayCustom
