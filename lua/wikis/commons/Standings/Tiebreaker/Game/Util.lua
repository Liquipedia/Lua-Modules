---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')

local StandingsOvertime = Lua.import('Module:Standings/Overtime')

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

---@param opponent TiebreakerOpponent
---@return {games: integer, w: integer, l: integer, walkover: {w: integer, l: integer}?}
local getPlayedGames = FnUtil.memoize(function (opponent)
	local games = 0
	local gameWins = 0
	local walkoverWins = 0
	local walkoverLosses = 0
	Array.forEach(opponent.matches, function (match)
		local opponentIndex = Array.indexOf(match.opponents, FnUtil.curry(Opponent.same, opponent.opponent))

		local walkover = match.finished and TiebreakerGameUtil.getWalkoverResult(match.opponents[opponentIndex].status)
		if walkover == 'w' then
			walkoverWins = walkoverWins + 1
			return
		elseif walkover == 'l' then
			walkoverLosses = walkoverLosses + 1
			return
		end
		-- Other results without a score, e.g. upcoming matches or draws without a score, have no games
		if Array.any(match.opponents, function (matchOpponent)
			return matchOpponent.status ~= 'S'
		end) then
			return
		end
		games = games + Array.reduce(Array.map(match.opponents, Operator.property('score')), Operator.nilSafeAdd)
		gameWins = gameWins + (match.opponents[opponentIndex].score or 0)
	end)
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
---@return {games: integer, w: integer, d: integer, l: integer, walkover: {w: integer, l: integer}?}
function TiebreakerGameUtil.getGames(opponent, walkoverGames)
	local games = getPlayedGames(opponent)
	local walkover = games.walkover or {}
	local adjustment = opponent.gameAdjustment or {}
	local wins = games.w + (walkover.w or 0) * (walkoverGames or 0) + (adjustment.w or 0)
	local draws = adjustment.d or 0
	local losses = games.l + (walkover.l or 0) * (walkoverGames or 0) + (adjustment.l or 0)
	return {
		games = wins + draws + losses,
		w = wins,
		d = draws,
		l = losses,
		walkover = games.walkover,
	}
end

---Counts the games that went into overtime. Based on the played games of the matches, without walkovers.
---@param opponent TiebreakerOpponent
---@return {w: integer, l: integer}
TiebreakerGameUtil.getOvertimeGames = FnUtil.memoize(function (opponent)
	local overtimeWins = 0
	local overtimeLosses = 0
	Array.forEach(opponent.matches, function (match)
		local opponentIndex = Array.indexOf(match.opponents, FnUtil.curry(Opponent.same, opponent.opponent))

		if Array.any(match.opponents, function (matchOpponent)
			return matchOpponent.status ~= 'S'
		end) then
			return
		end

		Array.forEach(Array.filter(match.games, StandingsOvertime.isOvertimeGame), function (game)
			if game.winner == opponentIndex then
				overtimeWins = overtimeWins + 1
			else
				overtimeLosses = overtimeLosses + 1
			end
		end)
	end)

	return {w = overtimeWins, l = overtimeLosses}
end)

return TiebreakerGameUtil
