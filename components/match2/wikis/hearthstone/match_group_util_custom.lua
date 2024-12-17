---
-- @Liquipedia
-- wiki=hearthstone
-- page=Module:MatchGroup/Util/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
-- can not use `Module:OpponentLibraries`/`Module:Opponent/Custom` to avoid loop
local Opponent = Lua.import('Module:Opponent')

local CustomMatchGroupUtil = Table.deepCopy(MatchGroupUtil)

---@class HearthstoneMatchGroupUtilSubmatch
---@field games MatchGroupUtilGame[]
---@field opponents GameOpponent[]
---@field resultType ResultType
---@field scores table<number, number>
---@field subgroup number
---@field walkover WalkoverType
---@field winner number?
---@field header string?

---@class HearthstoneMatchGroupUtilMatch: MatchGroupUtilMatch
---@field submatches StormgateMatchGroupUtilSubmatch[]?
---@field isTeamMatch boolean

---@param record table
---@return HearthstoneMatchGroupUtilMatch
function CustomMatchGroupUtil.matchFromRecord(record)
	local match = MatchGroupUtil.matchFromRecord(record) --[[@as HearthstoneMatchGroupUtilMatch]]

	-- Adjust game.opponents by looking up game.opponents.players in match.opponents
	Array.forEach(match.games, function(game)
		game.opponents = CustomMatchGroupUtil.computeGameOpponents(game, match.opponents)
	end)

	match.isTeamMatch = Array.any(match.opponents, function(opponent)
		return opponent.type == Opponent.team end
	)

	if match.isTeamMatch then
		-- Compute submatches
		match.submatches = Array.map(
			CustomMatchGroupUtil.groupBySubmatch(match.games),
			function(games) return CustomMatchGroupUtil.constructSubmatch(games) end
		)

		local extradata = match.extradata
		---@cast extradata table
		Array.forEach(match.submatches, function (submatch)
			submatch.header = Table.extract(extradata, 'subgroup' .. submatch.subgroup .. 'header')
		end)
	end

	return match
end

---@param game MatchGroupUtilGame
---@param matchOpponents standardOpponent[]
---@return table[]
function CustomMatchGroupUtil.computeGameOpponents(game, matchOpponents)
	return Array.map(game.opponents, function (opponent, opponentIndex)
		return Table.merge(opponent, {
			players = Array.map(game.opponents[opponentIndex].players or {}, function (player, playerIndex)
				if Logic.isEmpty(player) then return nil end
				return Table.merge(matchOpponents[opponentIndex].players[playerIndex] or {}, player)
			end)
		})
	end)
end

---Group games on the subgroup field to form submatches
---@param matchGames MatchGroupUtilGame[]
---@return MatchGroupUtilGame[][]
function CustomMatchGroupUtil.groupBySubmatch(matchGames)
	-- Group games on adjacent subgroups
	local previousSubgroup = nil
	local currentGames = nil
	local submatchGames = {}
	Array.forEach(matchGames, function (game)
		if previousSubgroup == nil or previousSubgroup ~= game.subgroup then
			currentGames = {}
			table.insert(submatchGames, currentGames)
			previousSubgroup = game.subgroup
		end
		---@cast currentGames -nil
		table.insert(currentGames, game)
	end)
	return submatchGames
end

---Constructs a submatch object whose properties are aggregated from that of its games.
---@param games MatchGroupUtilGame[]
---@return HearthstoneMatchGroupUtilSubmatch
function CustomMatchGroupUtil.constructSubmatch(games)
	local opponents = Table.deepCopy(games[1].opponents)

	-- Sum up scores
	local scores = {}
	Array.forEach(opponents, function (_, opponentIndex)
		scores[opponentIndex] = 0
	end)

	Array.forEach(games, function (game)
		if game.map and String.startsWith(game.map, 'Submatch') and not game.resultType then
			Array.forEach(scores, function (score, index)
				scores[index] = score + (tonumber(game.scores[index]) or 0)
			end)
		elseif game.winner then
			scores[game.winner] = (scores[game.winner] or 0) + 1
		end
	end)

	-- Compute winner if all games have been played, skipped, or defaulted
	local allPlayed = Array.all(games, function(game)
		return game.winner ~= nil or game.resultType ~= nil
	end)

	local resultType = nil
	local winner = nil
	if allPlayed then
		local diff = (scores[1] or 0) - (scores[2] or 0)
		if diff < 0 then
			winner = 2
		elseif diff == 0 then
			resultType = 'draw'
		else
			winner = 1
		end
	end

	-- Set resultType and walkover if every game is a walkover
	local walkovers = {}
	local resultTypes = {}
	Array.forEach(games, function (game)
		resultTypes[game.resultType or ''] = true
		walkovers[game.walkover or ''] = true
	end)
	local walkover
	local uniqueResult = Table.uniqueKey(resultTypes)
	if uniqueResult == 'default' then
		resultType = 'default'
		walkover = String.nilIfEmpty(Table.uniqueKey(walkovers)) or 'L'
	elseif uniqueResult == 'np' then
		resultType = 'np'
	end

	return {
		games = games,
		opponents = opponents,
		resultType = resultType,
		scores = scores,
		subgroup = games[1].subgroup,
		walkover = walkover,
		winner = winner,
	}
end

return CustomMatchGroupUtil
