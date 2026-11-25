---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Count
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerGameScore = Lua.import('Module:Standings/Tiebreaker/Game/Score')
local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')

---Shares the column of TiebreakerGameScore
---@class TiebreakerGameCount : TiebreakerGameScore
local TiebreakerGameCount = Class.new(TiebreakerGameScore)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerGameCount:valueOf(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent, self.options.walkoverGames)
	return games.games
end

return TiebreakerGameCount
