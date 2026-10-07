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

---Number of rounds a game has in regulation, as configured per wiki.
---@return integer?
function StandingsOvertime.regulationRounds()
	return ((Info.config.standings or {}).overtime or {}).regulationRounds
end

---A game went into overtime if more rounds were played than fit into regulation.
---@param game MatchGroupUtilGame
---@return boolean
function StandingsOvertime.isOvertimeGame(game)
	local regulationRounds = StandingsOvertime.regulationRounds()
	if not regulationRounds then
		return false
	end

	if Logic.isEmpty(game.winner) or game.status == 'notplayed' then
		return false
	end

	return MathUtil.sum(game.scores or {}) > regulationRounds
end

---A Bo1 match went into overtime if its game did. Overtime standings only support Bo1 matches.
---@param match MatchGroupUtilMatch
---@return boolean
function StandingsOvertime.isOvertimeMatch(match)
	local game = match.games[1]
	return game ~= nil and StandingsOvertime.isOvertimeGame(game)
end

return StandingsOvertime
