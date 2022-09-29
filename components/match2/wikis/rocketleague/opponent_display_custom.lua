---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:OpponentDisplay/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})

local CustomOpponentDisplay = {propTypes = {}, types = {}}

CustomOpponentDisplay.BracketOpponentEntry = Class.new(OpponentDisplay.BracketOpponentEntry, function(self) end)

function CustomOpponentDisplay.BracketOpponentEntry:addScores(opponent)
	local extradata = opponent.extradata or {}
	if not extradata.additionalScores then
		OpponentDisplay.BracketOpponentEntry.addScores(self, opponent)
	else
		local score1Node = OpponentDisplay.BracketScore({
			isWinner = extradata.set1win,
			scoreText = OpponentDisplay.InlineScore(opponent),
		})
		self.root:node(score1Node)

		local score2Node
		if opponent.extradata.score2 or opponent.score2 then
			score2Node = OpponentDisplay.BracketScore({
				isWinner = extradata.set2win,
				scoreText = CustomOpponentDisplay.InlineScore2(opponent),
			})
		end
		self.root:node(score2Node)

		local score3Node
		if opponent.extradata.score3 then
			score3Node = OpponentDisplay.BracketScore({
				isWinner = extradata.set3win,
				scoreText = CustomOpponentDisplay.InlineScore3(opponent),
			})
		end
		self.root:node(score3Node)

		if (opponent.placement2 or opponent.placement or 0) == 1
			or opponent.advances then
			self.content:addClass('brkts-opponent-win')
		end
	end
end

--[[
Displays the second score or status of the opponent, as a string.
]]
function CustomOpponentDisplay.InlineScore2(opponent)
	local score2 = opponent.extradata.score2
	if opponent.status2 == 'S' then
		if opponent.score2 == 0 and Opponent.isTbd(opponent) then
			return ''
		else
			return opponent.score2 ~= -1 and tostring(opponent.score2) or ''
		end
	else
		return opponent.status2 or score2 or ''
	end
end

--[[
Displays the third score or status of the opponent, as a string.
]]
function CustomOpponentDisplay.InlineScore3(opponent)
	local score3 = opponent.extradata.score3
	if opponent.status3 == 'S' then
		if opponent.score3 == 0 and Opponent.isTbd(opponent) then
			return ''
		else
			return opponent.score3 ~= -1 and tostring(opponent.score3) or ''
		end
	else
		return opponent.status3 or score3 or ''
	end
end

return Class.export(CustomOpponentDisplay)
