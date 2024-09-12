---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Array = require('Module:Array')
local Faction = require('Module:Faction')
local Game = require('Module:Game')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local Opponent = Lua.import('Module:Opponent')
local Streams = Lua.import('Module:Links/Stream')

local CustomMatchGroupInput = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	assert(not Logic.readBool(match.ffa), 'FFA is not yet supported in AoE match2.')
	MatchGroupInputUtil.getCommonTournamentVars(match)
	match.mode = Opponent.toLegacyMode(match.opponent1.type, match.opponent2.type)
	match.game, match.mapsInfo = CustomMatchGroupInput._getMapsAndGame(match)

	Table.mergeInto(match, CustomMatchGroupInput.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInputUtil.readOpponent(match, opponentIndex, {})
	end)

	local games = CustomMatchGroupInput.extractMaps(match, opponents)

	local autoScoreFunction = MatchGroupInputUtil.canUseAutoScore(match, games)
		and CustomMatchGroupInput.calculateMatchScore(games)
		or nil

	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.score, opponent.status = MatchGroupInputUtil.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		}, autoScoreFunction)
	end)

	match.bestof = CustomMatchGroupInput.getBestOf(match.bestof)

	local winnerInput = match.winner --[[@as string?]]
	local finishedInput = match.finished --[[@as string?]]
	match.finished = MatchGroupInputUtil.matchIsFinished(match, opponents)

	if match.finished then
		match.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponents)
		match.walkover = MatchGroupInputUtil.getWalkover(match.resulttype, opponents)
		match.winner = MatchGroupInputUtil.getWinner(match.resulttype, winnerInput, opponents)
		MatchGroupInputUtil.setPlacement(opponents, match.winner, 1, 2, match.resulttype)
	end

	match.stream = Streams.processStreams(match)
	match.vod = Logic.nilIfEmpty(match.vod)
	match.links = CustomMatchGroupInput._getLinks(match)

	match.games = games
	match.opponents = opponents

	match.extradata = CustomMatchGroupInput._getExtraData(match)

	return match
end

---@param match table
---@param opponents table[]
---@return table[]
function CustomMatchGroupInput.extractMaps(match, opponents)
	local maps = {}
	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		map.extradata = CustomMatchGroupInput._mapExtradata(map)
		map.map, map.extradata.mapDisplay = CustomMatchGroupInput._getMapName(map, match.mapsInfo)

		map.participants = CustomMatchGroupInput.processPlayerMapData(map, opponents)

		map.finished = MatchGroupInputUtil.mapIsFinished(map)
		local opponentInfo = Array.map(opponents, function(_, opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			}, CustomMatchGroupInput.calculateMapScore(map.winner, map.finished))
			return {score = score, status = status}
		end)

		map.scores = Array.map(opponentInfo, Operator.property('score'))
		if map.finished then
			map.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponentInfo)
			map.walkover = MatchGroupInputUtil.getWalkover(map.resulttype, opponentInfo)
			map.winner = MatchGroupInputUtil.getWinner(map.resulttype, winnerInput, opponentInfo)
		end

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
end

---@param bestofInput string|integer?
---@return integer?
function CustomMatchGroupInput.getBestOf(bestofInput)
	local bestof = tonumber(bestofInput) or tonumber(Variables.varDefault('bestof'))

	if bestof then
		Variables.varDefine('bestof', bestof)
	end

	return bestof
end

---@param match table
---@return string?, table?
function CustomMatchGroupInput._getMapsAndGame(match)
	local mapsInfo = Json.parse(Variables.varDefault('tournament_maps'))

	if Logic.isNotEmpty(mapsInfo) and match.game then
		return match.game, mapsInfo
	end

	-- likely in section preview, fetch from LPDB
	local title = mw.title.getCurrentTitle()
	local pages = {
		title.text:gsub(' ', '_'),
		title.baseText:gsub(' ', '_'),
		title.rootText:gsub(' ', '_'),
	}
	local data = mw.ext.LiquipediaDB.lpdb('tournament', {
			conditions = table.concat(Array.map(pages, function(page) return '[[pagename::' .. page .. ']]' end), ' OR '),
			query = 'game, maps',
			order = 'pagename desc'
		})[1] or {}

	-- Store fetched data for following matches
	Variables.varDefine('tournament_game', data.game)
	Variables.varDefine('tournament_maps', data.maps)

	return match.game or data.game, Logic.emptyOr(mapsInfo, (Json.parse(data.maps)))
end

---@param match table
function CustomMatchGroupInput._getLinks(match)
	local links = {}

	match.civdraft1 = match.civdraft1 or match.civdraft
	for key, value in Table.iter.pairsByPrefix(match, 'civdraft') do
		links[key] = 'https://aoe2cm.net/draft/' .. value
	end

	match.mapdraft1 = match.mapdraft1 or match.mapdraft
	for key, value in Table.iter.pairsByPrefix(match, 'mapdraft') do
		links[key] = 'https://aoe2cm.net/draft/' .. value
	end

	return links
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer
function CustomMatchGroupInput.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param match table
---@return table
function CustomMatchGroupInput._getExtraData(match)
	return {
		headtohead = Logic.emptyOr(match.headtohead, Variables.varDefault('tournament_headtohead')),
		civdraft = match.civdraft,
		mapdraft = match.mapdraft,
		casters = MatchGroupInputUtil.readCasters(match, {noSort = true}),
	}
end

---@param map table
---@param mapsInfo {name: string, link: string}[]?
---@return string?
---@return string?
function CustomMatchGroupInput._getMapName(map, mapsInfo)
	if String.isEmpty(map.map) or map.map == 'TBD' then
		return
	end
	if Logic.isEmpty(mapsInfo) then
		return mw.ext.TeamLiquidIntegration.resolve_redirect(map.map or ''), map.map
	end
	---@cast mapsInfo -nil
	local info = Array.find(mapsInfo, function(m)
		return m.name == map.map or m.link == map.map
	end) or {}
	return info.link, info.name
end

---@param map table
---@return table
function CustomMatchGroupInput._mapExtradata(map)
	return {
		comment = map.comment,
		header = map.header,
	}
end

---@param map table
---@param opponents table[]
---@return table<string, table>
function CustomMatchGroupInput.processPlayerMapData(map, opponents)
	local participants = {}
	for opponentIndex, opponent in ipairs(opponents) do
		if Opponent.typeIsParty(opponent.type) then
			local participantsOfOpponent = CustomMatchGroupInput._processPartyMapData(opponent.match2players, map, opponentIndex)
			Table.mergeInto(participants, Table.map(participantsOfOpponent, MatchGroupInputUtil.prefixPartcipants(opponentIndex)))
		elseif opponent.type == Opponent.team then
			local participantsOfOpponent = CustomMatchGroupInput._processTeamMapData(opponent.match2players, map, opponentIndex)
			Table.mergeInto(participants, Table.map(participantsOfOpponent, MatchGroupInputUtil.prefixPartcipants(opponentIndex)))
		end
	end
	return participants
end

---@param players table[]
---@param map table
---@param opponentIndex integer
---@return {civ: string?, player: string?}[]
function CustomMatchGroupInput._processPartyMapData(players, map, opponentIndex)
	local participants = {}
	local civs = Array.parseCommaSeparatedString(map['civs' .. opponentIndex])

	for playerIndex, player in ipairs(players) do
		local civ = Logic.emptyOr(civs[playerIndex], Faction.defaultFaction)
		civ = Faction.read(civ, {game = Game.abbreviation{game = map.game}:lower()})

		table.insert(participants, {
			civ = civ,
			player = player.name,
		})
	end

	return participants
end

---@param opponentPlayers table[]
---@param map table
---@param opponentIndex integer
---@return {civ: string?, flag: string?, displayName: string?, pageName: string?}[]
function CustomMatchGroupInput._processTeamMapData(opponentPlayers, map, opponentIndex)
	local players = Array.parseCommaSeparatedString(map['players' .. opponentIndex])
	local civs = Array.parseCommaSeparatedString(map['civs' .. opponentIndex])

	local participants, unattachedParticipants = MatchGroupInputUtil.parseParticipants(
		opponentPlayers,
		players,
		function(playerIndex)
			local player = players[playerIndex]
			return player and {name = player} or nil
		end,
		function(playerIndex, playerIdData, playerInputData)
			local civ = Logic.emptyOr(civs[playerIndex], Faction.defaultFaction)
			civ = Faction.read(civ, {game = Game.abbreviation{game = map.game}:lower()})
			return {
				civ = civ,
				displayName = playerIdData.displayName or playerInputData.name,
				pageName = playerIdData.pageName or playerInputData.name,
				flag = playerIdData.flag,
			}
		end
	)
	Array.forEach(unattachedParticipants, function(participant)
		table.insert(participants, participant)
	end)

	return participants
end

---@param winnerInput string|integer|nil
---@param finished boolean
---@return fun(opponentIndex: integer): integer?
function CustomMatchGroupInput.calculateMapScore(winnerInput, finished)
	local winner = tonumber(winnerInput)
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner and not finished then
			return
		end
		return winner == opponentIndex and 1 or 0
	end
end

return CustomMatchGroupInput
