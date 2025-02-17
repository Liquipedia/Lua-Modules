---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:OpponentDisplay/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Opponent = Lua.import('Module:Opponent')
local OpponentDisplay = Lua.import('Module:OpponentDisplay')

local CustomOpponentDisplay = Table.deepCopy(OpponentDisplay)

CustomOpponentDisplay.BracketOpponentEntry = Class.new(OpponentDisplay.BracketOpponentEntry, function(self) end)

---@class RocketLeagueStandardOpponent:standardOpponent
---@field extradata table?

---@param opponent RocketLeagueStandardOpponent
function CustomOpponentDisplay.BracketOpponentEntry:addScores(opponent)
	local extradata = opponent.extradata or {}
	if not extradata.additionalScores then
		OpponentDisplay.BracketOpponentEntry.addScores(self, opponent)
		return
	end

	local score1Node = OpponentDisplay.BracketScore({
		isWinner = extradata.set1win,
		scoreText = CustomOpponentDisplay.InlineScoreSpecial{
			opponent = opponent, score = extradata.score1
		},
	})
	self.root:node(score1Node)

	local score2Node
	if extradata.score2 or opponent.score2 then
		score2Node = OpponentDisplay.BracketScore({
			isWinner = extradata.set2win,
			scoreText = CustomOpponentDisplay.InlineScoreSpecial{
				opponent = opponent, score = extradata.score2
			},
		})
	end
	self.root:node(score2Node)

	local score3Node
	if extradata.score3 then
		score3Node = OpponentDisplay.BracketScore({
			isWinner = extradata.set3win,
			scoreText = CustomOpponentDisplay.InlineScoreSpecial{
				opponent = opponent, score = extradata.score3
			},
		})
	end
	self.root:node(score3Node)

	if (opponent.placement2 or opponent.placement or 0) == 1
		or opponent.advances then
		self.content:addClass('brkts-opponent-win')
	end
end

---@param opponent RocketLeagueStandardOpponent
function CustomOpponentDisplay.BracketOpponentEntry:createPlayers(opponent)
	local playerNode = OpponentDisplay.BlockPlayers({
		opponent = opponent,
		overflow = 'ellipsis',
		showLink = true,
	})
	self.content:node(playerNode)
end

---Displays a score or status of the opponent, as a string.
---@param props {opponent: RocketLeagueStandardOpponent, status: string?, score: number?}
---@return number|string
function CustomOpponentDisplay.InlineScoreSpecial(props)
	if props.score == -1 then
		return ''
	end
	if props.score == 0 and Opponent.isTbd(props.opponent) then
		return ''
	end
	return tostring(props.score)
end

return Class.export(CustomOpponentDisplay)
