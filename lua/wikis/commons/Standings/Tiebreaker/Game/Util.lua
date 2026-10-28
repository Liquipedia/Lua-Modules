---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')

local StandingsOvertime = Lua.import('Module:Standings/Overtime')
local TiebreakerScope = Lua.import('Module:Standings/Tiebreaker/Scope')

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

---Every round of an opponent has the matches of the rounds before it, so the counts over its matches continue the
---counts of the round before, as long as the matches of the round before are the first matches of this round.
---@param opponent TiebreakerOpponent
---@return TiebreakerOpponent? previousRound # The round before, if its counts can be continued
---@return integer firstMatchIndex # Index of the first match that is not counted in the round before
function TiebreakerGameUtil.continuedRound(opponent)
	local previousRound = opponent.previousRound
	if not previousRound or #previousRound.matches > #opponent.matches then
		return nil, 1
	end
	for index, match in ipairs(previousRound.matches) do
		if opponent.matches[index] ~= match then
			return nil, 1
		end
	end
	return previousRound, #previousRound.matches + 1
end

local getPlayedGames
---@param opponent TiebreakerOpponent
---@return {games: integer, w: integer, l: integer, walkover: {w: integer, l: integer}?}
getPlayedGames = FnUtil.memoize(function (opponent)
	local previousRound, firstMatchIndex = TiebreakerGameUtil.continuedRound(opponent)
	local previous = previousRound and getPlayedGames(previousRound) or {games = 0, w = 0}
	local previousWalkover = previous.walkover or {}
	local games = previous.games
	local gameWins = previous.w
	local walkoverWins = previousWalkover.w or 0
	local walkoverLosses = previousWalkover.l or 0
	for index = firstMatchIndex, #opponent.matches do
		local match = opponent.matches[index]
		local matchOpponent = match.opponents[TiebreakerScope.opponentIndex(match, opponent.opponent)]
		local walkover = match.finished and TiebreakerGameUtil.getWalkoverResult(matchOpponent.status)
		if walkover == 'w' then
			walkoverWins = walkoverWins + 1
		elseif walkover == 'l' then
			walkoverLosses = walkoverLosses + 1
		elseif isScored(match) then
			for _, scoredOpponent in ipairs(match.opponents) do
				games = games + (scoredOpponent.score or 0)
			end
			gameWins = gameWins + (matchOpponent.score or 0)
		end
	end
	local gameLosses = games - gameWins

	return {
		games = games, w = gameWins, l = gameLosses,
		walkover = Logic.nilIfEmpty{
			w = walkoverWins > 0 and walkoverWins or nil,
			l = walkoverLosses > 0 and walkoverLosses or nil,
		}
	}
end)

---Games of the matches, walkovers count as `walkoverGames` games won by the winner and lost by the loser.
---@param opponent TiebreakerOpponent
---@param walkoverGames number? # Defaults to 0, so walkovers do not count towards the games
---@return {games: integer, w: integer, l: integer, walkover: {w: integer, l: integer}?}
function TiebreakerGameUtil.getGames(opponent, walkoverGames)
	local games = getPlayedGames(opponent)
	local walkover = games.walkover
	if not walkover or (walkoverGames or 0) == 0 then
		return games
	end
	local walkoverWins = (walkover.w or 0) * walkoverGames
	local walkoverLosses = (walkover.l or 0) * walkoverGames
	return {
		games = games.games + walkoverWins + walkoverLosses,
		w = games.w + walkoverWins,
		l = games.l + walkoverLosses,
		walkover = walkover,
	}
end

---Counts the games that went into overtime. Based on the played games of the matches, without walkovers.
---@param opponent TiebreakerOpponent
---@return {w: integer, l: integer}
TiebreakerGameUtil.getOvertimeGames = FnUtil.memoize(function (opponent)
	local previousRound, firstMatchIndex = TiebreakerGameUtil.continuedRound(opponent)
	local previous = previousRound and TiebreakerGameUtil.getOvertimeGames(previousRound) or {w = 0, l = 0}
	local overtimeWins = previous.w
	local overtimeLosses = previous.l
	for index = firstMatchIndex, #opponent.matches do
		local match = opponent.matches[index]
		if isScored(match) then
			local opponentIndex = TiebreakerScope.opponentIndex(match, opponent.opponent)
			for _, game in ipairs(match.games) do
				if StandingsOvertime.isOvertimeGame(game) then
					if game.winner == opponentIndex then
						overtimeWins = overtimeWins + 1
					else
						overtimeLosses = overtimeLosses + 1
					end
				end
			end
		end
	end

	return {w = overtimeWins, l = overtimeLosses}
end)

return TiebreakerGameUtil
