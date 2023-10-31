---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:MatchGroup/Util/Custom
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
local TypeUtil = require('Module:TypeUtil')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
-- can not use `Module:OpponentLibraries`/`Module:Opponent/Custom` to avoid loop
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})

local TEAM_DISPLAY_MODE = 'team'
local UNIFORM_DISPLAY_MODE = 'uniform'
local SCORE_STATUS = 'S'

local CustomMatchGroupUtil = Table.deepCopy(MatchGroupUtil)

CustomMatchGroupUtil.types.Race = TypeUtil.literalUnion(unpack(Faction.factions))

CustomMatchGroupUtil.types.Player = TypeUtil.extendStruct(MatchGroupUtil.types.Player, {
	position = 'number?',
	race = CustomMatchGroupUtil.types.Race,
})

---@class WarcraftMatchGroupUtilGameOpponent:GameOpponent
---@field placement number?
---@field players WarcraftStandardPlayer[]
---@field score number?
CustomMatchGroupUtil.types.GameOpponent = TypeUtil.struct({
	placement = 'number?',
	players = TypeUtil.array(CustomMatchGroupUtil.types.Player),
	score = 'number?',
})

---@class WarcraftMatchGroupUtilGame: MatchGroupUtilGame
---@field opponents  WarcraftMatchGroupUtilGameOpponent[]
---@field offraces table<integer, string[]>?

---@class WarcraftMatchGroupUtilVeto
---@field by number?
---@field map string

---@class WarcraftMatchGroupUtilSubmatch
---@field games WarcraftMatchGroupUtilGame[]
---@field mode string
---@field opponents WarcraftMatchGroupUtilGameOpponent[]
---@field resultType ResultType
---@field scores table<number, number>
---@field subgroup number
---@field walkover WalkoverType
---@field winner number?
---@field header string?

---@class WarcraftMatchGroupUtilMatch: MatchGroupUtilMatch
---@field games WarcraftMatchGroupUtilGame[]
---@field headToHead boolean
---@field isFfa boolean
---@field noScore boolean?
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

	-- Compute game.opponents by looking up game.participants in match.opponents
	for _, game in ipairs(match.games) do
		game.opponents = CustomMatchGroupUtil.computeGameOpponents(game, match.opponents)
	end

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

		-- Extract submatch headers from extradata
		for _, submatch in pairs(match.submatches) do
			submatch.header = Table.extract(extradata, 'subgroup' .. submatch.subgroup .. 'header')
		end
	end

	-- Add vetoes
	match.vetoes = {}
	for vetoIx = 1, math.huge do
		local map = Table.extract(extradata, 'veto' .. vetoIx)
		local by = tonumber(Table.extract(extradata, 'veto' .. vetoIx .. 'by'))
		if not map then break end

		table.insert(match.vetoes, {map = map, by = by})
	end

	-- Misc
	match.headToHead = Logic.readBool(Table.extract(extradata, 'headtohead'))
	match.isFfa = Logic.readBool(Table.extract(extradata, 'ffa'))
	match.casters = Table.extract(extradata, 'casters')

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
			player.race = Table.extract(player.extradata, 'faction') or Faction.defaultFaction
		end
	end

	if #opponents == 2 and opponents[1].score2 and opponents[2].score2 then
		local scoreDiff = opponents[1].score2 - opponents[2].score2
		opponents[1].placement2 = scoreDiff > 0 and 1 or 2
		opponents[2].placement2 = scoreDiff < 0 and 1 or 2
	end
end

---Computes game.opponents by looking up matchOpponents.players on each participant.
---@param game WarcraftMatchGroupUtilGame
---@param matchOpponents WarcraftStandardOpponent[]
---@return WarcraftMatchGroupUtilGameOpponent[]
function CustomMatchGroupUtil.computeGameOpponents(game, matchOpponents)
	local function playerFromParticipant(opponentIx, matchPlayerIx, participant)
		local matchPlayer = matchOpponents[opponentIx].players[matchPlayerIx]
		if matchPlayer then
			return Table.merge(matchPlayer, {
				matchPlayerIx = matchPlayerIx,
				race = participant.faction,
				position = tonumber(participant.position),
				heroes = participant.heroes,
			})
		else
			return {
				displayName = 'TBD',
				matchPlayerIx = matchPlayerIx,
				race = Faction.defaultFaction,
			}
		end
	end

	-- Convert participants list to players array
	local opponentPlayers = {}
	for key, participant in pairs(game.participants) do
		local opponentIx, matchPlayerIx = key:match('(%d+)_(%d+)')
		opponentIx = tonumber(opponentIx)
		-- opponentIx can not be nil due to the format of the participants keys
		---@cast opponentIx -nil
		matchPlayerIx = tonumber(matchPlayerIx)

		local player = playerFromParticipant(opponentIx, matchPlayerIx, participant)

		if not opponentPlayers[opponentIx] then
			opponentPlayers[opponentIx] = {}
		end
		table.insert(opponentPlayers[opponentIx], player)
	end

	local modeParts = mw.text.split(game.mode or '', 'v')

	-- Create game opponents
	local opponents = {}
	for opponentIx = 1, #modeParts do
		local opponent = {
			placement = tonumber(Table.extract(game.extradata, 'placement' .. opponentIx)),
			players = opponentPlayers[opponentIx] or {},
			score = game.scores[opponentIx],
		}
		if opponent.placement and (opponent.placement < 1 or 99 <= opponent.placement) then
			opponent.placement = nil
		end
		table.insert(opponents, opponent)
	end

	-- Sort players in game opponents
	for _, opponent in pairs(opponents) do
		-- Sort players by the order they appear in the match opponent players list
		table.sort(opponent.players, function(a, b)
			return a.matchPlayerIx < b.matchPlayerIx
		end)
	end

	return opponents
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
	local opponents = Table.deepCopy(games[1].opponents)

	-- If the same race was played in all games, display that instead of the
	-- player's race listed in the match.
	for opponentIx, opponent in pairs(opponents) do
		-- Aggregate races among games for each player
		local playerRaces = {}
		for _, game in pairs(games) do
			for playerIx, player in pairs(game.opponents[opponentIx].players) do
				if not playerRaces[playerIx] then
					playerRaces[playerIx] = {}
				end
				playerRaces[playerIx][player.race] = true
			end
		end

		for playerIx, player in pairs(opponent.players) do
			player.race = Table.uniqueKey(playerRaces[playerIx])
			if not player.race then
				local matchPlayer = match.opponents[opponentIx].players[player.matchPlayerIx]
				player.race = matchPlayer and matchPlayer.race or Faction.defaultFaction
			end
		end
	end

	-- Sum up scores
	local scores = {}
	for opponentIx, _ in pairs(opponents) do
		scores[opponentIx] = 0
	end
	for _, game in pairs(games) do
		if game.map and String.startsWith(game.map, 'Submatch') and not game.resultType then
			for opponentIx, score in pairs(scores) do
				scores[opponentIx] = score + (game.scores[opponentIx] or 0)
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

---Determines if any players in an opponent are not playing their main race by comparing them to a reference opponent.
---Returns the races played if at least one player chose an offrace or nil if otherwise.
---@param gameOpponent WarcraftMatchGroupUtilGameOpponent
---@param referenceOpponent WarcraftStandardOpponent|WarcraftMatchGroupUtilGameOpponent
---@return string[]?
function CustomMatchGroupUtil.computeOffraces(gameOpponent, referenceOpponent)
	local gameRaces = {}
	local hasOffrace = false
	for playerIx, gamePlayer in ipairs(gameOpponent.players) do
		local referencePlayer = referenceOpponent.players[playerIx]
		table.insert(gameRaces, gamePlayer.race)
		hasOffrace = hasOffrace or gamePlayer.race ~= referencePlayer.race
	end
	return hasOffrace and gameRaces or nil
end

---@param record table
---@return WarcraftStandardPlayer
function CustomMatchGroupUtil.playerFromRecord(record)
	local extradata = MatchGroupUtil.parseOrCopyExtradata(record.extradata)
	return {
		displayName = record.displayname,
		extradata = extradata,
		flag = String.nilIfEmpty(Flags.CountryName(record.flag)),
		pageIsResolved = true,
		pageName = record.name,
		race = Table.extract(record.extradata, 'faction') or Faction.defaultFaction,
	}
end

return CustomMatchGroupUtil
