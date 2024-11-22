---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Match/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchLegacy = {}

local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local UNKNOWNREASON_DEFAULT_LOSS = 'L'
local TBD = 'TBD'

---@param match table
function MatchLegacy.storeMatch(match)
	if #match.match2opponents ~= 2 or not Namespace.isMain() then
		return
	end

	match = MatchLegacy._parseJsons(match)

	if Array.all(match.match2opponents, function(opponent) return opponent.type == Opponent.solo end) then
		MatchLegacy._storeSoloMatch(match)
		return
	end

	if Array.all(match.match2opponents, function(opponent) return opponent.type == Opponent.team
		or opponent.type == Opponent.solo end) then

		MatchLegacy._storeTeamMatch(match)
	end

	return
end

---@param object table
---@return table
function MatchLegacy._parseJsons(object)
	for key, item in pairs(object) do
		object[key] = Json.parseIfTable(item) or item
		if type(object[key]) == 'table' then
			object[key] = MatchLegacy._parseJsons(object[key])
		end
	end

	return object
end

---@param match2 table
function MatchLegacy._storeSoloMatch(match2)
	local match = MatchLegacy._convertParameters(match2)
	match.mode = '1v1'
	match.objectName = 'legacymatch_' .. match2.match2id

	local games = ''
	for gameIndex, game in ipairs(match2.match2games or {}) do
		games = games .. (MatchLegacy._storeGame(game, gameIndex, match) or '')
	end

	match.games = games

	match.extradata = Json.stringify(match.extradata)
	mw.ext.LiquipediaDB.lpdb_match(match.objectName, match)
end

---@param match2 table
function MatchLegacy._storeTeamMatch(match2)
	local match = MatchLegacy._convertParameters(match2)
	match.mode = Array.all(match2.match2opponents, function(opponent)
		return opponent.type == Opponent.team end) and Opponent.team or 'mixed'
	match.objectName = 'legacymatch_' .. match2.match2id

	for sumbmatchIndex, submatch in Table.iter.spairs(MatchLegacy._groupIntoSubmatches(match2, match.objectName)) do
		MatchLegacy._storeSubMatch(submatch, sumbmatchIndex, match)
	end

	match.extradata = Json.stringify(match.extradata)
	mw.ext.LiquipediaDB.lpdb_match(match.objectName, match)
end

---@param match2 table
---@return table
function MatchLegacy._convertParameters(match2)
	local bracketData = match2.match2bracketdata or {}

	local match = Table.filterByKey(match2, function(key, entry) return not String.startsWith(key, 'match2') end)
	---@cast match table
	match.type = match.type and string.lower(match.type) or nil
	match.header = DisplayHelper.expandHeader(Logic.emptyOr(bracketData.header, bracketData.inheritedheader) or '')[1]
	match.tickername = Variables.varDefault('tournament_tickername', Variables.varDefault('tournament_ticker_name'))

	match.staticid = match2.match2id

	match.extradata = match.extradata or {}
	local extradata = match.extradata --[[@as table]]

	extradata.legacymatchid = (tonumber(Variables.varDefault('matchID')) or 0) + 1
	Variables.varDefine('matchID', extradata.legacymatchid)

	extradata.mapdetails = #(match2.match2games) > 0 and 1 or 0
	extradata.tournamentstage = Variables.varDefault('tournamentStage') or (
		string.format('%02d', bracketData.bracketindex + 1) .. '-' ..
			string.sub(match2.match2id, #match2.match2bracketid + 2, #match2.match2bracketid + 4))
	extradata.matchsection = Variables.varDefault('matchsection')
	extradata.bestof = match2.bestof
	extradata.format = tonumber(match2.bestof) and ('Bo' .. match2.bestof) or nil

	Array.forEach(match2.match2games or {}, function(game, gameIndex) extradata['vodgame' .. gameIndex] = game.vod end)

	MatchLegacy._opponentToLegacy(match, match2.match2opponents)

	extradata.tournamentstagename = Logic.emptyOr(Variables.varDefault('Group_name'),
		match.header .. ' - ' .. (match.opponent1 or '') .. ' vs ' .. (match.opponent2 or ''))

	if match.resulttype == 'default' then
		match.resulttype = string.upper(match.walkover or '')
		if match.resulttype == UNKNOWNREASON_DEFAULT_LOSS then
			--needs to be converted because in match1 storage it was marked this way
			match.resulttype = 'unk'
		end
		match.walkover = match.winner
	end

	return match
end

---@param object table
---@param opponentData table
function MatchLegacy._opponentToLegacy(object, opponentData)
	Array.forEach(opponentData, function(opponent, opponentIndex)
		local prefix = 'opponent' .. opponentIndex
		local player = (opponent.match2players or {})[1] or {}

		object[prefix] = (opponent.name or player.name or TBD):gsub('_', ' ')
		object[prefix .. 'score'] = (tonumber(opponent.score) or 0) >= 0 and opponent.score or 0

		if opponent.type ~= Opponent.solo then return end

		object[prefix .. 'flag'] = player.flag
		object.extradata[prefix .. 'name'] = player.displayname

		object.extradata[prefix .. 'race'] = (player.extradata or {}).faction
	end)
end

---@param match2 table
---@param objectName string
---@return table<integer, {games: table[], objectName: string, opponents:table[]}>
function MatchLegacy._groupIntoSubmatches(match2, objectName)
	local submatches = {}

	Array.forEach(match2.match2games or {}, function(game)
		local submatchIndex = tonumber(game.subgroup)
		if game.mode ~= '1v1' or not submatchIndex then return end

		if not submatches[submatchIndex] then
			submatches[submatchIndex] = {
				games = {},
				objectName = objectName .. '_Submatch_' .. submatchIndex,
				opponents = MatchLegacy._fromParticipantToOpponent(game.participants or {}, match2.match2opponents)
			}
		end
		local submatch = submatches[submatchIndex]
		table.insert(submatch.games, game)
		submatch.opponents[1].score = submatch.opponents[1].score + (tonumber((game.scores or {})[1]) or 0)
		submatch.opponents[2].score = submatch.opponents[2].score + (tonumber((game.scores or {})[2]) or 0)
	end)

	return submatches
end

---@param submatch {games: table[], objectName: string, opponents:table[]}
---@param submatchIndex integer
---@param match table
function MatchLegacy._storeSubMatch(submatch, submatchIndex, match)
	if Array.any(submatch.opponents, function(opponent) return Table.isEmpty(opponent.match2players) end) then
		return
	end

	local submatchStorageObject = Table.deepCopy(match)
	submatchStorageObject.objectName = submatch.objectName
	submatchStorageObject.mode = '1v1'
	local extradata = submatchStorageObject.extradata --[[@as table]]
	extradata.submatch = submatchIndex

	MatchLegacy._opponentToLegacy(submatchStorageObject, submatch.opponents)

	local games = ''
	for gameIndex, game in ipairs(submatch.games) do
		games = games .. (MatchLegacy._storeGame(game, gameIndex, submatchStorageObject) or '')
	end

	submatchStorageObject.games = games

	submatchStorageObject.extradata = Json.stringify(extradata)

	mw.ext.LiquipediaDB.lpdb_match(submatchStorageObject.objectName, submatchStorageObject)
end

---@param participants table<string, table>
---@param opponents table
---@return {match2players: table[], score: number, type: OpponentType}
function MatchLegacy._fromParticipantToOpponent(participants, opponents)
	local submatchOpponents = {
		{match2players = {}, score = 0, type = Opponent.solo},
		{match2players = {}, score = 0, type = Opponent.solo},
	}
	for participantKey in Table.iter.spairs(participants) do
		local opponentKey, playerKey = string.match(participantKey, '^(%d+)_(%d+)$')
		opponentKey = tonumber(opponentKey)
		table.insert(submatchOpponents[opponentKey].match2players,
			opponents[opponentKey].match2players[tonumber(playerKey)])
	end

	return submatchOpponents
end

---@param game2 table
---@param gameIndex integer
---@param match table
---@return string?
function MatchLegacy._storeGame(game2, gameIndex, match)
	if game2.resulttype == 'np' then return end

	local objectName = match.objectName .. '_Map_' .. gameIndex

	local game = Table.deepCopy(match)
	game.winner = game2.winner
	game.vod = game2.vod
	game.map = game2.map

	game2.scores = game2.scores or {}
	game.opponent1score = game2.scores[1]
	game.opponent2score = game2.scores[2]

	local factions, heroes = MatchLegacy._heroesAndFactionFromParticipants(game2.participants)
	for opponentIndex = 1, 2 do
		game.extradata['opponent' .. opponentIndex .. 'race'] = factions[opponentIndex]
			or game.extradata['opponent' .. opponentIndex .. 'race']

		Array.forEach(heroes[opponentIndex] or {}, function(hero, heroIndex)
			game.extradata['opponent' .. opponentIndex .. 'hero' .. heroIndex] = hero
		end)
	end

	game.extradata.winnerrace = game2.extradata.winnerfaction
	game.extradata.loserrace = game2.extradata.loserfaction

	game.resulttype = nil
	game.walkover = nil
	if game2.resulttype == 'default' then
		game.resulttype = string.upper(game2.walkover or '')
		if game.resulttype == UNKNOWNREASON_DEFAULT_LOSS then
			--needs to be converted because in match1 storage it was marked this way
			game.resulttype = 'unk'
		end
		game.walkover = game2.winner
	end

	return mw.ext.LiquipediaDB.lpdb_game(objectName, game)
end

---@param participants table<string, table>
---@return string[]
---@return string[][]
function MatchLegacy._heroesAndFactionFromParticipants(participants)
	local factions, heroes = {}, {}
	for participantKey, participant in pairs(participants or {}) do
		local opponentKey = string.match(participantKey, '^(%d+)_%d+$')
		opponentKey = tonumber(opponentKey)
		---@cast opponentKey -nil
		factions[opponentKey] = participant.faction
		heroes[opponentKey] = participant.heroes
	end

	return factions, heroes
end

return MatchLegacy
