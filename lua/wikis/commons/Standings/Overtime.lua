---
-- @Liquipedia
-- page=Module:Standings/Overtime
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')

local StandingsOvertime = {}

---@class StandingsMatch: MatchGroupUtilMatch
---@field regulationRounds integer? # Resolved when imported, see `StandingsOvertime.regulationRounds`

---Number of rounds a game has in regulation. A table input overrides the wiki config.
---@param override integer?
---@return integer?
function StandingsOvertime.regulationRounds(override)
	return override or ((Info.config.standings or {}).overtime or {}).regulationRounds
end

---@param match MatchGroupUtilMatch|StandingsMatch
---@return integer?
function StandingsOvertime.matchRegulationRounds(match)
	return match.regulationRounds or StandingsOvertime.regulationRounds()
end

---A game went into overtime if more rounds were played than fit into regulation.
---@param game MatchGroupUtilGame
---@param regulationRounds integer?
---@return boolean
function StandingsOvertime.isOvertimeGame(game, regulationRounds)
	if not regulationRounds then
		return false
	end

	if Logic.isEmpty(game.winner) or game.status == 'notplayed' then
		return false
	end

	return MathUtil.sum(game.scores or {}) > regulationRounds
end

---A Bo1 match went into overtime if its game did. Overtime standings only support Bo1 matches.
---@param match MatchGroupUtilMatch|StandingsMatch
---@return boolean
function StandingsOvertime.isOvertimeMatch(match)
	local game = match.games[1]
	return game ~= nil and StandingsOvertime.isOvertimeGame(game, StandingsOvertime.matchRegulationRounds(match))
end

return StandingsOvertime
