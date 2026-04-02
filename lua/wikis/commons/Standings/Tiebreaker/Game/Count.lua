---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Count
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local AbstractGameTiebreaker = Lua.import('Module:Standings/Tiebreaker/Game')
local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')

---@class TiebreakerGameCount : AbstractGameTiebreaker
local TiebreakerGameCount = Class.new(AbstractGameTiebreaker)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerGameCount:valueOf(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent)
	if not games.walkover or not self:isWalkoverCoefficientDefined() then
		return games.games
	end
	local walkoverGames = self:calculateWalkoverValues(games.walkover)
	return games.games + (self:getWalkoverCoefficient() * (walkoverGames.w + walkoverGames.l))
end

---@return string
function TiebreakerGameCount:headerTitle()
	return 'Games Played'
end

return TiebreakerGameCount
