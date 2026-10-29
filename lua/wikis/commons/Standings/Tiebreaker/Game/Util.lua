---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local StandingsOvertime = Lua.import('Module:Standings/Overtime')
local TiebreakerMatchCounter = Lua.import('Module:Standings/Tiebreaker/MatchCounter')

local TiebreakerGameUtil = {}

local WALKOVER_WIN_STATUS = 'W'
local WALKOVER_LOSS_STATUSES = {FF = true, DQ = true, L = true}

---Walkover result of an opponent of a match or game, a W status is a win and FF, DQ and L are losses.
---@param status string?
---@return 'w'|'l'|nil
function TiebreakerGameUtil.getWalkoverResult(status)
	if status == WALKOVER_WIN_STATUS then
		return 'w'
	elseif WALKOVER_LOSS_STATUSES[status] then
		return 'l'
	end
end

---Whether all opponents of the match have a score, otherwise the match has no games,
---e.g. upcoming matches or draws without a score.
---@param match MatchGroupUtilMatch
---@return boolean
local function isScored(match)
	for _, matchOpponent in ipairs(match.opponents) do
		if matchOpponent.status ~= 'S' then
			return false
		end
	end
	return true
end

---@type fun(opponent: TiebreakerOpponent): {games: integer, w: integer, walkover: {w: integer, l: integer}}
local countPlayedGames = TiebreakerMatchCounter.create(
	{games = 0, w = 0, walkover = {w = 0, l = 0}},
	function (counts, match, opponentIndex)
		local matchOpponent = match.opponents[opponentIndex]
		local walkover = match.finished and TiebreakerGameUtil.getWalkoverResult(matchOpponent.status)
		if walkover then
			counts.walkover[walkover] = counts.walkover[walkover] + 1
		elseif isScored(match) then
			for _, scoredOpponent in ipairs(match.opponents) do
				counts.games = counts.games + (scoredOpponent.score or 0)
			end
			counts.w = counts.w + (matchOpponent.score or 0)
		end
	end
)

---Games of the matches, walkovers count as `walkoverGames` games won by the winner and lost by the loser.
---@param opponent TiebreakerOpponent
---@param walkoverGames number? # Defaults to 0, so walkovers do not count towards the games
---@return {games: integer, w: integer, l: integer}
function TiebreakerGameUtil.getGames(opponent, walkoverGames)
	local counts = countPlayedGames(opponent)
	local walkoverWins = counts.walkover.w * (walkoverGames or 0)
	local walkoverLosses = counts.walkover.l * (walkoverGames or 0)
	return {
		games = counts.games + walkoverWins + walkoverLosses,
		w = counts.w + walkoverWins,
		l = counts.games - counts.w + walkoverLosses,
	}
end

---Counts the games that went into overtime. Based on the played games of the matches, without walkovers.
---@type fun(opponent: TiebreakerOpponent): {w: integer, l: integer}
TiebreakerGameUtil.getOvertimeGames = TiebreakerMatchCounter.create(
	{w = 0, l = 0},
	function (counts, match, opponentIndex)
		if not isScored(match) then
			return
		end
		for _, game in ipairs(match.games) do
			if StandingsOvertime.isOvertimeGame(game) then
				local result = game.winner == opponentIndex and 'w' or 'l'
				counts[result] = counts[result] + 1
			end
		end
	end
)

return TiebreakerGameUtil
