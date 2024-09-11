---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Util/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Faction = require('Module:Faction')
local Flags = require('Module:Flags')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

--[[
Utility functions for match group related things specific to the starcraft and starcraft2 wikis.
]]
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
---@field opponents StarcraftMatchGroupUtilGameOpponent[]
---@field resultType ResultType
---@field scores table<number, number>
---@field subgroup number
---@field walkover WalkoverType
---@field winner number?
---@field header string?

---@class StarcraftMatchGroupUtilMatch: MatchGroupUtilMatch
---@field games StarcraftMatchGroupUtilGame[]
---@field headToHead boolean
---@field isFfa boolean
---@field noScore boolean?
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

	-- Compute game.opponents by looking up game.participants in match.opponents
	for _, game in ipairs(match.games) do
		game.opponents = StarcraftMatchGroupUtil.computeGameOpponents(game, match.opponents)
		game.extradata = game.extradata or {}
	end

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

		-- Extract submatch headers from extradata
		for _, submatch in pairs(match.submatches) do
			submatch.header = Table.extract(extradata, 'subGroup' .. submatch.subgroup .. 'header')
		end
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
	match.headToHead = Logic.readBool(Table.extract(extradata, 'headtohead'))
	match.isFfa = Logic.readBool(Table.extract(extradata, 'ffa'))
	match.noScore = Logic.readBoolOrNil(Table.extract(extradata, 'noscore'))
	match.casters = String.nilIfEmpty(Table.extract(extradata, 'casters'))

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

---Computes game.opponents by looking up matchOpponents.players on each participant.
---@param game StarcraftMatchGroupUtilGame
---@param matchOpponents StarcraftStandardOpponent[]
---@return StarcraftMatchGroupUtilGameOpponent[]
function StarcraftMatchGroupUtil.computeGameOpponents(game, matchOpponents)
	local function playerFromParticipant(opponentIndex, matchPlayerIndex, participant)
		local matchPlayer = matchOpponents[opponentIndex].players[matchPlayerIndex]
		if matchPlayer then
			return Table.merge(matchPlayer, {
				matchPlayerIndex = matchPlayerIndex,
				faction = participant.faction,
				position = tonumber(participant.position),
			})
		else
			return {
				displayName = 'TBD',
				matchPlayerIndex = matchPlayerIndex,
				faction = Faction.defaultFaction,
			}
		end
	end

	-- Convert participants list to players array
	local opponentPlayers = {}
	for key, participant in pairs(game.participants) do
		local opponentIndex, matchPlayerIndex = key:match('(%d+)_(%d+)')
		opponentIndex = tonumber(opponentIndex)
		-- opponentIndex can not be nil due to the format of the participants keys
		---@cast opponentIndex -nil
		matchPlayerIndex = tonumber(matchPlayerIndex)

		local player = playerFromParticipant(opponentIndex, matchPlayerIndex, participant)

		if not opponentPlayers[opponentIndex] then
			opponentPlayers[opponentIndex] = {}
		end
		table.insert(opponentPlayers[opponentIndex], player)
	end

	local modeParts = mw.text.split(game.mode or '', 'v')

	-- Create game opponents
	local opponents = {}
	for opponentIndex = 1, #modeParts do
		local opponent = {
			isArchon = modeParts[opponentIndex] == 'Archon',
			isSpecialArchon = modeParts[opponentIndex]:match('^%dS$'),
			placement = tonumber(Table.extract(game.extradata, 'placement' .. opponentIndex)),
			players = opponentPlayers[opponentIndex] or {},
			score = game.scores[opponentIndex],
		}
		if opponent.placement and (opponent.placement < 1 or 99 <= opponent.placement) then
			opponent.placement = nil
		end
		table.insert(opponents, opponent)
	end

	-- Sort players in game opponents
	for _, opponent in pairs(opponents) do
		if opponent.isSpecialArchon then
			-- Team melee: Sort players by the order they were inputted
			table.sort(opponent.players, function(a, b)
				return a.position < b.position
			end)
		else
			-- Sort players by the order they appear in the match opponent players list
			table.sort(opponent.players, function(a, b)
				return a.matchPlayerIndex < b.matchPlayerIndex
			end)
		end
	end

	return opponents
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
	local opponents = Table.deepCopy(games[1].opponents)

	-- If the same faction was played in all games, display that instead of the
	-- player's faction listed in the match.
	for opponentIndex, opponent in pairs(opponents) do
		-- Aggregate factions among games for each player
		local playerFactions = {}
		for _, game in pairs(games) do
			for playerIndex, player in pairs(game.opponents[opponentIndex].players) do
				if not playerFactions[playerIndex] then
					playerFactions[playerIndex] = {}
				end
				playerFactions[playerIndex][player.faction] = true
			end
		end

		for playerIndex, player in pairs(opponent.players) do
			player.faction = Table.uniqueKey(playerFactions[playerIndex])
			if not player.faction then
				local matchPlayer = match.opponents[opponentIndex].players[player.matchPlayerIndex]
				player.faction = matchPlayer and matchPlayer.faction or Faction.defaultFaction
			end
		end
	end

	-- Sum up scores
	local scores = {}
	for opponentIndex, _ in pairs(opponents) do
		scores[opponentIndex] = 0
	end
	for _, game in pairs(games) do
		if game.map and String.startsWith(game.map, 'Submatch') and not game.resultType then
			for opponentIndex, score in pairs(scores) do
				scores[opponentIndex] = score + (game.scores[opponentIndex] or 0)
			end
		elseif game.winner then
			scores[game.winner] = (scores[game.winner] or 0) + 1
		end
	end

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
	for _, game in pairs(games) do
		resultTypes[game.resultType or ''] = true
		walkovers[game.walkover or ''] = true
	end
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
		mode = games[1].mode,
		opponents = opponents,
		resultType = resultType,
		scores = scores,
		subgroup = games[1].subgroup,
		walkover = walkover,
		winner = winner,
	}
end

---Determine if a match has details that should be displayed via popup
---@param match StarcraftMatchGroupUtilMatch
---@return boolean
function StarcraftMatchGroupUtil.matchHasDetails(match)
	return match.dateIsExact
		or String.isNotEmpty(match.vod)
		or not Table.isEmpty(match.links)
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

---@param record table
---@return StarcraftStandardPlayer
function StarcraftMatchGroupUtil.playerFromRecord(record)
	local extradata = MatchGroupUtil.parseOrCopyExtradata(record.extradata)
	return {
		displayName = record.displayname,
		extradata = extradata,
		flag = String.nilIfEmpty(Flags.CountryName(record.flag)),
		pageIsResolved = true,
		pageName = record.name,
		faction = Table.extract(record.extradata, 'faction') or Faction.defaultFaction,
	}
end

return StarcraftMatchGroupUtil
