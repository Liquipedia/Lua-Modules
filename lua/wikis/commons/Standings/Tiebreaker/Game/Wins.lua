---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Wins
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')
local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerGameWins : StandingsTiebreaker
local TiebreakerGameWins = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerGameWins:valueOf(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent)
	return games.w
end

---@return string
function TiebreakerGameWins:headerTitle()
	return 'Games Won'
end

return TiebreakerGameWins
