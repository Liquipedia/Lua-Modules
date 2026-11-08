---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Losses
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')
local TiebreakerGameScore = Lua.import('Module:Standings/Tiebreaker/Game/Score')

---Shares the column of TiebreakerGameScore
---@class TiebreakerGameLosses : TiebreakerGameScore
local TiebreakerGameLosses = Class.new(TiebreakerGameScore)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerGameLosses:valueOf(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent, self.options.walkoverGames)
	return -games.l
end

return TiebreakerGameLosses
