---
-- @Liquipedia
-- page=Module:MatchGroup/Util/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Faction = require('Module:Faction')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local TEAM_DISPLAY_MODE = 'team'
local UNIFORM_DISPLAY_MODE = 'uniform'
local SCORE_STATUS = MatchGroupInputUtil.STATUS.SCORE

local CustomMatchGroupUtil = Table.deepCopy(MatchGroupUtil)

---@class WarcraftMatchGroupUtilGamePlayer: WarcraftStandardPlayer
---@field matchplayerIndex integer
---@field heroes string[]?
---@field position integer
---@field random boolean

---@class WarcraftMatchGroupUtilGameOpponent:GameOpponent
---@field placement number?
---@field players WarcraftMatchGroupUtilGamePlayer[]
---@field score number?

---@class WarcraftMatchGroupUtilGame: MatchGroupUtilGame
---@field opponents WarcraftMatchGroupUtilGameOpponent[]
---@field offfactions table<integer, string[]>?

---@class WarcraftMatchGroupUtilVeto
---@field by number?
---@field map string

---@class WarcraftMatchGroupUtilSubmatch
---@field games WarcraftMatchGroupUtilGame[]
---@field mode string
---@field opponents WarcraftMatchGroupUtilGameOpponent[]
---@field status string?
---@field subgroup number
---@field winner number?
---@field header string?

---@class WarcraftMatchGroupUtilMatch: MatchGroupUtilMatch
---@field games WarcraftMatchGroupUtilGame[]
---@field opponentMode 'uniform'|'team'
---@field opponents WarcraftStandardOpponent[]
---@field vetoes WarcraftMatchGroupUtilVeto[]
---@field submatches WarcraftMatchGroupUtilSubmatch[]?
---@field casters string?

---@param record table
---@return WarcraftMatchGroupUtilMatch
function CustomMatchGroupUtil.matchFromRecord(record)
	local match = MatchGroupUtil.matchFromRecord(record) --[[@as WarcraftMatchGroupUtilMatch]]

	-- Add additional fields to opponents
	CustomMatchGroupUtil.populateOpponents(match)

	-- Adjust game.opponents by looking up game.opponents.players in match.opponents
	Array.forEach(match.games, function(game)
		game.opponents = CustomMatchGroupUtil.computeGameOpponents(game, match.opponents)
	end)

	-- Determine whether the match is a team match with different players each game
	match.opponentMode = Array.any(match.opponents, function(opponent) return opponent.type == Opponent.team end)
		and TEAM_DISPLAY_MODE or UNIFORM_DISPLAY_MODE

	local extradata = match.extradata
	---@cast extradata table
	if match.opponentMode == TEAM_DISPLAY_MODE then
		-- Compute submatches
		match.submatches = Array.map(
			CustomMatchGroupUtil.groupBySubmatch(match.games),
			function(games) return CustomMatchGroupUtil.constructSubmatch(games, match) end
		)
	end

	-- Add vetoes
	match.vetoes = {}
	for vetoIndex = 1, math.huge do
		local map = Table.extract(extradata, 'veto' .. vetoIndex)
		local by = tonumber(Table.extract(extradata, 'veto' .. vetoIndex .. 'by'))
		if not map then break end

		table.insert(match.vetoes, {map = map, by = by})
	end

	return match
end

---Move additional fields from extradata to struct
---@param match WarcraftMatchGroupUtilMatch
function CustomMatchGroupUtil.populateOpponents(match)
	local opponents = match.opponents

	for _, opponent in ipairs(opponents) do
		opponent.placement2 = tonumber(Table.extract(opponent.extradata, 'placement2'))
		opponent.score2 = tonumber(Table.extract(opponent.extradata, 'score2'))
		opponent.status2 = opponent.score2 and SCORE_STATUS or nil

		for _, player in ipairs(opponent.players) do
			player.faction = Table.extract(player.extradata, 'faction') or Faction.defaultFaction
		end
	end

	if #opponents == 2 and opponents[1].score2 and opponents[2].score2 then
		local scoreDiff = opponents[1].score2 - opponents[2].score2
		opponents[1].placement2 = scoreDiff > 0 and 1 or 2
		opponents[2].placement2 = scoreDiff < 0 and 1 or 2
	end
end


---@param game WarcraftMatchGroupUtilGame
---@param matchOpponents WarcraftStandardOpponent[]
---@return WarcraftMatchGroupUtilGameOpponent[]
function CustomMatchGroupUtil.computeGameOpponents(game, matchOpponents)
	return Array.map(game.opponents, function(mapOpponent, opponentIndex)
		local players = Array.map(mapOpponent.players or {}, function(player, playerIndex)
			if Logic.isEmpty(player) then return end
			local matchPlayer = (matchOpponents[opponentIndex].players or {})[playerIndex] or {}
			return Table.merge({displayName = 'TBD'}, matchPlayer, {
				faction = player.faction,
				position = tonumber(player.position),
				heroes = player.heroes,
				random = player.random,
				matchPlayerIndex = playerIndex,
			})
		end)

		return Table.merge(mapOpponent, {players = players})
	end)
end

---Group games on the subgroup field to form submatches
---@param matchGames WarcraftMatchGroupUtilGame[]
---@return WarcraftMatchGroupUtilGame[][]
function CustomMatchGroupUtil.groupBySubmatch(matchGames)
	-- Group games on adjacent subgroups
	local previousSubgroup = nil
	local currentGames = nil
	local submatchGames = {}
	for _, game in ipairs(matchGames) do
		if previousSubgroup == nil or previousSubgroup ~= game.subgroup then
			currentGames = {}
			table.insert(submatchGames, currentGames)
			previousSubgroup = game.subgroup
		end
		---@cast currentGames -nil
		table.insert(currentGames, game)
	end
	return submatchGames
end

---Constructs a submatch object whose properties are aggregated from that of its games.
---@param games WarcraftMatchGroupUtilGame[]
---@param match WarcraftMatchGroupUtilMatch
---@return WarcraftMatchGroupUtilSubmatch
function CustomMatchGroupUtil.constructSubmatch(games, match)
	local firstGame = games[1]
	local opponents = Table.deepCopy(firstGame.opponents)
	local isSubmatch = String.startsWith(firstGame.map or '', 'Submatch')
	if isSubmatch then
		games = {firstGame}
	end

	---@param opponent table
	---@param opponentIndex integer
	local getOpponentScoreAndStatus = function(opponent, opponentIndex)
		local statuses = Array.unique(Array.map(games, function(game)
			return game.opponents[opponentIndex].status
		end))
		opponent.status = #statuses == 1 and statuses[1] ~= SCORE_STATUS and statuses[1] or SCORE_STATUS
		opponent.score = isSubmatch and opponent.score or Array.reduce(Array.map(games, function(game)
			return (game.winner == opponentIndex and 1 or 0)
		end), Operator.add)
	end

	Array.forEach(opponents, getOpponentScoreAndStatus)

	local allPlayed = Array.all(games, function (game)
		return game.winner ~= nil or game.status == 'notplayed'
	end)
	local winner = allPlayed and MatchGroupInputUtil.getWinner('', nil, opponents) or nil
	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.placement = MatchGroupInputUtil.placementFromWinner('', winner, opponentIndex)
	end)

	--check the faction of the players
	Array.forEach(opponents, function(_, opponentIndex)
		CustomMatchGroupUtil._determineSubmatchPlayerFactions(match, games, opponents, opponentIndex)
	end)

	return {
		games = games,
		mode = firstGame.mode,
		opponents = opponents,
		subgroup = firstGame.subgroup,
		winner = winner,
		header = Table.extract(match.extradata or {}, 'subgroup' .. firstGame.subgroup .. 'header'),
	}
end

---@param match WarcraftMatchGroupUtilMatch
---@param games WarcraftMatchGroupUtilGame[]
---@param opponents WarcraftMatchGroupUtilGameOpponent[]
---@param opponentIndex integer
function CustomMatchGroupUtil._determineSubmatchPlayerFactions(match, games, opponents, opponentIndex)
	local opponent = opponents[opponentIndex]
	local playerFactions = {}
	Array.forEach(games, function(game)
		for playerIndex, player in pairs(game.opponents[opponentIndex].players) do
			playerFactions[playerIndex] = playerFactions[playerIndex] or {}
			playerFactions[playerIndex][player.faction] = true
		end
	end)

	local toFaction = function(playerIndex, player)
		local isRandom = Array.any(games, function(game)
			return game.opponents[opponentIndex].players[playerIndex].random
		end)
		if isRandom then return Faction.read('r') end

		local faction = Table.uniqueKey(playerFactions[playerIndex])
		if faction then return faction end

		if Table.isNotEmpty(playerFactions[playerIndex]) then
			return Faction.read('m')
		end

		local matchPlayer = match.opponents[opponentIndex].players[player.matchplayerIndex]
		return matchPlayer and matchPlayer.faction or Faction.defaultFaction
	end

	for playerIndex, player in pairs(opponent.players) do
		player.faction = toFaction(playerIndex, player)
	end
end

---Determines if any player in an opponent is not playing their main faction by comparing them to a reference opponent.
---Returns the factions played if at least one player chose an offfaction or nil if otherwise.
---@param gameOpponent WarcraftMatchGroupUtilGameOpponent
---@param referenceOpponent WarcraftStandardOpponent|WarcraftMatchGroupUtilGameOpponent
---@return string[]?
function CustomMatchGroupUtil.computeOfffactions(gameOpponent, referenceOpponent)
	local gameFactions = {}
	local hasOfffaction = false
	for playerIndex, gamePlayer in ipairs(gameOpponent.players) do
		local referencePlayer = referenceOpponent.players[playerIndex]
		table.insert(gameFactions, gamePlayer.faction)
		hasOfffaction = hasOfffaction or gamePlayer.faction ~= referencePlayer.faction
	end
	return hasOfffaction and gameFactions or nil
end

return CustomMatchGroupUtil
