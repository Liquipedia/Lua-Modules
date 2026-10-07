---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/DiffRegulation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')
local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerGameDiffRegulation : StandingsTiebreaker
local TiebreakerGameDiffRegulation = Class.new(TiebreakerInterface)

---Games won and lost, not counting the games that went into overtime.
---@param opponent TiebreakerOpponent
---@return {w: integer, l: integer}
local function getRegulationGames(opponent)
	local games = TiebreakerGameUtil.getGames(opponent)
	local overtimeGames = TiebreakerGameUtil.getOvertimeGames(opponent)
	return {w = games.w - overtimeGames.w, l = games.l - overtimeGames.l}
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerGameDiffRegulation:valueOf(state, opponent)
	local games = getRegulationGames(opponent)
	return games.w - games.l
end

---@return string
function TiebreakerGameDiffRegulation:headerTitle()
	return 'Games (Reg.)'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerGameDiffRegulation:display(state, opponent)
	local games = getRegulationGames(opponent)
	return games.w .. ' - ' .. games.l
end

return TiebreakerGameDiffRegulation
