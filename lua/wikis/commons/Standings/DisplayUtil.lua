---
-- @Liquipedia
-- page=Module:Standings/DisplayUtil
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local StandingsDisplayUtil = {}

---Returns the stats that get a column, skipping untitled and duplicate ones.
---Stats with the same title share a column (e.g. all match based stats show the match record),
---the column shows the first of them.
---@param standings StandingsModel
---@return StandingsAdditionalStat[]
function StandingsDisplayUtil.statsToShow(standings)
	local seenTitlesBefore = {}
	return Array.filter(standings.additionalStats, function(tiebreaker)
		if not tiebreaker.title then
			return false
		end
		if seenTitlesBefore[tiebreaker.title] then
			return false
		end
		seenTitlesBefore[tiebreaker.title] = true
		return true
	end)
end

---The title of the column to show in bold, the column of the first tiebreaker that has one.
---@param standings StandingsModel
---@return string?
function StandingsDisplayUtil.boldStatTitle(standings)
	local firstTiebreakerWithColumn = Array.find(standings.additionalStats, function(stat)
		return stat.tiebreaker == true and stat.title ~= nil
	end)
	return firstTiebreakerWithColumn and firstTiebreakerWithColumn.title or nil
end

---The number of the last round that has started, 0 if none has.
---@param standings StandingsModel
---@return integer
function StandingsDisplayUtil.lastStartedRound(standings)
	local startedRounds = Array.filter(standings.rounds, function(round) return round.started end)
	return (Array.maxBy(startedRounds, function(round) return round.round end) or {round = 0}).round
end

---The number of rounds to display: every started round, and the first round before any has started.
---@param standings StandingsModel
---@return integer
function StandingsDisplayUtil.roundsToShow(standings)
	return math.max(StandingsDisplayUtil.lastStartedRound(standings), 1)
end

---@param standings StandingsModel
---@return boolean
function StandingsDisplayUtil.hasFutureRounds(standings)
	return not standings.rounds[#standings.rounds].started
end

return StandingsDisplayUtil
