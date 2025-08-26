---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Match/Count
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')
local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerGameCount : StandingsTiebreaker
local TiebreakerGameCount = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerGameCount:valueOf(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent)
	return games.games
end

---@return string
function TiebreakerGameCount:headerTitle()
	return 'Games Played'
end

return TiebreakerGameCount
