---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Losses
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')
local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerGameLosses : StandingsTiebreaker
local TiebreakerGameLosses = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerGameLosses:valueOf(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent)
	return -games.l
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerGameLosses:display(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent)
	return tostring(games.l)
end

---@return string
function TiebreakerGameLosses:headerTitle()
	return 'Games Lost'
end

return TiebreakerGameLosses
