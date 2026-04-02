---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Diff
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local AbstractGameTiebreaker = Lua.import('Module:Standings/Tiebreaker/Game')
local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')

---@class TiebreakerGameDiff : AbstractGameTiebreaker
local TiebreakerGameDiff = Class.new(AbstractGameTiebreaker)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerGameDiff:valueOf(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent)
	if not games.walkover or not self:isWalkoverCoefficientDefined() then
		return games.w - games.l
	end
	local walkoverGames = self:calculateWalkoverValues(games.walkover)
	return (games.w + walkoverGames.w) - (games.l + walkoverGames.l)
end

---@return string
function TiebreakerGameDiff:headerTitle()
	return 'Games'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerGameDiff:display(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent)
	if not games.walkover or not self:isWalkoverCoefficientDefined() then
		return games.w .. ' - ' .. games.l
	end
	local walkoverGames = self:calculateWalkoverValues(games.walkover)
	return (games.w + walkoverGames.w) .. ' - ' .. (games.l + walkoverGames.l)
end

return TiebreakerGameDiff
