---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Util/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Flags = require('Module:Flags')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

--[[
Utility functions for match group related things specific to the starcraft and starcraft2 wikis.
]]
local StarcraftMatchGroupUtil = {}

StarcraftMatchGroupUtil.types = {}

StarcraftMatchGroupUtil.types.Race = TypeUtil.literalUnion('p', 't', 'z', 'r', 'u')
StarcraftMatchGroupUtil.types.Player = TypeUtil.extendStruct(MatchGroupUtil.types.Player, {
	position = 'number?',
	race = StarcraftMatchGroupUtil.types.Race,
})
StarcraftMatchGroupUtil.types.Opponent = TypeUtil.extendStruct(MatchGroupUtil.types.Opponent, {
	isArchon = 'boolean',
	players = TypeUtil.array(StarcraftMatchGroupUtil.types.Player),
	team = TypeUtil.optional(MatchGroupUtil.types.Team),
})
StarcraftMatchGroupUtil.types.GameOpponent = TypeUtil.struct({
	isArchon = 'boolean',
	isSpecialArchon = 'boolean',
	placement = 'number?',
	players = TypeUtil.array(StarcraftMatchGroupUtil.types.Player),
	score = 'number?',
})
StarcraftMatchGroupUtil.types.Game = TypeUtil.extendStruct(MatchGroupUtil.types.Game, {
	opponents = TypeUtil.array(StarcraftMatchGroupUtil.types.Opponent),
})
StarcraftMatchGroupUtil.types.MatchVeto = TypeUtil.struct({
	by = 'number',
	map = 'string',
})
StarcraftMatchGroupUtil.types.Submatch = TypeUtil.struct({
	games = TypeUtil.array(StarcraftMatchGroupUtil.types.Game),
	mode = 'string',
	opponents = TypeUtil.array(StarcraftMatchGroupUtil.types.Opponent),
	resultType = TypeUtil.optional(MatchGroupUtil.types.ResultType),
	scores = TypeUtil.table('number', 'number'),
	subgroup = 'number',
	walkover = TypeUtil.optional(MatchGroupUtil.types.Walkover),
	winner = 'number?',
})
StarcraftMatchGroupUtil.types.Match = TypeUtil.extendStruct(MatchGroupUtil.types.Match, {
	games = TypeUtil.array(StarcraftMatchGroupUtil.types.Game),
	headToHead = 'boolean',
	isFfa = 'boolean',
	noScore = 'boolean?',
	opponentMode = TypeUtil.literalUnion('uniform', 'team'),
	opponents = TypeUtil.array(StarcraftMatchGroupUtil.types.Opponent),
	vetoes = TypeUtil.array(StarcraftMatchGroupUtil.types.MatchVeto),
})


function StarcraftMatchGroupUtil.matchFromRecord(record)
	local match = MatchGroupUtil.matchFromRecord(record)

	-- Add additional fields to opponents
	StarcraftMatchGroupUtil.populateOpponents(match)

	-- Remove submatches from match.games because submatches will be computed later (even when fetching from lpdb)
	match.games = Array.filter(match.games, function(game) return game.resultType ~= 'submatch' end)

	-- Compute game.opponents by looking up game.participants in match.opponents
	for _, game in ipairs(match.games) do
		game.opponents = StarcraftMatchGroupUtil.computeGameOpponents(game, match.opponents)
	end

	-- Determine whether the match is a team match with different players each game
	match.opponentMode = match.mode:match('team') and 'team' or 'uniform'

	if match.opponentMode == 'team' then
		-- Compute submatches
		match.submatches = Array.map(
			StarcraftMatchGroupUtil.groupBySubmatch(match.games),
			function(games) return StarcraftMatchGroupUtil.constructSubmatch(games, match) end
		)

		-- Extract submatch headers from extradata
		for _, submatch in pairs(match.submatches) do
			submatch.header = Table.extract(match.extradata, 'subGroup' .. submatch.subgroup .. 'header')
		end
	end

	-- Add vetoes
	match.vetoes = {}
	for vetoIx = 1, math.huge do
		local map = Table.extract(match.extradata, 'veto' .. vetoIx)
		local by = tonumber(Table.extract(match.extradata, 'veto' .. vetoIx .. 'by'))
		if not map then break end

		table.insert(match.vetoes, {map = map, by = by})
	end

	-- Misc
	match.headToHead = Logic.readBool(Table.extract(match.extradata, 'headtohead'))
	match.isFfa = Logic.readBool(Table.extract(match.extradata, 'ffa'))
	match.noScore = Logic.readBoolOrNil(Table.extract(match.extradata, 'noscore'))
	match.casters = String.nilIfEmpty(Table.extract(match.extradata, 'casters'))

	return match
end

-- Move additional fields from extradata to struct
function StarcraftMatchGroupUtil.populateOpponents(match)
	local opponents = match.opponents

	for _, opponent in ipairs(opponents) do
		opponent.isArchon = Logic.readBool(Table.extract(opponent.extradata, 'isarchon'))
		opponent.placement2 = tonumber(Table.extract(opponent.extradata, 'placement2'))
		opponent.score2 = tonumber(Table.extract(opponent.extradata, 'score2'))
		opponent.status2 = opponent.score2 and 'S' or nil

		for _, player in ipairs(opponent.players) do
			player.race = Table.extract(player.extradata, 'faction') or 'u'
		end

		if opponent.template == 'default' then
			opponent.team = {
				bracketName = Table.extract(opponent.extradata, 'bracket'),
				displayName = Table.extract(opponent.extradata, 'display'),
				pageName = opponent.name,
				shortName = Table.extract(opponent.extradata, 'short'),
			}
		end
	end

	if #opponents == 2 and opponents[1].score2 and opponents[2].score2 then
		local d = opponents[1].score2 - opponents[2].score2
		opponents[1].placement2 = d > 0 and 1 or 2
		opponents[2].placement2 = d < 0 and 1 or 2
	end
end

-- Computes game.opponents by looking up matchOpponents.players on each
-- participant.
function StarcraftMatchGroupUtil.computeGameOpponents(game, matchOpponents)
	local function playerFromParticipant(opponentIx, matchPlayerIx, participant)
		local matchPlayer = matchOpponents[opponentIx].players[matchPlayerIx]
		if matchPlayer then
			return Table.merge(matchPlayer, {
				matchPlayerIx = matchPlayerIx,
				race = participant.faction,
				position = tonumber(participant.position),
			})
		else
			return {
				displayName = 'TBD',
				matchPlayerIx = matchPlayerIx,
				race = 'u',
			}
		end
	end

	-- Convert participants list to players array
	local opponentPlayers = {}
	for key, participant in pairs(game.participants) do
		local opponentIx, matchPlayerIx = key:match('(%d+)_(%d+)')
		opponentIx = tonumber(opponentIx)
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
			isArchon = modeParts[opponentIx] == 'Archon',
			isSpecialArchon = modeParts[opponentIx]:match('^%dS$'),
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
		if opponent.isSpecialArchon then
			-- Team melee: Sort players by the order they were inputted
			table.sort(opponent.players, function(a, b)
				return a.position < b.position
			end)
		else
			-- Sort players by the order they appear in the match opponent players list
			table.sort(opponent.players, function(a, b)
				return a.matchPlayerIx < b.matchPlayerIx
			end)
		end
	end

	return opponents
end

-- Group games on the subgroup field to form submatches
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
		table.insert(currentGames, game)
	end
	return submatchGames
end

--Constructs a submatch object whose properties are aggregated from that of its games.
function StarcraftMatchGroupUtil.constructSubmatch(games, match)
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
				player.race = matchPlayer and matchPlayer.race or 'u'
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

-- Determine if a match has details that should be displayed via popup
function StarcraftMatchGroupUtil.matchHasDetails(match)
	return match.dateIsExact
		or match.vod
		or not Table.isEmpty(match.links)
		or match.comment
		or match.casters
		or 0 < #match.vetoes
		or Array.any(match.games, function(game)
			return game.map and game.map ~= 'TBD'
				or game.winner
		end)
end

--[[
Determines if any players in an opponent are not playing their main race by
comparing them to a reference opponent. Returns the races played if at least
one player chose an offrace or nil if otherwise.
]]
function StarcraftMatchGroupUtil.computeOffraces(gameOpponent, referenceOpponent)
	local gameRaces = {}
	local hasOffrace = false
	for playerIx, gamePlayer in ipairs(gameOpponent.players) do
		local referencePlayer = referenceOpponent.players[playerIx]
		table.insert(gameRaces, gamePlayer.race)
		if gamePlayer.race ~= referencePlayer.race then
			hasOffrace = true
		end
	end
	return hasOffrace and gameRaces or nil
end

function StarcraftMatchGroupUtil.playerFromRecord(record)
	local extradata = MatchGroupUtil.parseOrCopyExtradata(record.extradata)
	return {
		displayName = record.displayname,
		extradata = extradata,
		flag = String.nilIfEmpty(Flags.CountryName(record.flag)),
		pageIsResolved = true,
		pageName = record.name,
		race = Table.extract(record.extradata, 'faction') or 'u',
	}
end

return StarcraftMatchGroupUtil
