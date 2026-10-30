---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Draws
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerMatchScore = Lua.import('Module:Standings/Tiebreaker/Match/Score')

---Shares the column of TiebreakerMatchScore
---@class TiebreakerMatchDraws : TiebreakerMatchScore
local TiebreakerMatchDraws = Class.new(TiebreakerMatchScore)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerMatchDraws:valueOf(state, opponent)
	return opponent.match.d
end

return TiebreakerMatchDraws
