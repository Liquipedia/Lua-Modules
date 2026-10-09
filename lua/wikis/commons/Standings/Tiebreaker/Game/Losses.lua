---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Losses
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')
local TiebreakerGameDiff = Lua.import('Module:Standings/Tiebreaker/Game/Diff')

---Shares the column of TiebreakerGameDiff
---@class TiebreakerGameLosses : TiebreakerGameDiff
local TiebreakerGameLosses = Class.new(TiebreakerGameDiff)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerGameLosses:valueOf(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent)
	return -games.l
end

return TiebreakerGameLosses
