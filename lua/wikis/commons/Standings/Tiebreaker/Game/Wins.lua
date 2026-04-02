---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Wins
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local AbstractGameTiebreaker = Lua.import('Module:Standings/Tiebreaker/Game')
local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')

---@class TiebreakerGameWins : AbstractGameTiebreaker
local TiebreakerGameWins = Class.new(AbstractGameTiebreaker)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerGameWins:valueOf(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent)
	local walkoverGames = self:calculateWalkoverValues(games.walkover)
	return games.w + walkoverGames.w
end

---@return string
function TiebreakerGameWins:headerTitle()
	return 'Games Won'
end

return TiebreakerGameWins
