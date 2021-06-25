local Array = require('Module:Array')
local Logic = require('Module:Logic')
local MatchGroupUtil = require('Module:MatchGroup/Util')
local String = require('Module:String')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

--[[
Utility functions for match group related things specific to the starcraft and starcraft2 wikis.
]]
local StarcraftMatchGroupUtil = {}

StarcraftMatchGroupUtil.types = {}

StarcraftMatchGroupUtil.types.Race = TypeUtil.literalUnion('p', 't', 'z', 'r', 'u')
StarcraftMatchGroupUtil.types.Player = TypeUtil.extendStruct(MatchGroupUtil.types.Player, {
	mainRace = StarcraftMatchGroupUtil.types.Race,
	position = 'number?',
	race = StarcraftMatchGroupUtil.types.Race,
})
StarcraftMatchGroupUtil.types.Opponent = TypeUtil.extendStruct(MatchGroupUtil.types.Opponent, {
	players = TypeUtil.array(StarcraftMatchGroupUtil.types.Player),
	isArchon = 'boolean',
	team = TypeUtil.optional(MatchGroupUtil.types.Team),
})
StarcraftMatchGroupUtil.types.GameOpponent = TypeUtil.struct({
	players = TypeUtil.array(StarcraftMatchGroupUtil.types.Player),
	isArchon = 'boolean',
	isSpecialArchon = 'boolean',
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
	isFFA = 'boolean',
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
		match.submatches = StarcraftMatchGroupUtil.groupBySubmatch(match.games)

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
	match.isFFA = Logic.readBool(Table.extract(match.extradata, 'ffa'))

	return match
end

-- Move additional fields from extradata to struct
function StarcraftMatchGroupUtil.populateOpponents(match)
	local opponents = match.opponents

	for _, opponent in ipairs(opponents) do
		opponent.isArchon = Logic.readBool(Table.extract(opponent.extradata, 'isarchon'))
		opponent.score2 = tonumber(Table.extract(opponent.extradata, 'score2'))
		opponent.status2 = opponent.score2 and 'S' or nil
		opponent.placement2 = tonumber(Table.extract(opponent.extradata, 'placement2'))

		for _, player in ipairs(opponent.players) do
			player.race = Table.extract(player.extradata, 'faction') or 'u'
			player.mainRace = player.race
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

	if opponents[1] and opponents[2] and opponents[1].score2 and opponents[2].score2 then
		local d = opponents[1].score2 - opponents[2].score2
		opponents[1].placement2 = d > 0 and 1 or 2
		opponents[2].placement2 = d < 0 and 1 or 2
	end
end

-- Computes game.opponents by looking up matchOpponents.players on each
-- participant.
function StarcraftMatchGroupUtil.computeGameOpponents(game, matchOpponents)
	local opponents = {}
	for key, participant in pairs(game.participants) do
		local opponentIx, matchPlayerIx = key:match('(%d+)_(%d+)')
		opponentIx = tonumber(opponentIx)
		matchPlayerIx = tonumber(matchPlayerIx)

		local matchPlayer = matchOpponents[opponentIx].players[matchPlayerIx]
		local player = matchPlayer
			and Table.merge(matchPlayer, {
				mainRace = matchPlayer.race,
				matchPlayerIx = matchPlayerIx,
				race = participant.faction,
				position = tonumber(participant.position),
			})
			or {
				displayName = 'TBD',
				mainRace = 'u',
				matchPlayerIx = matchPlayerIx,
				race = 'u',
			}

		if not opponents[opponentIx] then
			opponents[opponentIx] = {
				-- TODO add FFA support
				isArchon = opponentIx == 1 and game.mode:match('^Archon') ~= nil
					or opponentIx == 2 and game.mode:match('Archon$') ~= nil,
				isSpecialArchon = opponentIx == 1 and game.mode:match('^%dS') ~= nil
					or opponentIx == 2 and game.mode:match('%dS$') ~= nil,
				players = {},
			}
		end
		table.insert(opponents[opponentIx].players, player)
	end

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

	-- Construct submatch objects on grouped games
	return Array.map(submatchGames, StarcraftMatchGroupUtil.constructSubmatch)
end

--Constructs a submatch object whose properties are aggregated from that of its games.
function StarcraftMatchGroupUtil.constructSubmatch(games)
	local opponents = Table.deepCopy(games[1].opponents)

	-- If the same race was played in all games, display that instead of the
	-- player's main race.
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
				or player.mainRace
		end
	end

	-- Sum up scores
	local scores = {}
	for opponentIx, _ in pairs(opponents) do
		scores[opponentIx] = 0
	end
	for _, game in pairs(games) do
		if game.winner then
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
StarcraftMatchGroupUtil.matchHasDetails = function(match)
	return match.dateIsExact
		or match.vod
		or not Table.isEmpty(match.links)
		or match.comment
		or 0 < #match.vetoes
		or Array.any(match.games, function(game)
			return game.map and game.map ~= 'TBD'
				or game.winner
		end)
end

return StarcraftMatchGroupUtil
