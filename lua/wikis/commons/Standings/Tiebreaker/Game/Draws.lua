---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Draws
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')
local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerGameDraws : StandingsTiebreaker
local TiebreakerGameDraws = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerGameDraws:valueOf(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent)
	return games.d
end

---@return string
function TiebreakerGameDraws:headerTitle()
	return 'Games Drawn'
end

return TiebreakerGameDraws
