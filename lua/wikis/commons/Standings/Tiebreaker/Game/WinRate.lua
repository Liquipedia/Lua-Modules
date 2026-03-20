---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/WinRate
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local MathUtil = Lua.import('Module:MathUtil')

local AbstractGameTiebreaker = Lua.import('Module:Standings/Tiebreaker/Game')
local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')

---@class TiebreakerGameWinRate : AbstractGameTiebreaker
local TiebreakerGameWinRate = Class.new(AbstractGameTiebreaker)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerGameWinRate:valueOf(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent)
	if not games.walkover or not self:isWalkoverCoefficientDefined() then
		return games.games == 0 and 0.5 or (games.w / games.games)
	end
	local walkoverGames = self:calculateWalkoverValues(games.walkover)
	local totalGames = games.games + walkoverGames.w + walkoverGames.l
	return (games.w + walkoverGames.w) / totalGames
end

---@return string
function TiebreakerGameWinRate:headerTitle()
	return 'Game Win %'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerGameWinRate:display(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent)
	if games == 0 then
		return '-'
	end
	return MathUtil.formatPercentage(self:valueOf(state, opponent), 2)
end

return TiebreakerGameWinRate
