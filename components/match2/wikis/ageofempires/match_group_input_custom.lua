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
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input/Util')
local Opponent = Lua.import('Module:Opponent')
local Streams = Lua.import('Module:Links/Stream')

local ALLOWED_STATUSES = {'W', 'FF', 'DQ', 'L'}
local CONVERT_STATUS_INPUT = {W = 'W', FF = 'FF', L = 'L', DQ = 'DQ', ['-'] = 'L'}
local DEFAULT_LOSS_STATUSES = {'FF', 'L', 'DQ'}
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 10
local DEFAULT_BESTOF = 99

local CustomMatchGroupInput = {}

--- called from Module:MatchGroup
---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	assert(not Logic.readBool(match.ffa), 'FFA is not yet supported in AoE match2.')
	Table.mergeInto(match, MatchGroupInput.readDate(match.date))
	CustomMatchGroupInput._getOpponents(match)
	CustomMatchGroupInput._getTournamentVars(match)
	CustomMatchGroupInput._processMaps(match)
	CustomMatchGroupInput._calculateWinner(match)
	CustomMatchGroupInput._updateFinished(match)
	match.stream = Streams.processStreams(match)
	CustomMatchGroupInput._getLinks(match)
	CustomMatchGroupInput._getVod(match)
	CustomMatchGroupInput._getExtraData(match)
	return match
end

---@param match table
function CustomMatchGroupInput._getTournamentVars(match)
	match = MatchGroupInput.getCommonTournamentVars(match)

	match = CustomMatchGroupInput._getMapsAndGame(match)
	match.bestof = Logic.emptyOr(match.bestof, Variables.varDefault('bestof'))
	match.mode = Opponent.toLegacyMode(match.opponent1.type, match.opponent2.type)
	match.headtohead = Logic.emptyOr(match.headtohead, Variables.varDefault('tournament_headtohead'))

	Variables.varDefine('bestof', match.bestof)
end

---@param match table
---@return table
function CustomMatchGroupInput._getMapsAndGame(match)
	match.mapsInfo = Json.parse(Variables.varDefault('tournament_maps'))

	if Logic.isNotEmpty(match.mapsInfo) and match.game then
		return match
	end

	-- likely in preview w/o Infobox/HDB. Fetch from LPDB
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

	match.game = match.game or data.game
	match.mapsInfo = Logic.emptyOr(match.mapsInfo, (Json.parse(data.maps)))

	return match
end

---@param match table
function CustomMatchGroupInput._updateFinished(match)
	match.finished = Logic.nilOr(Logic.readBoolOrNil(match.finished), Logic.isNotEmpty(match.winner))
	if match.finished or match.timestamp == DateExt.defaultTimestamp then
		return
	end

	-- Match is automatically marked finished upon page edit after a
	-- certain amount of time (depending on whether the date is exact)
	local currentUnixTime = os.time(os.date('!*t') --[[@as osdateparam]])
	local threshold = match.dateexact and 30800 or 86400
	match.finished = match.timestamp + threshold < currentUnixTime
end

---@param match table
function CustomMatchGroupInput._getLinks(match)
	match.links = {}
	match.civdraft1 = match.civdraft1 or match.civdraft
	for key, value in Table.iter.pairsByPrefix(match, 'civdraft') do
		match.links[key] = 'https://aoe2cm.net/draft/' .. value
	end
	match.mapdraft1 = match.mapdraft1 or match.mapdraft
	for key, value in Table.iter.pairsByPrefix(match, 'mapdraft') do
		match.links[key] = 'https://aoe2cm.net/draft/' .. value
	end
end

---@param match table
function CustomMatchGroupInput._getVod(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod)
end

---@param match table
function CustomMatchGroupInput._getExtraData(match)
	match.extradata = {
		headtohead = match.headtohead,
		civdraft = match.civdraft,
		mapdraft = match.mapdraft,
		casters = MatchGroupInput.readCasters(match, {noSort = true}),
	}
end

---@param match table
function CustomMatchGroupInput._processMaps(match)
	for _, _, mapIndex in Table.iter.pairsByPrefix(match, 'map') do
		CustomMatchGroupInput._mapInput(match, mapIndex)
	end
end

---@param match table
function CustomMatchGroupInput._calculateWinner(match)
	local bestof = match.bestof or DEFAULT_BESTOF
	local numberOfOpponents = 0

	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		local opponent = match['opponent' .. opponentIndex]
		if Logic.isEmpty(opponent) then
			break
		end

		numberOfOpponents = numberOfOpponents + 1

		if Logic.isNotEmpty(match.walkover) then
			if Logic.isNumeric(match.walkover) then
				local walkover = tonumber(match.walkover)
				if walkover == opponentIndex then
					match.winner = opponentIndex
					match.walkover = 'FF'
					opponent.status = 'W'
				elseif walkover == 0 then
					match.winner = 0
					match.walkover = 'FF'
					opponent.status = 'FF'
				else
					local score = string.upper(opponent.score or '')
					opponent.status = CONVERT_STATUS_INPUT[score] or 'FF'
				end
			elseif Table.includes(ALLOWED_STATUSES, string.upper(match.walkover)) then
				if tonumber(match.winner or 0) == opponentIndex then
					opponent.status = 'W'
				else
					opponent.status = CONVERT_STATUS_INPUT[string.upper(match.walkover)] or 'L'
				end
			else
				local score = string.upper(opponent.score or '')
				opponent.status = CONVERT_STATUS_INPUT[score] or 'L'
				match.walkover = 'L'
			end
			opponent.score = -1
			match.finished = true
			match.resulttype = 'default'
		elseif CONVERT_STATUS_INPUT[string.upper(opponent.score or '')] then
			if string.upper(opponent.score) == 'W' then
				match.winner = opponentIndex
				match.finished = true
				opponent.score = -1
				opponent.status = 'W'
			else
				local score = string.upper(opponent.score)
				match.finished = true
				match.walkover = CONVERT_STATUS_INPUT[score]
				opponent.status = CONVERT_STATUS_INPUT[score]
				opponent.score = -1
			end
			match.resulttype = 'default'
		else
			opponent.status = 'S'
			opponent.score = tonumber(opponent.score) or tonumber(opponent.autoscore) or -1
			if opponent.score > bestof / 2 then
				match.finished = Logic.emptyOr(match.finished, true)
				match.winner = tonumber(match.winner) or opponentIndex
			end
		end
	end

	CustomMatchGroupInput._determineWinnerIfMissing(match)

	for opponentIndex = 1, numberOfOpponents do
		local opponent = match['opponent' .. opponentIndex]
		if match.winner == 'draw' or tonumber(match.winner) == 0 or
				(match.opponent1.score == bestof / 2 and match.opponent1.score == match.opponent2.score) then
			match.finished = true
			match.winner = 0
			match.resulttype = 'draw'
		end

		if tonumber(match.winner) == opponentIndex or
				match.resulttype == 'draw' then
			opponent.placement = 1
		elseif Logic.isNumeric(match.winner) then
			opponent.placement = 2
		end
	end
end

---@param match table
function CustomMatchGroupInput._determineWinnerIfMissing(match)
	if not Logic.readBool(match.finished) or Logic.isNotEmpty(match.winner) then
		return
	end

	local scores = Array.mapIndexes(function(opponentIndex)
		local opponent = match['opponent' .. opponentIndex]
		if not opponent then
			return nil
		end
		return match['opponent' .. opponentIndex].score or -1
	end
	)
	local maxScore = math.max(unpack(scores) or 0)
	-- if we have a positive score and the match is finished we also have a winner
	if maxScore > 0 then
		local maxIndexFound = false
		for opponentIndex, score in pairs(scores) do
			if maxIndexFound and score == maxScore then
				match.winner = 0
				break
			elseif score == maxScore then
				maxIndexFound = true
				match.winner = opponentIndex
			end
		end
	end
end

---@param match table
---@return table
function CustomMatchGroupInput._getOpponents(match)
	-- read opponents and ignore empty ones
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = match['opponent' .. opponentIndex]
		if Logic.isNotEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, match.timestamp)
		end
		match['opponent' .. opponentIndex] = opponent

		if opponent.type == Opponent.team and Logic.isNotEmpty(opponent.template) then
			local template = mw.ext.TeamTemplate.raw(opponent.template)
			if template then
				MatchGroupInput.readPlayersOfTeam(match, opponentIndex, template.page, {
					resolveRedirect = true,
					applyUnderScores = true,
					maxNumPlayers = MAX_NUM_PLAYERS,
				})
			end
		end
	end

	return match
end

---@param record table
---@param timestamp number
function CustomMatchGroupInput.processOpponent(record, timestamp)
	local opponent = Opponent.readOpponentArgs(record) or Opponent.blank()

	-- Convert byes to literals
	if Opponent.isBye(opponent) then
		opponent = {type = Opponent.literal, name = 'BYE'}
	end

	---@type number|string
	local teamTemplateDate = timestamp
	-- If date is default date, resolve using tournament dates instead
	-- default date indicates that the match is missing a date
	-- In order to get correct child team template, we will use an approximately date and not the default date
	if teamTemplateDate == DateExt.defaultTimestamp then
		teamTemplateDate = DateExt.getContextualDateOrNow()
	end

	Opponent.resolve(opponent, teamTemplateDate, {syncPlayer = true})
	MatchGroupInput.mergeRecordWithOpponent(record, opponent)
end

---@param match table
---@param mapIndex integer
function CustomMatchGroupInput._mapInput(match, mapIndex)
	local map = Json.parseIfString(match['map' .. mapIndex])
	if String.isNotEmpty(map.map) and map.map ~= 'TBD' then
		if Logic.isNotEmpty(match.mapsInfo) then
			local info = Array.find(match.mapsInfo, function(m)
				return m.name == map.map or m.link == map.map
			end)
			if info then
				map.map = info.link
				map.mapDisplayName = info.name
			end
		else
			map.mapDisplayName = map.map
			map.map = mw.ext.TeamLiquidIntegration.resolve_redirect(map.map or '')
		end
	end

	-- set initial extradata for maps
	map.extradata = {
		comment = map.comment,
		header = map.header,
		displayname = map.mapDisplayName,
		mapmode = map.mode
	}
	map.game = match.game
	map.mode = match.mode

	-- determine score, resulttype, walkover and winner
	map = CustomMatchGroupInput._mapWinnerProcessing(map)

	-- Init score if match started and map info is present
	if not match.opponent1.autoscore and not match.opponent2.autoscore
			and map.map and map.map ~= 'TBD'
			and match.timestamp < os.time(os.date('!*t') --[[@as osdateparam]])
			and String.isNotEmpty(map.civs1) and String.isNotEmpty(map.civs2) then
		match.opponent1.autoscore = 0
		match.opponent2.autoscore = 0
	end

	if Logic.isEmpty(map.resulttype) and map.scores[1] and map.scores[2] then
		match.opponent1.autoscore = (match.opponent1.autoscore or 0) + map.scores[1]
		match.opponent2.autoscore = (match.opponent2.autoscore or 0) + map.scores[2]
	end

	-- get participants data for the map + get map mode + winnerfaction and loserfaction
	--(w/l faction stuff only for 1v1 maps)
	CustomMatchGroupInput.processPlayerMapData(map, match, 2)

	match['map' .. mapIndex] = map
end

---@param map table
---@return table
function CustomMatchGroupInput._mapWinnerProcessing(map)
	map.scores = {}
	local hasManualScores = false
	local indexedScores = {}
	for scoreIndex = 1, MAX_NUM_OPPONENTS do
		-- read scores
		local score = map['score' .. scoreIndex]
		local obj = {}
		if Logic.isNotEmpty(score) then
			hasManualScores = true
			score = CONVERT_STATUS_INPUT[score] or score
			if Logic.isNumeric(score) then
				obj.status = 'S'
				obj.score = score
			elseif Table.includes(ALLOWED_STATUSES, score) then
				obj.status = score
				obj.score = -1
			end
			table.insert(map.scores, score)
			indexedScores[scoreIndex] = obj
		else
			break
		end
	end

	local winnerInput = tonumber(map.winner)
	if Logic.isNotEmpty(map.walkover) then
		local walkoverInput = tonumber(map.walkover)
		if walkoverInput == 1 or walkoverInput == 2 or walkoverInput == 0 then
			map.winner = walkoverInput
		end
		map.walkover = Table.includes(ALLOWED_STATUSES, map.walkover) and map.walkover or 'L'
		map.scores = {-1, -1}
		map.resulttype = 'default'

		return map
	end

	if hasManualScores then
		for scoreIndex, _ in Table.iter.spairs(indexedScores, CustomMatchGroupInput._placementSortFunction) do
			if not tonumber(map.winner) then
				map.winner = scoreIndex
			else
				break
			end
		end

		return map
	end

	if map.winner == 'skip' then
		map.scores = {-1, -1}
		map.resulttype = 'np'
	elseif winnerInput == 1 then
		map.scores = {1, 0}
	elseif winnerInput == 2 then
		map.scores = {0, 1}
	elseif winnerInput == 0 or map.winner == 'draw' then
		map.scores = {0.5, 0.5}
		map.resulttype = 'draw'
	end

	return map
end

---@param map table
---@param match table
---@param numberOfOpponents integer
function CustomMatchGroupInput.processPlayerMapData(map, match, numberOfOpponents)
	local participants = {}
	for opponentIndex = 1, numberOfOpponents do
		local opponent = match['opponent' .. opponentIndex]
		if Opponent.typeIsParty(opponent.type) then
			CustomMatchGroupInput._processPartyMapData(opponent.match2players, map, opponentIndex, participants)
		elseif opponent.type == Opponent.team then
			CustomMatchGroupInput._processTeamMapData(opponent.match2players, map, opponentIndex, participants)
		end
	end

	map.participants = participants
end

---@param players table[]
---@param map table
---@param opponentIndex integer
---@param participants table<string, table>
---@return table<string, table>
function CustomMatchGroupInput._processPartyMapData(players, map, opponentIndex, participants)
	local civs = Array.parseCommaSeparatedString(map['civs' .. opponentIndex])

	for playerIndex, player in pairs(players) do
		local civ = Logic.emptyOr(civs[playerIndex], Faction.defaultFaction)
		civ = Faction.read(civ, {game = Game.abbreviation{game = map.game}:lower()})

		participants[opponentIndex .. '_' .. playerIndex] = {
			civ = civ,
			player = player.name,
		}
	end

	return participants
end

---@param opponentPlayers table[]
---@param map table
---@param opponentIndex integer
---@param participants table<string, table>
---@return table<string, table>
function CustomMatchGroupInput._processTeamMapData(opponentPlayers, map, opponentIndex, participants)
	local players = Array.parseCommaSeparatedString(map['players' .. opponentIndex])
	local civs = Array.parseCommaSeparatedString(map['civs' .. opponentIndex])

	local function findPlayer(name)
		return Table.filter(opponentPlayers or {}, function(player)
			return player.displayName == name or player.pageName == name
		end)[1] or {pageName = name, displayName = name}
	end

	for playerIndex, player in pairs(players) do
		local civ = Logic.emptyOr(civs[playerIndex], Faction.defaultFaction)
		civ = Faction.read(civ, {game = Game.abbreviation{game = map.game}:lower()})
		local playerData = findPlayer(player)

		participants[opponentIndex .. '_' .. playerIndex] = {
			civ = civ,
			displayName = playerData.displayName,
			pageName = playerData.pageName,
			flag = playerData.flag,
		}
	end
	return participants
end

-- function to sort out winner/placements
---@param tbl table
---@param key1 string
---@param key2 string
---@return boolean
function CustomMatchGroupInput._placementSortFunction(tbl, key1, key2)
	local opponent1 = tbl[key1]
	local opponent2 = tbl[key2]
	local opponent1Norm = opponent1.status == 'S'
	local opponent2Norm = opponent2.status == 'S'
	if opponent1Norm then
		if opponent2Norm then
			return tonumber(opponent1.score) > tonumber(opponent2.score)
		else
			return true
		end
	else
		if opponent2Norm then
			return false
		elseif opponent1.status == 'W' then
			return true
		elseif Table.includes(DEFAULT_LOSS_STATUSES, opponent1.status) then
			return false
		elseif opponent2.status == 'W' then
			return false
		elseif Table.includes(DEFAULT_LOSS_STATUSES, opponent2.status) then
			return true
		else
			return true
		end
	end
end

return CustomMatchGroupInput
