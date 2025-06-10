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
local TypeUtil = require('Module:TypeUtil')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local SCORE_STATUS = 'S'

local CustomMatchGroupUtil = Table.deepCopy(MatchGroupUtil)

CustomMatchGroupUtil.types.Faction = TypeUtil.literalUnion(unpack(Faction.getFactions()))

CustomMatchGroupUtil.types.Player = TypeUtil.extendStruct(MatchGroupUtil.types.Player, {
	position = 'number?',
	faction = CustomMatchGroupUtil.types.Faction,
	random = 'boolean',
})

---@class StormgateMatchGroupUtilGamePlayer: StormgateStandardPlayer
---@field matchplayerIndex integer
---@field heroes string[]?
---@field position integer
---@field random boolean

---@class StormgateMatchGroupUtilGameOpponent:GameOpponent
---@field placement number?
---@field players StormgateMatchGroupUtilGamePlayer[]
---@field score number?
CustomMatchGroupUtil.types.GameOpponent = TypeUtil.struct({
	placement = 'number?',
	players = TypeUtil.array(CustomMatchGroupUtil.types.Player),
	score = 'number?',
})

---@class StormgateMatchGroupUtilGame: MatchGroupUtilGame
---@field opponents StormgateMatchGroupUtilGameOpponent[]
---@field offFactions table<integer, string[]>?

---@class StormgateMatchGroupUtilVeto
---@field by number?
---@field map string

---@class StormgateMatchGroupUtilSubmatch
---@field games StormgateMatchGroupUtilGame[]
---@field mode string
---@field opponents StormgateMatchGroupUtilGameOpponent[]
---@field status string?
---@field subgroup number
---@field winner number?
---@field header string?

---@class StormgateMatchGroupUtilMatch: MatchGroupUtilMatch
---@field games StormgateMatchGroupUtilGame[]
---@field opponents StormgateStandardOpponent[]
---@field vetoes StormgateMatchGroupUtilVeto[]
---@field submatches StormgateMatchGroupUtilSubmatch[]?
---@field casters string?
---@field isUniformMode boolean

---@param record table
---@return StormgateMatchGroupUtilMatch
function CustomMatchGroupUtil.matchFromRecord(record)
	local match = MatchGroupUtil.matchFromRecord(record) --[[@as StormgateMatchGroupUtilMatch]]

	-- Add additional fields to opponents
	CustomMatchGroupUtil.populateOpponents(match)

	-- Adjust game.opponents by looking up game.opponents.players in match.opponents
	Array.forEach(match.games, function(game)
		game.opponents = CustomMatchGroupUtil.computeGameOpponents(game, match.opponents)
	end)

	match.isUniformMode = Array.all(match.opponents, function(opponent) return opponent.type ~= Opponent.team end)

	local extradata = match.extradata
	---@cast extradata table
	if not match.isUniformMode then
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
---@param match StormgateMatchGroupUtilMatch
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

---@param game StormgateMatchGroupUtilGame
---@param matchOpponents StormgateStandardOpponent[]
---@return StormgateMatchGroupUtilGameOpponent[]
function CustomMatchGroupUtil.computeGameOpponents(game, matchOpponents)
	return Array.map(game.opponents, function(mapOpponent, opponentIndex)
		local players = Array.map(mapOpponent.players, function(player, playerIndex)
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
---@param matchGames StormgateMatchGroupUtilGame[]
---@return StormgateMatchGroupUtilGame[][]
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
---@param games StormgateMatchGroupUtilGame[]
---@param match StormgateMatchGroupUtilMatch
---@return StormgateMatchGroupUtilSubmatch
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

	-- can not import this at the top due to loop imports
	local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
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

---@param match StormgateMatchGroupUtilMatch
---@param games StormgateMatchGroupUtilGame[]
---@param opponents StormgateMatchGroupUtilGameOpponent[]
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

---Determines if any players in an opponent aren't playing their main faction by comparing them to a reference opponent.
---Returns the factions played if at least one player chose an offFaction or nil if otherwise.
---@param gameOpponent StormgateMatchGroupUtilGameOpponent
---@param referenceOpponent StormgateStandardOpponent|StormgateMatchGroupUtilGameOpponent
---@return string[]?
function CustomMatchGroupUtil.computeOffFactions(gameOpponent, referenceOpponent)
	local gameFactions = {}
	local hasOffFaction = false
	for playerIndex, gamePlayer in ipairs(gameOpponent.players) do
		local referencePlayer = referenceOpponent.players[playerIndex]
		table.insert(gameFactions, gamePlayer.faction)
		hasOffFaction = hasOffFaction or gamePlayer.faction ~= referencePlayer.faction
	end
	return hasOffFaction and gameFactions or nil
end

return CustomMatchGroupUtil
