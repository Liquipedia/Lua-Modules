---
-- @Liquipedia
-- page=Module:MatchGroup/Util/Starcraft
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

local SCORE_STATUS = MatchGroupInputUtil.STATUS.SCORE

--Utility functions for match group related things specific to the starcraft and starcraft2 wikis.
local StarcraftMatchGroupUtil = Table.deepCopy(MatchGroupUtil)

---@class StarcraftMatchGroupUtilGameOpponent:GameOpponent
---@field isArchon boolean
---@field isSpecialArchon boolean
---@field placement number?
---@field players StarcraftStandardPlayer[]
---@field score number?

---@class StarcraftMatchGroupUtilGame: MatchGroupUtilGame
---@field opponents StarcraftMatchGroupUtilGameOpponent[]
---@field offFactions table<integer, string[]>?

---@class StarcraftMatchGroupUtilVeto
---@field by number?
---@field map string
---@field displayName string?

---@class StarcraftMatchGroupUtilSubmatch
---@field games StarcraftMatchGroupUtilGame[]
---@field mode string
---@field status string?
---@field opponents StarcraftMatchGroupUtilGameOpponent[]
---@field subgroup number
---@field winner number?
---@field header string?

---@class StarcraftMatchGroupUtilMatch: MatchGroupUtilMatch
---@field games StarcraftMatchGroupUtilGame[]
---@field isFfa boolean
---@field opponentMode 'uniform'|'team'
---@field opponents StarcraftStandardOpponent[]
---@field vetoes StarcraftMatchGroupUtilVeto[]
---@field submatches StarcraftMatchGroupUtilSubmatch[]?
---@field casters string?

---@param record table
---@return StarcraftMatchGroupUtilMatch
function StarcraftMatchGroupUtil.matchFromRecord(record)
	local match = MatchGroupUtil.matchFromRecord(record)--[[@as StarcraftMatchGroupUtilMatch]]

	-- Add additional fields to opponents
	StarcraftMatchGroupUtil.populateOpponents(match)

	-- Adjust game.opponents by looking up game.opponents.players in match.opponents
	Array.forEach(match.games, function(game)
		game.opponents = StarcraftMatchGroupUtil.computeGameOpponents(game, match.opponents)
		game.extradata = game.extradata or {}
	end)

	-- Determine whether the match is a team match with different players each game
	match.opponentMode = Array.any(match.opponents, function(opponent)
		return opponent.type == Opponent.team
	end) and 'team' or 'uniform'

	local extradata = match.extradata
	---@cast extradata table
	if match.opponentMode == 'team' then
		-- Compute submatches
		match.submatches = Array.map(
			StarcraftMatchGroupUtil.groupBySubmatch(match.games),
			function(games) return StarcraftMatchGroupUtil.constructSubmatch(games, match) end
		)
	end

	-- Add vetoes
	match.vetoes = {}
	for vetoIndex = 1, math.huge do
		local map = Table.extract(extradata, 'veto' .. vetoIndex)
		local by = tonumber(Table.extract(extradata, 'veto' .. vetoIndex .. 'by'))
		local displayName = Table.extract(extradata, 'veto' .. vetoIndex .. 'displayname')

		if not map then break end

		table.insert(match.vetoes, {map = map, by = by, displayName = displayName})
	end

	-- Misc
	match.isFfa = Logic.readBool(Table.extract(extradata, 'ffa'))

	return match
end

---Move additional fields from extradata to struct
---@param match StarcraftMatchGroupUtilMatch
function StarcraftMatchGroupUtil.populateOpponents(match)
	local opponents = match.opponents

	for _, opponent in ipairs(opponents) do
		opponent.isArchon = Logic.readBool(Table.extract(opponent.extradata, 'isarchon'))
		opponent.placement2 = tonumber(Table.extract(opponent.extradata, 'placement2'))
		opponent.score2 = tonumber(Table.extract(opponent.extradata, 'score2'))
		opponent.status2 = opponent.score2 and 'S' or nil

		for _, player in ipairs(opponent.players) do
			player.faction = Table.extract(player.extradata, 'faction') or Faction.defaultFaction
		end
	end

	if #opponents == 2 and opponents[1].score2 and opponents[2].score2 then
		local d = opponents[1].score2 - opponents[2].score2
		opponents[1].placement2 = d > 0 and 1 or 2
		opponents[2].placement2 = d < 0 and 1 or 2
	end
end

---@param game StarcraftMatchGroupUtilGame
---@param matchOpponents StarcraftStandardOpponent[]
---@return StarcraftMatchGroupUtilGameOpponent[]
function StarcraftMatchGroupUtil.computeGameOpponents(game, matchOpponents)
	local modeParts = mw.text.split(game.mode or '', 'v')

	return Array.map(game.opponents, function(mapOpponent, opponentIndex)
		local mode = modeParts[opponentIndex]
		local players = Array.map(mapOpponent.players or {}, function(player, playerIndex)
			if Logic.isEmpty(player) then return end
			local matchPlayer = (matchOpponents[opponentIndex].players or {})[playerIndex] or {}
			return Table.merge({displayName = 'TBD'}, matchPlayer, {
				faction = player.faction,
				position = tonumber(player.position),
				matchPlayerIndex = playerIndex,
			})
		end) --[[@as table[] ]]

		local isSpecialArchon = (mode or ''):match('^%dS$')
		if isSpecialArchon then
			-- Team melee: Sort players by the order they were inputted
			table.sort(players, function(a, b) return a.position < b.position end)
		end

		return Table.merge(mapOpponent, {
			isArchon = mode == 'Archon',
			isSpecialArchon = isSpecialArchon,
			players = players,
		})
	end)
end

---Group games on the subgroup field to form submatches
---@param matchGames StarcraftMatchGroupUtilGame[]
---@return StarcraftMatchGroupUtilGame[][]
function StarcraftMatchGroupUtil.groupBySubmatch(matchGames)
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
---@param games StarcraftMatchGroupUtilGame[]
---@param match StarcraftMatchGroupUtilMatch
---@return StarcraftMatchGroupUtilSubmatch
function StarcraftMatchGroupUtil.constructSubmatch(games, match)
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

		Array.forEach(opponent.players, function(player, playerIndex)
			local playerFactions = {}
			Array.forEach(games, function(game)
				local gamePlayer = game.opponents[opponentIndex].players[playerIndex] or {}
				if not gamePlayer.faction then return end
				playerFactions[gamePlayer.faction] = true
			end)
			player.faction = Table.uniqueKey(playerFactions)
			if not player.faction then
				local matchPlayer = match.opponents[opponentIndex].players[player.matchPlayerIndex]
				player.faction = matchPlayer and matchPlayer.faction or Faction.defaultFaction
			end
		end)
	end

	Array.forEach(opponents, getOpponentScoreAndStatus)

	local allPlayed = Array.all(games, function (game)
		return game.winner ~= nil or game.status == 'notplayed'
	end)
	local winner = allPlayed and MatchGroupInputUtil.getWinner('', nil, opponents) or nil
	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.placement = MatchGroupInputUtil.placementFromWinner('', winner, opponentIndex)
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

---Determine if a match has details that should be displayed via popup
---@param match StarcraftMatchGroupUtilMatch
---@return boolean
function StarcraftMatchGroupUtil.matchHasDetails(match)
	local linksWithoutH2H = Table.filterByKey(match.links, function(key)
		return key ~= 'headtohead'
	end)
	return match.dateIsExact
		or String.isNotEmpty(match.vod)
		or not Table.isEmpty(linksWithoutH2H)
		or String.isNotEmpty(match.comment)
		or String.isNotEmpty(match.casters)
		or 0 < #match.vetoes
		or Array.any(match.games, function(game)
			return game.map and game.map ~= 'TBD'
				or Logic.isNumeric(game.winner)
		end)
end

---Determines if any player in an opponent is not playing their main faction by comparing them to a reference opponent.
---Returns the factions played if at least one player chose an offFaction or nil if otherwise.
---@param gameOpponent StarcraftMatchGroupUtilGameOpponent
---@param referenceOpponent StarcraftStandardOpponent|StarcraftMatchGroupUtilGameOpponent
---@return string[]?
function StarcraftMatchGroupUtil.computeOffFactions(gameOpponent, referenceOpponent)
	local gameFactions = {}
	local hasOffFaction = false
	for playerIndex, gamePlayer in ipairs(gameOpponent.players) do
		local referencePlayer = referenceOpponent.players[playerIndex] or {}
		table.insert(gameFactions, gamePlayer.faction)
		if gamePlayer.faction ~= referencePlayer.faction then
			hasOffFaction = true
		end
	end
	return hasOffFaction and gameFactions or nil
end

---@param matchRecord match2
---@param record match2opponent
---@param opponentIndex integer
---@return StarcraftStandardOpponent
function StarcraftMatchGroupUtil.opponentFromRecord(matchRecord, record, opponentIndex)
	local extradata = MatchGroupUtil.parseOrCopyExtradata(record.extradata)
	local opponent = MatchGroupUtil.opponentFromRecord(matchRecord, record, opponentIndex) --[[
	@as StarcraftStandardOpponent]]
	opponent.isArchon = Logic.readBool(extradata.isarchon)

	return opponent
end

return StarcraftMatchGroupUtil
