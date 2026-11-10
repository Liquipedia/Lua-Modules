---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Wins
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')
local TiebreakerGameScore = Lua.import('Module:Standings/Tiebreaker/Game/Score')

---Shares the column of TiebreakerGameScore
---@class TiebreakerGameWins : TiebreakerGameScore
local TiebreakerGameWins = Class.new(TiebreakerGameScore)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerGameWins:valueOf(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent, self.options.walkoverGames)
	return games.w
end

return TiebreakerGameWins
