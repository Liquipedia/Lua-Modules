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
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Links = Lua.import('Module:Links')
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
	FORFIET = 'FF',
	DISQUALIFIED = 'DQ',
}

MatchGroupInputUtil.STATUS = Table.copy(MatchGroupInputUtil.STATUS_INPUTS)
MatchGroupInputUtil.STATUS.SCORE = 'S'

MatchGroupInputUtil.RESULT_TYPE = {
	DEFAULT = 'default',
	NOT_PLAYED = 'np',
	DRAW = 'draw',
}
MatchGroupInputUtil.WALKOVER = {
	FORFIET = 'ff',
	DISQUALIFIED = 'dq',
	NO_SCORE = 'l',
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

---@deprecated
---@class MatchGroupInputReadPlayersOfTeamOptions
---@field maxNumPlayers integer?
---@field resolveRedirect boolean?
---@field applyUnderScores boolean?

---@class readOpponentOptions
---@field maxNumPlayers integer?
---@field resolveRedirect boolean?
---@field pagifyTeamNames boolean?

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
---@return {players: MatchGroupMvpPlayer[], points: integer}?
function MatchGroupInputUtil.readMvp(match)
	if not match.mvp then return end
	local mvppoints = match.mvppoints or 1

	-- Split the input
	local players = mw.text.split(match.mvp, ',')

	-- parse the players to get their information
	local opponents = MatchGroupUtil.normalizeSubtype(match, 'opponent')
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

	---@param player {pageName: string, displayName: string?, flag: string?, faction: string?}
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

		if wasPresentInMatch(varPrefix) then
			insertIntoPlayers{
				pageName = name,
				displayName = globalVars:get(varPrefix .. 'dn'),
				flag = globalVars:get(varPrefix .. 'flag'),
				faction = globalVars:get(varPrefix .. 'faction'),
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
---@return string?
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

	return Table.isNotEmpty(casters) and Json.stringify(casters) or nil
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

---Should only be called on finished matches or maps
---@param winnerInput integer|string|nil
---@param finishedInput string?
---@param opponents {score: number?, status: string}[]
---@return string? #Result Type
function MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponents)
	if MatchGroupInputUtil.isNotPlayed(winnerInput, finishedInput) then
		return MatchGroupInputUtil.RESULT_TYPE.NOT_PLAYED
	end

	if MatchGroupInputUtil.isDraw(opponents, winnerInput) then
		return MatchGroupInputUtil.RESULT_TYPE.DRAW
	end

	if MatchGroupInputUtil.hasSpecialStatus(opponents) then
		return MatchGroupInputUtil.RESULT_TYPE.DEFAULT
	end
end

---@param resultType string?
---@param winnerInput integer|string|nil
---@param opponents {score: number, status: string, placement: integer?}[]
---@return integer? # Winner
function MatchGroupInputUtil.getWinner(resultType, winnerInput, opponents)
	if resultType == MatchGroupInputUtil.RESULT_TYPE.NOT_PLAYED then
		return nil
	elseif Logic.isNumeric(winnerInput) then
		return tonumber(winnerInput)
	elseif resultType == MatchGroupInputUtil.RESULT_TYPE.DRAW then
		return MatchGroupInputUtil.WINNER_DRAW
	elseif resultType == MatchGroupInputUtil.RESULT_TYPE.DEFAULT then
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
	local scores = Array.map(opponents, Operator.property('score'))
	local maxScore = Array.max(scores)
	return Array.indexOf(scores, FnUtil.curry(Operator.eq, maxScore))
end

---@param resultType string?
---@param opponents {status: string}[]
---@return string? # Walkover Type
function MatchGroupInputUtil.getWalkover(resultType, opponents)
	if resultType == MatchGroupInputUtil.RESULT_TYPE.DEFAULT then
		return MatchGroupInputUtil.getWalkoverType(opponents)
	end
end

---@param opponents {status: string}[]
---@return string?
function MatchGroupInputUtil.getWalkoverType(opponents)
	if MatchGroupInputUtil.hasForfeit(opponents) then
		return MatchGroupInputUtil.WALKOVER.FORFIET
	elseif MatchGroupInputUtil.hasDisqualified(opponents) then
		return MatchGroupInputUtil.WALKOVER.DISQUALIFIED
	elseif MatchGroupInputUtil.hasDefaultWinLoss(opponents) then
		return MatchGroupInputUtil.WALKOVER.NO_SCORE
	end
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

-- function to check for forfeits
---@param opponents {status: string?}[]
---@return boolean
function MatchGroupInputUtil.hasForfeit(opponents)
	return MatchGroupInputUtil._opponentWithStatus(opponents, MatchGroupInputUtil.STATUS.FORFIET) ~= 0
end

-- function to check for DQ's
---@param opponents {status: string?}[]
---@return boolean
function MatchGroupInputUtil.hasDisqualified(opponents)
	return MatchGroupInputUtil._opponentWithStatus(opponents, MatchGroupInputUtil.STATUS.DISQUALIFIED) ~= 0
end

-- function to check for W/L
---@param opponents {status: string?}[]
---@return boolean
function MatchGroupInputUtil.hasDefaultWinLoss(opponents)
	return MatchGroupInputUtil._opponentWithStatus(opponents, MatchGroupInputUtil.STATUS.DEFAULT_LOSS) ~= 0
end

-- function to check for Normal Scores
---@param opponents {status: string?}[]
---@return boolean
function MatchGroupInputUtil.hasScore(opponents)
	return MatchGroupInputUtil._opponentWithStatus(opponents, MatchGroupInputUtil.STATUS.SCORE) ~= 0
end

-- Get the winner when resulttype=default
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
---@param resultType string?
---@param winner integer?
---@param opponentIndex integer
---@return integer?
function MatchGroupInputUtil.placementFromWinner(resultType, winner, opponentIndex)
	if resultType == MatchGroupInputUtil.RESULT_TYPE.NOT_PLAYED then
		return nil
	end
	if winner == 0 or winner == opponentIndex then
		return 1
	end
	return 2
end

---@param match table
---@param opponents {score: integer?}[]
---@return boolean
function MatchGroupInputUtil.matchIsFinished(match, opponents)
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
	local threshold = match.dateexact and ASSUME_FINISHED_AFTER.EXACT or ASSUME_FINISHED_AFTER.ESTIMATE
	if match.timestamp ~= DateExt.defaultTimestamp and (match.timestamp + threshold) < NOW then
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

---@generic T:table
---@param opponentIndex integer
---@return fun(playerIndex: integer, data: T): string, T
function MatchGroupInputUtil.prefixPartcipants(opponentIndex)
	return function(playerIndex, data)
		return opponentIndex .. '_' .. playerIndex, data
	end
end

---@param match table
---@return { [string]: string }
function MatchGroupInputUtil.getLinks(match)
	local links = Links.transform(match)
	return Table.map(links, function(value, key)
		return key, Links.makeFullLink(key, value, 'match')
	end)
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

return MatchGroupInputUtil
