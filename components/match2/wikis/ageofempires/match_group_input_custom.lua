---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Faction = require('Module:Faction')
local Game = require('Module:Game')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local Opponent = Lua.import('Module:Opponent')
local Streams = Lua.import('Module:Links/Stream')

local CustomMatchGroupInput = {}

local OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	assert(not Logic.readBool(match.ffa), 'FFA is not yet supported in AoE match2.')
	Table.mergeInto(match, MatchGroupInputUtil.getTournamentContext(match))
	match.game, match.mapsInfo = CustomMatchGroupInput._getMapsAndGame(match)

	Table.mergeInto(match, MatchGroupInputUtil.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return CustomMatchGroupInput.readOpponent(match, opponentIndex, OPPONENT_CONFIG)
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
		Array.forEach(opponents, function(opponent, opponentIndex)
			opponent.placement = MatchGroupInputUtil.placementFromWinner(match.resulttype, match.winner, opponentIndex)
		end)
	end

	match.mode = Opponent.toLegacyMode(opponents[1].type, opponents[2].type)
	match.stream = Streams.processStreams(match)
	match.links = CustomMatchGroupInput._getLinks(match)

	match.games = games
	match.opponents = opponents

	match.extradata = CustomMatchGroupInput._getExtraData(match)

	return match
end

---@param match table
---@param opponentIndex integer
---@param options readOpponentOptions
---@return table?
function CustomMatchGroupInput.readOpponent(match, opponentIndex, options)
	options = options or {}
	local opponentInput = Json.parseIfString(Table.extract(match, 'opponent' .. opponentIndex))
	if not opponentInput then
		return opponentIndex <= 2 and MatchGroupInputUtil.mergeRecordWithOpponent({}, Opponent.blank()) or nil
	end

	--- or Opponent.blank() is only needed because readOpponentArg can return nil for team opponents
	local opponent = Opponent.readOpponentArgs(opponentInput) or Opponent.blank()
	if Opponent.isBye(opponent) then
		local byeOpponent = Opponent.blank()
		byeOpponent.name = 'BYE'
		return MatchGroupInputUtil.mergeRecordWithOpponent({}, byeOpponent)
	end

	---@type number|string?
	local resolveDate = match.timestamp
	-- If date is default date, resolve using tournament dates instead
	-- default date indicates that the match is missing a date
	-- In order to get correct child team template, we will use an approximately date and not the default date
	if resolveDate == DateExt.defaultTimestamp then
		resolveDate = DateExt.getContextualDate()
	end

	Opponent.resolve(opponent, resolveDate, {syncPlayer = true})

	local substitutions
	if opponent.type == Opponent.team then
		local manualPlayersInput = MatchGroupInputUtil.extractManualPlayersInput(match, opponentIndex, opponentInput)
		substitutions = manualPlayersInput.substitutions
		-- Change compared to commons MatchGroupInputUtil.readOpponent
		local template = mw.ext.TeamTemplate.raw(opponent.template or '') or {}
		opponent.players = MatchGroupInputUtil.readPlayersOfTeam(
			template.page or '',
			manualPlayersInput,
			options,
			{timestamp = match.timestamp, timezoneOffset = match.timezoneOffset}
		)
	end

	Array.forEach(opponent.players or {}, function(player)
		player.pageName = Page.pageifyLink(player.pageName)
	end)

	local record = MatchGroupInputUtil.mergeRecordWithOpponent(opponentInput, opponent, substitutions)

	-- no need to pagify non opponent names as for literals it is irrelevant
	-- and for party opponents it comes down to pagifying player names
	if options.pagifyTeamNames and opponent.type == Opponent.team then
		record.name = Page.pageifyLink(record.name)
	end

	return record
end

---@param match table
---@param opponents table[]
---@return table[]
function CustomMatchGroupInput.extractMaps(match, opponents)
	local maps = {}
	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		map.extradata = {}
		map.map, map.extradata.displayname = CustomMatchGroupInput._getMapName(map, match.mapsInfo)
		map.extradata.mapmode = Table.extract(map, 'mode')

		Table.mergeInto(map, MatchGroupInputUtil.getTournamentContext(map, match))

		map.opponents = CustomMatchGroupInput.processPlayerMapData(map, opponents)

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
	local mapsInfo = Json.parseIfString(Variables.varDefault('tournament_maps'))

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
---@param opponents table[]
---@return {players: table[]}[]
function CustomMatchGroupInput.processPlayerMapData(map, opponents)
	return Array.map(opponents, function(opponent, opponentIndex)
		return {players = CustomMatchGroupInput._participants(
			opponent.match2players,
			map,
			opponentIndex,
			opponent.type
		)}
	end)
end

---@param opponentPlayers table[]
---@param map table
---@param opponentIndex integer
---@param opponentType OpponentType
---@return {civ: string?, flag: string?, displayName: string?, pageName: string?}[]
function CustomMatchGroupInput._participants(opponentPlayers, map, opponentIndex, opponentType)
	local players
	if opponentType == Opponent.team then
		players = Array.parseCommaSeparatedString(map['players' .. opponentIndex])
	else
		players = Array.map(opponentPlayers, Operator.property('name'))
	end
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
				displayName = playerIdData.displayname or playerInputData.name,
				pageName = playerIdData.name or playerInputData.name,
				flag = playerIdData.flag,
				index = playerIndex,
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
