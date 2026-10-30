---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Wins
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerMatchScore = Lua.import('Module:Standings/Tiebreaker/Match/Score')
local TiebreakerMatchUtil = Lua.import('Module:Standings/Tiebreaker/Match/Util')

---Shares the column of TiebreakerMatchScore
---@class TiebreakerMatchWins : TiebreakerMatchScore
local TiebreakerMatchWins = Class.new(TiebreakerMatchScore)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchWins:valueOf(state, opponent)
	return TiebreakerMatchUtil.getMatches(opponent).w
end

return TiebreakerMatchWins
