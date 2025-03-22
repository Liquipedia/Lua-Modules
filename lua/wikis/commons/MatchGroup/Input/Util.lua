---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Input/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Faction = require('Module:Faction')
local Flags = require('Module:Flags')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Page = require('Module:Page')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Streams = require('Module:Links/Stream')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Links = Lua.import('Module:Links')
-- can not use /Custom here to avoid dependency loop on sc(2)
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local globalVars = PageVariableNamespace{cached = true}

local MatchGroupInputUtil = {}

---@class MGIParsedPlayer
---@field displayname string?
---@field name string?
---@field flag string?
---@field faction string?
---@field index integer
---@field extradata table

---@class MGIParsedOpponent
---@field type OpponentType
---@field name string
---@field template string?
---@field icon string?
---@field icondark string?
---@field score integer?
---@field status string?
---@field placement integer?
---@field match2players MGIParsedPlayer[]
---@field startingpoints number?
---@field extradata table

local NOT_PLAYED_INPUTS = {
	'skip',
	'np',
	'canceled',
	'cancelled',
}

MatchGroupInputUtil.DEFAULT_ALLOWED_VETOES = {
	'decider',
	'pick',
	'ban',
	'defaultban',
}

MatchGroupInputUtil.STATUS_INPUTS = {
	DEFAULT_WIN = 'W',
	DEFAULT_LOSS = 'L',
	DRAW = 'D',
	FORFEIT = 'FF',
	DISQUALIFIED = 'DQ',
}

MatchGroupInputUtil.STATUS = Table.copy(MatchGroupInputUtil.STATUS_INPUTS)
MatchGroupInputUtil.STATUS.SCORE = 'S'

MatchGroupInputUtil.MATCH_STATUS = {
	NOT_PLAYED = 'notplayed',
}

MatchGroupInputUtil.SCORE_NOT_PLAYED = -1
MatchGroupInputUtil.WINNER_DRAW = 0

local ASSUME_FINISHED_AFTER = {
	EXACT = 30800,
	ESTIMATE = 86400,
}
MatchGroupInputUtil.ASSUME_FINISHED_AFTER = ASSUME_FINISHED_AFTER

local NOW = os.time()
local contentLanguage = mw.getContentLanguage()

---@class MatchGroupMvpPlayer
---@field displayname string
---@field name string
---@field comment string?
---@field team string?
---@field template string

---@class readOpponentOptions
---@field maxNumPlayers integer?
---@field resolveRedirect boolean?
---@field pagifyTeamNames boolean?
---@field disregardTransferDates boolean?

---@class MatchGroupInputSubstituteInformation
---@field substitute standardPlayer
---@field player standardPlayer?
---@field games string[]
---@field reason string?

---@param dateString string?
---@param dateFallbacks string[]?
---@return {date: string, dateexact: boolean, timestamp: integer, timezoneId: string?, timezoneOffset: string?}
function MatchGroupInputUtil.readDate(dateString, dateFallbacks)
	if dateString then
		-- Extracts the '-4:00' out of <abbr data-tz="-4:00" title="Eastern Daylight Time (UTC-4)">EDT</abbr>
		local timezoneOffset = dateString:match('data%-tz%=[\"\']([%d%-%+%:]+)[\"\']')
		local timezoneId = dateString:match('>(%a-)<')
		local matchDate = mw.text.split(dateString, '<', true)[1]:gsub('-', '')
		local isDateExact = String.contains(matchDate .. (timezoneOffset or ''), '[%+%-]')
		local date = contentLanguage:formatDate('c', matchDate .. (timezoneOffset or ''))
		return {
			date = date,
			dateexact = isDateExact,
			timezoneId = timezoneId,
			timezoneOffset = timezoneOffset,
			timestamp = DateExt.readTimestamp(dateString),
		}

	elseif dateFallbacks then
		table.insert(dateFallbacks, DateExt.defaultDate)
		local suggestedDate
		for _, fallbackDate in ipairs(dateFallbacks) do
			if globalVars:get(fallbackDate) then
				suggestedDate = globalVars:get(fallbackDate)
				break
			end
		end
		local missingDateCount = globalVars:get('num_missing_dates') or 0
		globalVars:set('num_missing_dates', missingDateCount + 1)
		local inexactDateString = (suggestedDate or '') .. ' + ' .. missingDateCount .. ' second'
		local date = contentLanguage:formatDate('c', inexactDateString)
		return {
			date = date,
			dateexact = false,
			timestamp = DateExt.readTimestampOrNil(date),
		}

	else
		return {
			date = DateExt.defaultDateTimeExtended,
			dateexact = false,
			timestamp = DateExt.defaultTimestamp,
		}
	end
end

---Fetches the LPDB records of a match group containing standalone matches.
---Standalone matches are specified from individual match pages in the Match namespace.
---@param bracketId string
---@return match2[]
MatchGroupInputUtil.fetchStandaloneMatchGroup = FnUtil.memoize(function(bracketId)
	return mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = '[[namespace::130]] AND [[match2bracketid::' .. bracketId .. ']]',
		limit = 5000,
	})
end)

---Fetches the LPDB record of a standalone match.
---
---matchId is a full match ID, such as MATCH_wec2CbLWRx_0001
---@param matchId string
---@return match2?
function MatchGroupInputUtil.fetchStandaloneMatch(matchId)
	local bracketId, _ = MatchGroupUtil.splitMatchId(matchId)
	assert(bracketId, 'Invalid matchId "' .. matchId .. '"')
	local matches = MatchGroupInputUtil.fetchStandaloneMatchGroup(bracketId)
	return Array.find(matches, function(match)
		return match.match2id == matchId
	end)
end

---Warning, mutates first argument by removing the key `opponentX` where X is the second argument
---@param match table
---@param opponentIndex integer
---@param options readOpponentOptions?
---@return MGIParsedOpponent?
function MatchGroupInputUtil.readOpponent(match, opponentIndex, options)
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
		opponent.players = MatchGroupInputUtil.readPlayersOfTeam(
			Opponent.toName(opponent) or '',
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

--[[
Merges an opponent struct into a match2 opponent record.

If any property exists in both the record and opponent struct, the value from the opponent struct will be prioritized.
The opponent struct is retrieved programmatically via Module:Opponent, by using the team template extension.
Using the team template extension, the opponent struct is standardised and not user input dependant, unlike the record.
]]
---@param record table
---@param opponent standardOpponent|StarcraftStandardOpponent|StormgateStandardOpponent|WarcraftStandardOpponent
---@param substitutions MatchGroupInputSubstituteInformation[]?
---@return MGIParsedOpponent
function MatchGroupInputUtil.mergeRecordWithOpponent(record, opponent, substitutions)
	if opponent.type == Opponent.team then
		record.template = opponent.template or record.template
		record.icon = opponent.icon or record.icon
		record.icondark = opponent.icondark or record.icondark
	end

	if not record.match2players then
		record.match2players = Array.map(opponent.players or {}, function(player)
			return {
				displayname = player.displayName,
				flag = player.flag,
				name = player.pageName,
				team = player.team,
				extradata = player.faction and {faction = player.faction}
			}
		end)
	end

	record.name = Opponent.toName(opponent)
	record.type = opponent.type
	record.extradata = Table.merge(record.extradata or {}, {substitutions = Logic.nilIfEmpty(substitutions)})

	return record
end

-- Retrieves Common Tournament Variables used inside match2 and match2game
---@param obj table
---@param parent table?
---@return table
---@nodiscard
function MatchGroupInputUtil.getTournamentContext(obj, parent)
	parent = parent or {}
	local vars = {}
	vars.game = Logic.emptyOr(obj.game, parent.game, globalVars:get('tournament_game'))
	vars.icon = Logic.emptyOr(obj.icon, parent.icon, globalVars:get('tournament_icon'))
	vars.icondark = Logic.emptyOr(obj.iconDark, parent.icondark, globalVars:get('tournament_icondark'))
	vars.liquipediatier = Logic.emptyOr(
		obj.liquipediatier,
		parent.liquipediatier,
		globalVars:get('tournament_liquipediatier')
	)
	vars.liquipediatiertype = Logic.emptyOr(
		obj.liquipediatiertype,
		parent.liquipediatiertype,
		globalVars:get('tournament_liquipediatiertype')
	)
	vars.publishertier = Logic.emptyOr(
		obj.publishertier,
		parent.publishertier,
		globalVars:get('tournament_publishertier')
	)
	vars.series = Logic.emptyOr(obj.series, parent.series, globalVars:get('tournament_series'))
	vars.shortname = Logic.emptyOr(obj.shortname, parent.shortname, globalVars:get('tournament_shortname'))
	vars.tickername = Logic.emptyOr(obj.tickername, parent.tickername, globalVars:get('tournament_tickername'))
	vars.tournament = Logic.emptyOr(obj.tournament, parent.tournament, globalVars:get('tournament_name'))
	vars.type = Logic.emptyOr(obj.type, parent.type, globalVars:get('tournament_type'))
	vars.patch = Logic.emptyOr(obj.patch, parent.patch, globalVars:get('tournament_patch'))
	vars.date = Logic.emptyOr(obj.date, parent.date)
	vars.mode = Logic.emptyOr(obj.mode, parent.mode)

	return vars
end

---@param match table
---@param opponents? table[]
---@return {players: MatchGroupMvpPlayer[], points: integer}?
function MatchGroupInputUtil.readMvp(match, opponents)
	if not match.mvp then return end
	local mvppoints = match.mvppoints or 1

	-- Split the input
	local players = mw.text.split(match.mvp, ',')

	-- parse the players to get their information
	opponents = Logic.isNotDeepEmpty(opponents) and opponents or MatchGroupUtil.normalizeSubtype(match, 'opponent')
	local parsedPlayers = Array.map(players, function(player, playerIndex)
		local link = mw.ext.TeamLiquidIntegration.resolve_redirect(mw.text.split(player, '|')[1]):gsub(' ', '_')
		for _, opponent in ipairs(opponents) do
			for _, lookUpPlayer in pairs(opponent.match2players or {}) do
				if link == lookUpPlayer.name then
					return Table.merge(lookUpPlayer,
						{team = opponent.name, template = opponent.template, comment = match['mvp' .. playerIndex .. 'comment']})
				end
			end
		end

		local nameComponents = mw.text.split(player, '|')
		return {
			displayname = nameComponents[#nameComponents],
			name = link,
			comment = match['mvp' .. playerIndex .. 'comment']
		}
	end)

	return {players = parsedPlayers, points = mvppoints}
end

---@param match table
---@param opponentIndex integer
---@param opponentInput table
---@return {players: table[], substitutions: MatchGroupInputSubstituteInformation[]}
function MatchGroupInputUtil.extractManualPlayersInput(match, opponentIndex, opponentInput)
	local manualInput = {players = {}}

	---@param playerData table|string|nil
	---@return standardPlayer?
	local makeStandardPlayer = function(playerData)
		if not playerData then return end
		playerData = type(playerData) == 'string' and {playerData} or playerData
		local player = {
			displayName = Logic.emptyOr(playerData.displayName, playerData.displayname, playerData[1] or playerData.name),
			pageName = Logic.emptyOr(playerData.pageName, playerData.pagename, playerData.link),
			flag = playerData.flag,
			faction = playerData.faction or playerData.race,
		}
		if Logic.isEmpty(player.displayName) then return end
		player = PlayerExt.populatePlayer(player)
		return player
	end

	local substitutions, parseFailure = Json.parseStringified(opponentInput.substitutes)
	if parseFailure then
		substitutions = {}
	end

	manualInput.substitutions = Array.map(substitutions, function(substitution)
		if type(substitution) ~= 'table' or not substitution['in'] then return end

		return {
			substitute = makeStandardPlayer(substitution['in']),
			player = makeStandardPlayer(substitution.out),
			games = Logic.nilIfEmpty(Array.parseCommaSeparatedString(substitution.games, ';')),
			reason = substitution.reason,
		}
	end)

	--players from manual input in `opponent.players`
	local playersData = Json.parseIfString(opponentInput.players)

	if not playersData then return manualInput end

	for playerPrefix, playerName in Table.iter.pairsByPrefix(playersData, 'p') do
		table.insert(manualInput.players, {
			pageName = playersData[playerPrefix .. 'link'] or playerName,
			displayName = playersData[playerPrefix .. 'dn'] or playerName,
			flag = playersData[playerPrefix .. 'flag'],
			faction = playersData[playerPrefix .. 'faction'] or playersData[playerPrefix .. 'race'],
		})
	end

	return manualInput
end

---reads the players of a team from input and wiki variables
---@param teamName string
---@param manualPlayersInput {players: table[], substitutions: MatchGroupInputSubstituteInformation[]}
---@param options readOpponentOptions
---@param dateTimeInfo {timestamp: integer?, timezoneOffset: string?}
---@return table
function MatchGroupInputUtil.readPlayersOfTeam(teamName, manualPlayersInput, options, dateTimeInfo)
	local players = {}
	local playersIndex = 0

	---@param player {pageName: string, displayName: string?, flag: string?, faction: string?, customId: string?}
	local insertIntoPlayers = function(player)
		if type(player) ~= 'table' or Logic.isEmpty(player) or Logic.isEmpty(player.pageName) then
			return
		end

		local pageName = player.pageName
		pageName = options.resolveRedirect and mw.ext.TeamLiquidIntegration.resolve_redirect(pageName) or pageName
		local normalizedPageName = pageName:gsub(' ', '_')

		playersIndex = playersIndex + 1
		players[normalizedPageName] = Table.merge(players[normalizedPageName] or {}, {
			pageName = pageName,
			flag = Flags.CountryName(player.flag),
			displayName = player.displayName,
			faction = player.faction and Faction.read(player.faction) or nil,
			index = playersIndex,
			customId = player.customId
		})
	end

	---@param varPrefix string
	---@return boolean
	local wasPresentInMatch = function(varPrefix)
		if not dateTimeInfo.timestamp then return true end

		local joinDate = DateExt.readTimestamp(globalVars:get(varPrefix .. 'joindate'))
		local leaveDate = DateExt.readTimestamp(globalVars:get(varPrefix .. 'leavedate'))

		if (not joinDate) and (not leaveDate) then return true end

		-- need to offset match time to correct timezone as transfers do not have a time associated with them
		local timestampLocal = dateTimeInfo.timestamp + DateExt.getOffsetSeconds(dateTimeInfo.timezoneOffset or '')

		return (not joinDate or (joinDate <= timestampLocal)) and
			(not leaveDate or (leaveDate > timestampLocal))
	end

	local playerIndex = 1
	local varPrefix = teamName .. '_p' .. playerIndex
	local name = globalVars:get(varPrefix)
	-- if we do not find a player for the teamName try to find them for the teamName with underscores
	if not name then
		teamName = teamName:gsub(' ', '_')
		varPrefix = teamName .. '_p' .. playerIndex
		name = globalVars:get(varPrefix)
	end

	while name do
		if options.maxNumPlayers and (playersIndex >= options.maxNumPlayers) then break end

		if options.disregardTransferDates or wasPresentInMatch(varPrefix) then
			insertIntoPlayers{
				pageName = name,
				displayName = globalVars:get(varPrefix .. 'dn'),
				flag = globalVars:get(varPrefix .. 'flag'),
				faction = globalVars:get(varPrefix .. 'faction'),
				-- To be discussed - prefixed with "custom" to make sure it's not confused with e.g. opponentXpY
				-- Used on dota2 for ingame IDs
				customId = globalVars:get(varPrefix .. 'id'),
			}
		end
		playerIndex = playerIndex + 1
		varPrefix = teamName .. '_p' .. playerIndex
		name = globalVars:get(varPrefix)
	end

	Array.forEach(manualPlayersInput.players, insertIntoPlayers)

	--handle `substitutes` input for opponenets
	Array.forEach(manualPlayersInput.substitutions, function(sub)
		if sub.player and not sub.games then
			local normalizedPageName = sub.player.pageName:gsub(' ', '_')
			players[normalizedPageName] = nil
		end

		insertIntoPlayers(sub.substitute)
	end)

	local playersArray = Array.extractValues(players)
	Array.sortInPlaceBy(playersArray, function (player)
		return player.index
	end)

	return playersArray
end

---reads the caster input of a match
---@param match table
---@param options {noSort: boolean?}?
---@return table[]?
function MatchGroupInputUtil.readCasters(match, options)
	options = options or {}
	local casters = {}
	for casterKey, casterName in Table.iter.pairsByPrefix(match, 'caster') do
		table.insert(casters, MatchGroupInputUtil._getCasterInformation(
			casterName,
			match[casterKey .. 'flag'],
			match[casterKey .. 'name']
		))
	end

	if not options.noSort then
		table.sort(casters, function(c1, c2) return c1.displayName:lower() < c2.displayName:lower() end)
	end

	return Logic.nilIfEmpty(casters)
end

---fills in missing information for a given caster
---@param name string
---@param flag string?
---@param displayName string?
---@return {name:string, displayName: string, flag: string?}
function MatchGroupInputUtil._getCasterInformation(name, flag, displayName)
	flag = Logic.emptyOr(flag, globalVars:get(name .. '_flag'))
	displayName = Logic.emptyOr(displayName, globalVars:get(name .. 'dn'))

	if String.isEmpty(flag) or String.isEmpty(displayName) then
		local parent = globalVars:get('tournament_parent') or mw.title.getCurrentTitle().text
		local pageName = mw.ext.TeamLiquidIntegration.resolve_redirect(name):gsub(' ', '_')
		local data = mw.ext.LiquipediaDB.lpdb('broadcasters', {
			conditions = '[[page::' .. pageName .. ']] AND [[parent::' .. parent .. ']]',
			query = 'flag, id',
			limit = 1,
		})[1]
		if type(data) == 'table' then
			flag = String.isNotEmpty(flag) and flag or data.flag
			displayName = String.isNotEmpty(displayName) and displayName or data.id
		end
	end

	if String.isNotEmpty(flag) then
		globalVars:set(name .. '_flag', flag)
	end

	if String.isEmpty(displayName) then
		displayName = name
	end
	globalVars:set(name .. '_dn', displayName)

	return {
		name = name,
		displayName = displayName,
		flag = flag,
	}
end

-- Parse map veto input
---@param match table
---@param allowedVetoes string[]?
---@return {type:string, team1: string?, team2:string?, decider:string?, vetostart:string?}[]?
function MatchGroupInputUtil.getMapVeto(match, allowedVetoes)
	if not match.mapveto then return nil end

	allowedVetoes = allowedVetoes or MatchGroupInputUtil.DEFAULT_ALLOWED_VETOES

	match.mapveto = Json.parseIfString(match.mapveto)

	local vetoTypes = Array.parseCommaSeparatedString(match.mapveto.types)
	local deciders = Array.parseCommaSeparatedString(match.mapveto.decider)
	local deciderIndex = 1

	local data = {}
	for index, vetoType in ipairs(vetoTypes) do
		vetoType = vetoType:lower()
		if not Table.includes(allowedVetoes, vetoType) then
			return nil -- Any invalid input will not store (ie hide) all vetoes.
		end
		if vetoType == 'decider' then
			table.insert(data, {type = vetoType, decider = deciders[deciderIndex]})
			deciderIndex = deciderIndex + 1
		else
			table.insert(data, {type = vetoType, team1 = match.mapveto['t1map'..index], team2 = match.mapveto['t2map'..index]})
		end
	end
	if data[1] then
		data[1].vetostart = match.mapveto.firstpick or ''
		data[1].format = match.mapveto.format
	end
	return data
end

---@param winnerInput integer|string|nil
---@param finishedInput string?
---@return boolean
function MatchGroupInputUtil.isNotPlayed(winnerInput, finishedInput)
	return (type(winnerInput) == 'string' and MatchGroupInputUtil.isNotPlayedInput(winnerInput))
		or (type(finishedInput) == 'string' and MatchGroupInputUtil.isNotPlayedInput(finishedInput))
end

---@param winnerInput integer|string|nil
---@param finishedInput string?
---@return string? #Match Status
function MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
	if MatchGroupInputUtil.isNotPlayed(winnerInput, finishedInput) then
		return MatchGroupInputUtil.MATCH_STATUS.NOT_PLAYED
	end
end

---@param status string
---@param winnerInput integer|string|nil
---@param opponents {score: number, status: string, placement: integer?}[]
---@return integer? # Winner
function MatchGroupInputUtil.getWinner(status, winnerInput, opponents)
	if status == MatchGroupInputUtil.MATCH_STATUS.NOT_PLAYED then
		return nil
	elseif Logic.isNumeric(winnerInput) then
		return tonumber(winnerInput)
	elseif MatchGroupInputUtil.isDraw(opponents, winnerInput) then
		return MatchGroupInputUtil.WINNER_DRAW
	elseif MatchGroupInputUtil.hasSpecialStatus(opponents) then
		return MatchGroupInputUtil.getDefaultWinner(opponents)
	elseif MatchGroupInputUtil.findOpponentWithFirstPlace(opponents) then
		return MatchGroupInputUtil.findOpponentWithFirstPlace(opponents)
	else
		return MatchGroupInputUtil.getHighestScoringOpponent(opponents)
	end
end

---Find the opponent with placement 1
---If multiple opponents share this placement, the first one is returned
---@param opponents {placement: integer?}[]
---@return integer?
function MatchGroupInputUtil.findOpponentWithFirstPlace(opponents)
	local firstPlace = Array.indexOf(opponents, function(opponent)
		return opponent.placement == 1
	end)
	if firstPlace > 0 then
		return firstPlace
	end
end

---Find the opponent with the highest score
---If multiple opponents share the highest score, the first one is returned
---@param opponents {score: number}[]
---@return integer
function MatchGroupInputUtil.getHighestScoringOpponent(opponents)
	local scores = Array.map(opponents, function (opponent)
		return opponent.score or 0
	end)
	local maxScore = Array.max(scores)
	return Array.indexOf(scores, FnUtil.curry(Operator.eq, maxScore))
end

---@param match table
---@param maps {scores: integer[]?, winner: integer?}[]
---@return boolean
function MatchGroupInputUtil.canUseAutoScore(match, maps)
	local matchHasStarted = MatchGroupUtil.computeMatchPhase(match) ~= 'upcoming'
	local anyMapHasWinner = Table.any(maps, function(_, map)
		return Logic.isNotEmpty(map.winner)
	end)
	local anyMapHasScores = Table.any(maps, function(_, map)
		return Logic.isNotEmpty(map.scores)
	end)
	return matchHasStarted or anyMapHasWinner or anyMapHasScores
end

---@param props {walkover: string|integer?, winner: string|integer?, score: string|integer?, opponentIndex: integer}
---@param autoScore? fun(opponentIndex: integer): integer?
---@return integer? #SCORE
---@return string? #STATUS
function MatchGroupInputUtil.computeOpponentScore(props, autoScore)
	if props.walkover then
		local winner = tonumber(props.walkover) or tonumber(props.winner)
		assert(winner, 'Failed to parse walkover input')
		return MatchGroupInputUtil.opponentWalkover(props.walkover, winner == props.opponentIndex)
	end
	local score = props.score
	if Logic.isEmpty(score) and autoScore then
		score = autoScore(props.opponentIndex)
	end

	return MatchGroupInputUtil.parseScoreInput(score)
end

---@param scoreInput string|number|nil
---@return integer? #SCORE
---@return string? #STATUS
function MatchGroupInputUtil.parseScoreInput(scoreInput)
	if Logic.isEmpty(scoreInput) then
		return
	end
	---@cast scoreInput -nil

	if Logic.isNumeric(scoreInput) then
		return tonumber(scoreInput), MatchGroupInputUtil.STATUS.SCORE
	end

	local scoreUpperCase = string.upper(scoreInput)
	assert(Table.includes(MatchGroupInputUtil.STATUS_INPUTS, scoreUpperCase), 'Invalid score input: ' .. scoreUpperCase)
	return MatchGroupInputUtil.SCORE_NOT_PLAYED, scoreUpperCase
end

---@param walkoverInput string|integer #wikicode input
---@param isWinner boolean
---@return integer? #SCORE
---@return string? #STATUS
function MatchGroupInputUtil.opponentWalkover(walkoverInput, isWinner)
	if Logic.isNumeric(walkoverInput) then
		walkoverInput = MatchGroupInputUtil.STATUS.DEFAULT_LOSS
	end

	local walkoverUpperCase = string.upper(walkoverInput)
	assert(Table.includes(MatchGroupInputUtil.STATUS_INPUTS, walkoverUpperCase),
		'Invalid walkover input: ' .. walkoverUpperCase)
	return MatchGroupInputUtil.SCORE_NOT_PLAYED, isWinner and MatchGroupInputUtil.STATUS.DEFAULT_WIN or walkoverUpperCase
end

-- Calculate the match scores based on the map results (counting map wins)
---@param maps {winner: integer?}[]
---@param opponentIndex integer
---@return integer
function MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	return Array.reduce(Array.map(maps, function(map)
		return (map.winner == opponentIndex and 1 or 0)
	end), Operator.add)
end

---@param input string?
---@return boolean
function MatchGroupInputUtil.isNotPlayedInput(input)
	return Table.includes(NOT_PLAYED_INPUTS, input)
end

---@param opponents {status: string, score: number?}[]
---@param winnerInput integer|string|nil
---@return boolean
function MatchGroupInputUtil.isDraw(opponents, winnerInput)
	if Logic.isEmpty(opponents) then return true end
	if tonumber(winnerInput) == 0 then
		return true
	end
	local function opponentHasFinalStatus(opponent)
		return opponent.status ~= MatchGroupInputUtil.STATUS.SCORE and opponent.status ~= MatchGroupInputUtil.STATUS.DRAW
	end
	if Array.any(opponents, opponentHasFinalStatus) then
		return false
	end
	-- Check if all opponents have the same score?
	return #Array.unique(Array.map(opponents, Operator.property('score'))) == 1
end

-- Check if any opponent has a none-standard status
---@param opponents {status: string}[]
---@return boolean
function MatchGroupInputUtil.hasSpecialStatus(opponents)
	return Array.any(opponents, function (opponent)
			return opponent.status and opponent.status ~= MatchGroupInputUtil.STATUS.SCORE end)
end

---@param opponents {status: string?}[]
---@param status string
---@return integer
function MatchGroupInputUtil._opponentWithStatus(opponents, status)
	return Array.indexOf(opponents, function (opponent) return opponent.status == status end)
end

-- function to check for Normal Scores
---@param opponents {status: string?}[]
---@return boolean
function MatchGroupInputUtil.hasScore(opponents)
	return MatchGroupInputUtil._opponentWithStatus(opponents, MatchGroupInputUtil.STATUS.SCORE) ~= 0
end

-- Get the winner when letter results (W/L etc)
---@param opponents {status: string?}[]
---@return integer
function MatchGroupInputUtil.getDefaultWinner(opponents)
	local idx = MatchGroupInputUtil._opponentWithStatus(opponents, MatchGroupInputUtil.STATUS.DEFAULT_WIN)
	return idx > 0 and idx or -1
end


--- Calculate the correct value of the 'placement' for the two-opponent matches/games.
--- Cases:
--- If Winner = OpponentIndex, return 1
--- If Winner = 0, means it was a draw, return 1
--- If Winner = -1, means that mean no team won, returns 2
--- Otherwise return 2
---@param status string?
---@param winner integer?
---@param opponentIndex integer
---@return integer?
function MatchGroupInputUtil.placementFromWinner(status, winner, opponentIndex)
	if status == MatchGroupInputUtil.MATCH_STATUS.NOT_PLAYED then
		return nil
	end
	if winner == 0 or winner == opponentIndex then
		return 1
	end
	return 2
end

---@param match table
---@param maps table[]
---@param opponents {score: integer?}[]
---@return boolean
function MatchGroupInputUtil.matchIsFinished(match, maps, opponents)
	if MatchGroupInputUtil.isNotPlayed(match.winner, match.finished) then
		return true
	end

	local finished = Logic.readBoolOrNil(match.finished)
	if finished ~= nil then
		return finished
	end

	-- If a winner has been set
	if Logic.isNotEmpty(match.winner) then
		return true
	end

	-- If special status has been applied to a team
	if MatchGroupInputUtil.hasSpecialStatus(opponents) then
		return true
	end

	if not MatchGroupInputUtil.hasScore(opponents) then
		return false
	end

	-- If enough time has passed since match started, it should be marked as finished
	local function recordLiveLongEnough(record)
		if not record.timestamp or record.timestamp == DateExt.defaultTimestamp then
			return false
		end
		local longLiveTime = record.dateexact and ASSUME_FINISHED_AFTER.EXACT or ASSUME_FINISHED_AFTER.ESTIMATE
		return NOW > (record.timestamp + longLiveTime)
	end
	if (#maps > 0 and Array.all(maps, recordLiveLongEnough)) or (#maps == 0 and recordLiveLongEnough(match)) then
		return true
	end

	local bestof = match.bestof
	if not bestof then
		return false
	end
	-- TODO: Investigate if bestof = 0 needs to be handled

	return MatchGroupInputUtil.majorityHasBeenWon(bestof, opponents)
end

---@param map {winner: string|nil, finished: string?, bestof: integer?}
---@param opponents? {score: integer?}[]
---@return boolean
function MatchGroupInputUtil.mapIsFinished(map, opponents)
	if MatchGroupInputUtil.isNotPlayed(map.winner, map.finished) then
		return true
	end

	local finished = Logic.readBoolOrNil(map.finished)
	if finished ~= nil then
		return finished
	end

	if Logic.isNotEmpty(map.winner) then
		return true
	end

	if Logic.isNotEmpty(map.finished) then
		return true
	end

	local bestof = map.bestof
	if not bestof or bestof == 0 or not opponents then
		return false
	end

	return MatchGroupInputUtil.majorityHasBeenWon(bestof, opponents)
end

-- Check if all/enough games/rounds have been played for being certain winner
---@param bestof integer
---@param opponents {score: integer?}[]
---@return boolean
function MatchGroupInputUtil.majorityHasBeenWon(bestof, opponents)
	local firstTo = math.floor(bestof / 2)
	if Array.any(opponents, function(opponent) return (tonumber(opponent.score) or 0) > firstTo end) then
		return true
	end
	local scoreSum = Array.reduce(opponents, function(sum, opponent) return sum + (opponent.score or 0) end, 0)
	if scoreSum >= bestof then
		return true
	end
	return false
end

---@param bestOfInput string|integer?
---@param maps table[]
---@return integer?
function MatchGroupInputUtil.getBestOf(bestOfInput, maps)
	return tonumber(bestOfInput) or #maps
end

---@param alias table<string, string>
---@param character string?
---@return string?
function MatchGroupInputUtil.getCharacterName(alias, character)
	if Logic.isEmpty(character) then return nil end
	---@cast character -nil
	return (assert(alias[character:lower()], 'Invalid character:' .. character))
end

---@param players MGIParsedPlayer[]
---@param playerInput string?
---@param playerLink string?
---@return integer?
function MatchGroupInputUtil.findPlayerId(players, playerInput, playerLink)
	if Logic.isEmpty(playerInput) and Logic.isEmpty(playerLink) then
		return
	end

	local playerLinks = Array.map(players, Operator.property('name'))
	local playerIndex = Array.indexOf(playerLinks, FnUtil.curry(Operator.eq, playerLink))
	if playerIndex > 0 then
		return playerIndex
	end

	local playerDisplayNames = Array.map(players, Operator.property('displayname'))
	playerIndex = Array.indexOf(playerDisplayNames, FnUtil.curry(Operator.eq, playerInput))
	if playerIndex > 0 then
		return playerIndex
	end
	mw.log('Player with id ' .. playerInput .. ' not found in opponent data')
end

---@param name string
---@return string
function MatchGroupInputUtil.makeLinkFromName(name)
	return Page.pageifyLink(name) --[[@as string]]
end

---@deprecated
---@alias PlayerInputData {name: string?, link: string?}
---@param playerIds MGIParsedPlayer[]
---@param inputPlayers table[]
---@param indexToPlayer fun(playerIndex: integer): PlayerInputData?
---@param transform fun(playerIndex: integer, playerIdData: MGIParsedPlayer?, playerInputData: PlayerInputData): table?
---@return table, table
function MatchGroupInputUtil.parseParticipants(playerIds, inputPlayers, indexToPlayer, transform)
	local participants = {}
	local unattachedParticipants = {}
	local function parsePlayer(_, playerIndex)
		local playerInputData = indexToPlayer(playerIndex) or {}
		if playerInputData.name and not playerInputData.link then
			playerInputData.link = MatchGroupInputUtil.makeLinkFromName(playerInputData.name)
		end
		local playerId = MatchGroupInputUtil.findPlayerId(playerIds, playerInputData.name, playerInputData.link)
		local toStoreData = transform(playerIndex, playerIds[playerId] or {}, playerInputData)
		if playerId then
			participants[playerId] = toStoreData
		else
			table.insert(unattachedParticipants, toStoreData)
		end
	end
	Array.forEach(inputPlayers, parsePlayer)

	return participants, unattachedParticipants
end

---@param playerIds MGIParsedPlayer[]
---@param inputPlayers table[]
---@param indexToPlayer fun(playerIndex: integer): PlayerInputData?
---@param transform fun(playerIndex: integer, playerIdData: MGIParsedPlayer, playerInputData: PlayerInputData): table?
---@return table
function MatchGroupInputUtil.parseMapPlayers(playerIds, inputPlayers, indexToPlayer, transform)
	local transformedPlayers = {}
	local playerIdToIndex = Table.map(inputPlayers, function(playerIndex)
		local playerInputData = indexToPlayer(playerIndex) or {}
		if playerInputData.name and not playerInputData.link then
			playerInputData.link = MatchGroupInputUtil.makeLinkFromName(playerInputData.name)
		end
		local playerId = MatchGroupInputUtil.findPlayerId(playerIds, playerInputData.name, playerInputData.link)
		transformedPlayers[playerIndex] = transform(playerIndex, playerIds[playerId] or {}, playerInputData)
		if playerId then
			return playerId, playerIndex
		end
		return 0, nil
	end)

	local mappedPlayers = Array.map(playerIds, function(_, playerId)
		local playerIndex = playerIdToIndex[playerId]
		if not playerIndex or not transformedPlayers[playerIndex] then
			return {}
		end
		return Table.extract(transformedPlayers, playerIndex)
	end)

	return Array.extend(mappedPlayers, Array.extractValues(transformedPlayers))
end

---@param match table
---@return table<string, string?>
function MatchGroupInputUtil.getLinks(match)
	local links = Links.transform(match)
	return Table.mapValues(
		Links.makeFullLinksForTableItems(links, 'match', false),
		String.nilIfEmpty
	)
end

--- Warning, both match and standalone match may be mutated
---@param match table
---@param standaloneMatch table
---@return table
function MatchGroupInputUtil.mergeStandaloneIntoMatch(match, standaloneMatch)
	local function ensureTable(input)
		if type(input) == 'table' then
			return input
		end
		if type(input) == 'string' then
			return Json.parseIfTable(input)
		end
	end

	match.matchPage = 'Match:ID_' .. match.bracketid .. '_' .. match.matchid

	-- Update Opponents from the Standlone Match
	match.opponents = standaloneMatch.match2opponents

	-- Update Maps from the Standalone Match
	match.games = standaloneMatch.match2games
	for _, game in ipairs(match.games) do
		game.scores = ensureTable(game.scores)
		game.opponents = ensureTable(game.opponents)
		game.participants = ensureTable(game.participants)
		game.extradata = ensureTable(game.extradata)
	end

	-- Copy all match level records which have value
	for key, value in pairs(standaloneMatch) do
		if Logic.isNotEmpty(value) and not String.startsWith(key, 'match2') then
			match[key] = value
		end
	end

	return match
end

---@alias readDateFunction fun(match: table): {
---date: string,
---dateexact: boolean,
---timestamp: integer,
---timezoneId: string?,
---timezoneOffset:string?,
---}

---@class MatchParserInterface
---@field extractMaps fun(match: table, opponents: table[], mapProps: any?): table[]
---@field getBestOf fun(bestOfInput: string|integer|nil, maps: table[]): integer?
---@field switchToFfa? fun(match: table, opponents: table[]): boolean
---@field calculateMatchScore? fun(maps: table[], opponents: table[]): fun(opponentIndex: integer): integer?
---@field removeUnsetMaps? fun(maps: table[]): table[]
---@field getExtraData? fun(match: table, games: table[], opponents: table[]): table?
---@field adjustOpponent? fun(opponent: MGIParsedOpponent, opponentIndex: integer)
---@field getLinks? fun(match: table, games: table[]): table
---@field getHeadToHeadLink? fun(match: table, opponents: table[]): string?
---@field readDate? readDateFunction
---@field getMode? fun(opponents: table[]): string
---@field readOpponent? fun(match: table, opponentIndex: integer, opponentConfig: readOpponentOptions?):
---MGIParsedOpponent
---@field DEFAULT_MODE? string
---@field DATE_FALLBACKS? string[]
---@field OPPONENT_CONFIG? readOpponentOptions

--- The standard way to process a match input.
---
--- The Parser injection must have the following functions:
--- - extractMaps(match, opponents, mapProps): table[]
--- - getBestOf(bestOfInput, maps): integer?
---
--- It may optionally have the following functions:
--- - switchToFfa(match, opponents): boolean
--- - calculateMatchScore(maps, opponents): fun(opponentIndex): integer?
--- - removeUnsetMaps(maps): table[]
--- - getExtraData(match, games, opponents): table?
--- - adjustOpponent(opponent, opponentIndex)
--- - getLinks(match, games): table?
--- - getHeadToHeadLink(match, opponents): string?
--- - readDate(match): table
--- - getMode(opponents): string?
--- - readOpponent(match, opponentIndex, opponentConfig): MGIParsedOpponent
---
--- Additionally, the Parser may have the following properties:
--- - DEFAULT_MODE: string
--- - DATE_FALLBACKS: string[]
--- - OPPONENT_CONFIG: table
---@param match table
---@param Parser MatchParserInterface?
---@param FfaParser FfaMatchParserInterface?
---@param mapProps any?
---@return table
function MatchGroupInputUtil.standardProcessMatch(match, Parser, FfaParser, mapProps)
	Parser = Parser or {}
	local matchInput = Table.deepCopy(match)

	local dateProps = MatchGroupInputUtil.getMatchDate(Parser, matchInput)
	Table.mergeInto(match, dateProps)

	local readOpponent = Parser.readOpponent or MatchGroupInputUtil.readOpponent
	local opponents = Array.mapIndexes(function(opponentIndex)
		local opponent = readOpponent(match, opponentIndex, Parser.OPPONENT_CONFIG)
		if opponent and Parser.adjustOpponent then
			Parser.adjustOpponent(opponent, opponentIndex)
		end
		return opponent
	end)

	local function defaultSwitchToFfa()
		return #opponents > 2
	end
	local switchToFfa = Parser.switchToFfa or defaultSwitchToFfa
	if FfaParser and switchToFfa(match, opponents) then
		return MatchGroupInputUtil.standardProcessFfaMatch(matchInput, FfaParser, mapProps)
	end

	local games = Parser.extractMaps(match, opponents, mapProps)
	match.bestof = Parser.getBestOf(match.bestof, games)
	games = Parser.removeUnsetMaps and Parser.removeUnsetMaps(games) or games

	match.links = Parser.getLinks and Parser.getLinks(match, games) or MatchGroupInputUtil.getLinks(match)
	if Parser.getHeadToHeadLink then
		match.links.headtohead = Parser.getHeadToHeadLink(match, opponents)
	end

	local autoScoreFunction = (Parser.calculateMatchScore and MatchGroupInputUtil.canUseAutoScore(match, games))
		and Parser.calculateMatchScore(games, opponents)
		or nil
	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.score, opponent.status = MatchGroupInputUtil.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		}, autoScoreFunction)
	end)

	match.finished = MatchGroupInputUtil.matchIsFinished(match, games, opponents)

	if match.finished then
		match.status = MatchGroupInputUtil.getMatchStatus(matchInput.winner, matchInput.finished)
		match.winner = MatchGroupInputUtil.getWinner(match.status, matchInput.winner, opponents)
		Array.forEach(opponents, function(opponent, opponentIndex)
			opponent.placement = MatchGroupInputUtil.placementFromWinner(match.status, match.winner, opponentIndex)
		end)
	end

	match.mode = Parser.getMode and Parser.getMode(opponents)
		or Logic.emptyOr(match.mode, globalVars:get('tournament_mode'), Parser.DEFAULT_MODE)
	Table.mergeInto(match, MatchGroupInputUtil.getTournamentContext(match))

	match.stream = Streams.processStreams(match)
	match.extradata = Parser.getExtraData and Parser.getExtraData(match, games, opponents) or {}

	match.games = games
	match.opponents = opponents

	return match
end

---@class MapParserInterface
---@field calculateMapScore? fun(map: table): fun(opponentIndex: integer): integer?
---@field getExtraData? fun(match: table, game: table, opponents: table[]): table?
---@field getMapName? fun(game: table, mapIndex: integer, match: table): string?, string?
---@field getMapMode? fun(match: table, game: table, opponents: table[]): string?
---@field getPlayersOfMapOpponent? fun(game: table, opponent:table, opponentIndex: integer): table[]
---@field getPatch? fun(game: table): string?
---@field mapIsFinished? fun(map: table, opponents: table[], finishedInput: string?, winnerInput: string?): boolean
---@field extendMapOpponent? fun(map: table, opponentIndex: integer): table
---@field getMapBestOf? fun(map: table): integer?
---@field computeOpponentScore? fun(props: table, autoScore?: fun(opponentIndex: integer):integer?): integer?, string?
---@field getGame? fun(match: table, map:table): string?
---@field ADD_SUB_GROUP? boolean
---@field BREAK_ON_EMPTY? boolean

--- The standard way to process a map input.
---
--- The Parser injection may optionally have the following functions:
--- - calculateMapScore(map): fun(opponentIndex): integer?
--- - getExtraData(match, map, opponents): table?
--- - getMapName(map, mapIndex, match): string?, string?
--- - getMapMode(match, map, opponents): string?
--- - getPlayersOfMapOpponent(map, opponent, opponentIndex): table[]?
--- - getPatch(game): string?
--- - mapIsFinished(map, opponents): boolean
--- - extendMapOpponent(map, opponentIndex): table
--- - getMapBestOf(map): integer?
--- - computeOpponentScore(props, autoScore): integer?, string?
--- - getGame(match, map): string?
---
--- Additionally, the Parser may have the following properties:
--- - ADD_SUB_GROUP boolean?
--- - BREAK_ON_EMPTY boolean?
---@param match table
---@param opponents table[]
---@param Parser MapParserInterface
---@return table
function MatchGroupInputUtil.standardProcessMaps(match, opponents, Parser)
	local maps = {}
	local subGroup = 0
	for key, map, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		if Parser.BREAK_ON_EMPTY and Logic.isDeepEmpty(map) then
			break
		end
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		local dateToUse = map.date or match.date
		Table.mergeInto(map, MatchGroupInputUtil.readDate(dateToUse))

		if Parser.ADD_SUB_GROUP then
			subGroup = tonumber(map.subgroup) or (subGroup + 1)
			map.subgroup = subGroup
		end

		if Parser.getMapName then
			map.map, map.mapDisplayName = Parser.getMapName(map, mapIndex, match)
		end

		if Parser.getMapBestOf then
			map.bestof = Parser.getMapBestOf(map)
		end

		if Parser.getPatch then
			map.patch = Parser.getPatch(map)
		end

		if Parser.getGame then
			map.game = Parser.getGame(match, map)
		end

		map.opponents = Array.map(opponents, function(opponent, opponentIndex)
			local computeOpponentScore = Parser.computeOpponentScore or MatchGroupInputUtil.computeOpponentScore
			local score, status = computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			}, Parser.calculateMapScore and Parser.calculateMapScore(map) or nil)
			local players = Parser.getPlayersOfMapOpponent
				and Parser.getPlayersOfMapOpponent(map, opponent, opponentIndex)
				or nil

			local mapOpponent = {score = score, status = status, players = players}
			if not Parser.extendMapOpponent then
				return mapOpponent
			end
			return Table.merge(Parser.extendMapOpponent(map, opponentIndex), mapOpponent)
		end)

		if Parser.mapIsFinished then
			map.finished = Parser.mapIsFinished(map, opponents, finishedInput, winnerInput)
		else
			map.finished = MatchGroupInputUtil.mapIsFinished(map, map.opponents)
		end

		-- needs map.opponents available!
		if Parser.getMapMode then
			map.mode = Parser.getMapMode(match, map, opponents)
		end

		map.scores = Array.map(map.opponents, Operator.property('score'))
		if map.finished then
			map.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
			map.winner = MatchGroupInputUtil.getWinner(map.status, winnerInput, map.opponents)
		end

		map.extradata = Table.merge(
			{displayname = map.mapDisplayName},
			Parser.getExtraData and Parser.getExtraData(match, map, opponents) or nil
		)

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
end

---@class FfaMatchParserInterface
---@field extractMaps fun(match: table, opponents: table[], mapProps: any?): table[]
---@field parseSettings? fun(match: table, opponentCount: integer): table
---@field calculateMatchScore? fun(maps: table[], opponents: table[]): fun(opponentIndex: integer): integer?
---@field getExtraData? fun(match: table, games: table[], opponents: table[], settings: table): table?
---@field getMode? fun(opponents: table[]): string
---@field readDate? readDateFunction
---@field adjustOpponent? fun(opponent: table[], opponentIndex: integer, match: table)
---@field matchIsFinished? fun(match: table, opponents: table[]): boolean
---@field getMatchWinner? fun(status: string, winnerInput: integer|string|nil, opponents: table[]): integer?
---@field extendOpponentIfFinished? fun(match: table, opponent:table)
---@field DEFAULT_MODE? string
---@field DATE_FALLBACKS? string[]
---@field OPPONENT_CONFIG? readOpponentOptions

--- The standard way to process a match input.
---
--- The Parser injection must have the following functions:
--- - extractMaps(match, opponents, mapProps): table[]
---
--- It may optionally have the following functions:
--- - parseSettings(match, opponentCount): table
--- - calculateMatchScore(maps, opponents): fun(opponentIndex): integer?
--- - getExtraData(match, games, opponents, settings): table?
--- - getMode(opponents): string?
--- - readDate(match): table
--- - adjustOpponent(opponent, opponentIndex, match)
--- - matchIsFinished(match, opponents): boolean
--- - getMatchWinner(status, winnerInput, opponents): integer?
--- - extendOpponentIfFinished(match, opponent)
---
--- Additionally, the Parser may have the following properties:
--- - DEFAULT_MODE: string
--- - DATE_FALLBACKS: string[]
--- - OPPONENT_CONFIG: table
---@param match table
---@param Parser FfaMatchParserInterface
---@param mapProps any?
---@return table
function MatchGroupInputUtil.standardProcessFfaMatch(match, Parser, mapProps)
	local finishedInput = match.finished --[[@as string?]]
	local winnerInput = match.winner --[[@as string?]]

	local dateProps = MatchGroupInputUtil.getMatchDate(Parser, match)
	Table.mergeInto(match, dateProps)

	local opponents = Array.mapIndexes(function(opponentIndex)
		local opponent = MatchGroupInputUtil.readOpponent(match, opponentIndex, Parser.OPPONENT_CONFIG)
		if opponent and Parser.adjustOpponent then
			Parser.adjustOpponent(opponent, opponentIndex, match)
		end
		return opponent
	end)

	local settings = Parser.parseSettings and Parser.parseSettings(match, #opponents)
		or MatchGroupInputUtil.parseSettings(match, #opponents)

	local games = Parser.extractMaps(match, opponents, settings.placementInfo)

	local autoScoreFunction = Parser.calculateMatchScore and Parser.calculateMatchScore(opponents, games) or nil
	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.extradata = opponent.extradata or {}
		opponent.extradata.startingpoints = tonumber(opponent.startingpoints)
		opponent.placement = tonumber(opponent.placement)

		opponent.score, opponent.status = MatchGroupInputUtil.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		}, autoScoreFunction)
	end)

	match.finished = Parser.matchIsFinished and Parser.matchIsFinished(match, opponents)
		or MatchGroupInputUtil.matchIsFinished(match, games, opponents)

	if match.finished then
		match.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)

		local placementOfOpponents = MatchGroupInputUtil.calculatePlacementOfOpponents(opponents)
		Array.forEach(opponents, function(opponent, opponentIndex)
			opponent.placement = placementOfOpponents[opponentIndex]
			opponent.extradata.bg = ((settings.placementInfo or {})[opponent.placement] or {}).status
		end)

		match.winner = Parser.getMatchWinner and Parser.getMatchWinner(match.status, winnerInput, opponents)
			or MatchGroupInputUtil.getWinner(match.status, winnerInput, opponents)

		if Parser.extendOpponentIfFinished then
			Array.forEach(opponents, FnUtil.curry(Parser.extendOpponentIfFinished, match))
		end
	end

	match.mode = Parser.getMode and Parser.getMode(opponents)
		or Logic.emptyOr(match.mode, globalVars:get('tournament_mode'), Parser.DEFAULT_MODE)
	Table.mergeInto(match, MatchGroupInputUtil.getTournamentContext(match))

	match.stream = Streams.processStreams(match)
	match.links = MatchGroupInputUtil.getLinks(match)
	match.extradata = Table.merge({
		mvp = MatchGroupInputUtil.readMvp(match, opponents),
	}, Parser.getExtraData and Parser.getExtraData(match, games, opponents, settings) or {
		placementinfo = settings.placementInfo,
		settings = settings.settings,
	})

	match.games = games
	match.opponents = opponents

	return match
end

---@class FfaMapParserInterface
---@field getMapName? fun(game: table, mapIndex: integer, match: table): string?, string?
---@field getPatch? fun(game: table): string?
---@field getPlayersOfMapOpponent? fun(game: table, opponent:table, opponentIndex: integer): table[]
---@field getMapMode? fun(match: table, game: table, opponents: table[]): string?
---@field getExtraData? fun(match: table, game: table, opponents: table[]): table?
---@field readMapOpponent? fun(map: table, matchOpponent: table, opponentIndex: integer): table
---@field getMapWinner? fun(status: string?, winnerInput: integer|string?, mapOpponents: table[]): integer?
---@field mapIsFinished? fun(match: table, map: table): boolean

--- The standard way to process a ffa map input.
---
--- The Parser injection may optionally have the following functions:
--- - getMapName(map, mapIndex, match): string?, string?
--- - getPatch(map): string?
--- - getMapMode(match, map, opponents): string?
--- - readMapOpponent(map, matchOpponent, opponentIndex): table
--- - getMapWinner(status, winnerInput, mapOpponents)
--- - getExtraData(match, map, opponents): table?
--- - getPlayersOfMapOpponent(map, opponent, opponentMapInput): table[]?
---
---@param match table
---@param opponents table[]
---@param scoreSettings table
---@param Parser FfaMapParserInterface
---@return table
function MatchGroupInputUtil.standardProcessFfaMaps(match, opponents, scoreSettings, Parser)
	local maps = {}
	for key, map, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		if Parser.getMapName then
			map.map, map.mapDisplayName = Parser.getMapName(map, mapIndex, match)
		end

		if Parser.getPatch then
			map.patch = Parser.getPatch(map)
		end

		local dateToUse = map.date or match.date
		Table.mergeInto(map, MatchGroupInputUtil.readDate(dateToUse))

		local opponentParser = Parser.readMapOpponent and FnUtil.curry(Parser.readMapOpponent, map) or function(matchOpponent)
			local opponentMapInput = Json.parseIfString(matchOpponent['m' .. mapIndex])
			local opponent = MatchGroupInputUtil.makeBattleRoyaleMapOpponentDetails(opponentMapInput, scoreSettings)
			if Parser.getPlayersOfMapOpponent then
				opponent.players = Parser.getPlayersOfMapOpponent(map, matchOpponent, opponentMapInput)
			end
			return opponent
		end
		map.opponents = Array.map(opponents, opponentParser)

		map.finished = Parser.mapIsFinished and Parser.mapIsFinished(match, map) or MatchGroupInputUtil.mapIsFinished(map)

		-- needs map.opponents available!
		if Parser.getMapMode then
			map.mode = Parser.getMapMode(match, map, opponents)
		end


		map.scores = Array.map(map.opponents, Operator.property('score'))
		if map.finished then
			map.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
			local getWinner = Parser.getMapWinner or MatchGroupInputUtil.getWinner
			map.winner = getWinner(map.status, winnerInput, map.opponents)
		end

		map.extradata = Table.merge({
			mvp = MatchGroupInputUtil.readMvp(map, opponents),
		}, Parser.getExtraData and Parser.getExtraData(match, map, opponents) or nil)

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
end

---@param opponents table[]
---@return integer[]
function MatchGroupInputUtil.calculatePlacementOfOpponents(opponents)

	local usedPlacements = Array.map(opponents, function()
		return 0
	end)
	Array.forEach(opponents, function(opponent)
		if opponent.placement then
			usedPlacements[opponent.placement] = usedPlacements[opponent.placement] + 1
		end
	end)
	-- Spread out placements if there are duplicates placements
	-- For example 2 placement at 4 means 5 is also taken and the next available is 6
	Array.forEach(usedPlacements, function(count, placement)
		if count > 1 then
			usedPlacements[placement + 1] = usedPlacements[placement + 1] + (count - 1)
			usedPlacements[placement] = 1
		end
	end)

	local placementCount = #usedPlacements
	local function findNextSlot(placement)
		if usedPlacements[placement] == 0 or placement > placementCount then
			return placement
		end
		return findNextSlot(placement + 1)
	end

	local placementOfTeams = {}
	local lastScore
	local lastPlacement = 0

	local function sorter(tbl, key1, key2)
		local opponent1 = tbl[key1]
		local opponent2 = tbl[key2]

		if opponent1.status == MatchGroupInputUtil.STATUS.DEFAULT_WIN then
			return true
		elseif Logic.isNotEmpty(opponent1.status) and opponent1.status ~= MatchGroupInputUtil.STATUS.SCORE then
			return false
		end

		local value1 = tonumber(tbl[key1].score) or -math.huge
		local value2 = tonumber(tbl[key2].score) or -math.huge
		if value1 ~= value2 then
			return value1 > value2
		end

		local place1 = tonumber(opponent1.placement) or -math.huge
		local place2 = tonumber(opponent2.placement) or -math.huge
		return place1 < place2
	end

	for opponentIdx, opp in Table.iter.spairs(opponents, sorter) do
		local placement = opp.placement
		if not placement then
			local thisPlacement = findNextSlot(lastPlacement)
			usedPlacements[thisPlacement] = 1
			if lastScore and opp.score == lastScore then
				placement = lastPlacement
			else
				placement = thisPlacement
			end
		end
		placementOfTeams[opponentIdx] = placement

		lastPlacement = placement
		lastScore = opp.score
	end

	return placementOfTeams
end

---@param match table
---@param opponentCount integer
---@return {placementInfo: table[], settings: table}
function MatchGroupInputUtil.parseSettings(match, opponentCount)
	-- Pre-parse Status colors (up/down etc)
	local statusParsed = {}
	Array.forEach(Array.parseCommaSeparatedString(match.bg, ','), function (status)
		local placements, color = unpack(Array.parseCommaSeparatedString(status, '='))
		local pStart, pEnd = unpack(Array.parseCommaSeparatedString(placements, '-'))
		local pStartNumber = tonumber(pStart) --[[@as integer]]
		local pEndNumber = tonumber(pEnd) or pStartNumber
		Array.forEach(Array.range(pStartNumber, pEndNumber), function(placement)
			statusParsed[placement] = color
		end)
	end)

	-- Info per Placement
	local placementInfo = Array.map(Array.range(1, opponentCount), function(index)
		return {
			placement = index,
			killPoints = tonumber(match['p' .. index .. '_kill']) or tonumber(match.p_kill),
			placementPoints = tonumber(match['p' .. index]) or 0,
			status = statusParsed[index],
		}
	end)

	return {
		placementInfo = placementInfo,
		settings = {
			showGameDetails = Logic.nilOr(Logic.readBoolOrNil(match.showgamedetails), true),
			matchPointThreshold = tonumber(match.matchpoint),
		}
	}
end

---@param scoreDataInput {[1]: string?, [2]: string?, p: string?}?
---@param placementsInfo {killPoints: number, placement: integer, placementPoints: number}[]
---@return table
function MatchGroupInputUtil.makeBattleRoyaleMapOpponentDetails(scoreDataInput, placementsInfo)
	if not scoreDataInput then
		return {}
	end

	local scoreBreakdown = {}

	local placement, kills = tonumber(scoreDataInput[1]), tonumber(scoreDataInput[2])
	local placementEnd = placement
	-- If the placement input is a range (`start-end`, eg. `5-7`), let's fetch both
	if not placement and scoreDataInput[1] and scoreDataInput[1]:match('%d+%-%d+') then
		placement, placementEnd = unpack(Array.map(Array.parseCommaSeparatedString(scoreDataInput[1], '-'), function(place)
			return tonumber(place)
		end))
	end
	local manualPoints = tonumber(scoreDataInput.p)
	if placement or kills then
		local minimumKillPoints = Array.reduce(
			Array.map(placementsInfo, Operator.property('killPoints')),
			math.min,
			math.huge
		)
		-- In case there's a placement range (eg. 5-7), the placement points are calculated as the average of all 3
		local placementPoints = 0
		if placement and placementEnd then
			placementPoints = Array.reduce(Array.range(placement, placementEnd), function (aggregate, place)
				local placementInfo = placementsInfo[place] or {}
				return aggregate + (placementInfo.placementPoints or 0)
			end, 0) / (placementEnd - placement + 1)
		end

		scoreBreakdown.placePoints = placementPoints
		scoreBreakdown.kills = kills

		-- For kill we points, we assume the kill multipler of the highest placement, based on stakeholder suggestion
		-- Likely never to occur, not aware of any tournament format that has this
		local placementInfo = placementsInfo[placement] or {}
		local pointsPerKill = placementInfo.killPoints or minimumKillPoints
		if kills and pointsPerKill ~= math.huge then
			scoreBreakdown.killPoints = scoreBreakdown.kills * pointsPerKill
		end
		scoreBreakdown.totalPoints = (scoreBreakdown.placePoints or 0) + (scoreBreakdown.killPoints or 0)
	end

	local opponent = {
		status = MatchGroupInputUtil.STATUS.SCORE,
		scoreBreakdown = scoreBreakdown,
		placement = placement,
		score = manualPoints or scoreBreakdown.totalPoints,
	}

	if scoreDataInput[1] == '-' then
		opponent.status = MatchGroupInputUtil.STATUS.FORFEIT
		opponent.score = 0
	end

	return opponent
end

---@param matchParser {readDate?: readDateFunction, DATE_FALLBACKS?: string[]}
---@param matchInput table
---@return {date: string, dateexact: boolean, timestamp: integer, timezoneId: string?, timezoneOffset: string?}
function MatchGroupInputUtil.getMatchDate(matchParser, matchInput)
	local defaultDateParser = function(record)
		return MatchGroupInputUtil.readDate(record.date, matchParser.DATE_FALLBACKS)
	end
	local dateParsingFunction = matchParser.readDate or defaultDateParser

	if matchInput.date then
		-- If there's a match date in the input, use it
		return dateParsingFunction(matchInput)
	end

	-- Otherwise, use the date from the earliest game in the match
	local easlierGameTimestamp, earliestGameDateStruct = DateExt.maxTimestamp, nil

	-- We have to loop through the maps unparsed as we haven't parsed the maps at this point yet
	for _, map in Table.iter.pairsByPrefix(matchInput, 'map', {requireIndex = true}) do
		if map.date then
			local gameDateStruct = dateParsingFunction(map)
			if gameDateStruct.timestamp < easlierGameTimestamp then
				earliestGameDateStruct = gameDateStruct
				easlierGameTimestamp = gameDateStruct.timestamp
			end
		end
	end

	-- We couldn't find game date neither, let's use the defaults for the match
	if not earliestGameDateStruct then
		return dateParsingFunction(matchInput)
	end

	return earliestGameDateStruct
end

return MatchGroupInputUtil
