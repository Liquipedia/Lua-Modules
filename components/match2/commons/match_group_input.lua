---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Input
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
local Variables = require('Module:Variables')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')
local WikiSpecific = Lua.import('Module:Brkts/WikiSpecific')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local globalVars = PageVariableNamespace{cached = true}

local DEFAULT_ALLOWED_VETOES = {'decider', 'pick', 'ban', 'defaultban'}

local MatchGroupInput = {}

---@class MatchGroupContext
---@field bracketIndex integer
---@field groupRoundIndex number?
---@field matchSection string?
---@field sectionHeader string?
---@field tournamentParent string

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
---@field pagifyOpponentName boolean?
---@field pagifyPlayerNames boolean?

---@class MatchGroupInputSubstituteInformation
---@field substitute standardPlayer
---@field player standardPlayer?
---@field games string[]
---@field reason string?

local GSL_GROUP_STYLE_DEFAULT_HEADERS = {
	{default = 'Opening Matches'},
	{},
	{winnersfirst = 'Winners Match', losersfirst = 'Elimination Match'},
	{winnersfirst = 'Elimination Match', losersfirst = 'Winners Match'},
	{default = 'Decider Match'},
}
local VALID_GSL_GROUP_STYLES = {
	'winnersfirst',
	'losersfirst',
}

---@param match table
function MatchGroupInput._applyTournamentVarsToMaps(match)
	for mapKey, map in Table.iter.pairsByPrefix(match, 'map') do
		match[mapKey] = MatchGroupInput.getCommonTournamentVars(map, match)
	end
end

---@param matchArgs table
---@param options? {isMatchPage: boolean?}
---@return table
function MatchGroupInput._processMatch(matchArgs, options)
	local match = WikiSpecific.processMatch(matchArgs, options)
	MatchGroupInput._applyTournamentVarsToMaps(match)
	return match
end

---@param bracketId string
---@param args table
---@return table[]
function MatchGroupInput.readMatchlist(bracketId, args)
	local matchKeys = Table.mapArgumentsByPrefix(args, {'M'}, FnUtil.identity)

	local gslGroupStyle = (args.gsl or ''):lower()
	if Table.includes(VALID_GSL_GROUP_STYLES, gslGroupStyle) then
		for matchIndex, header in pairs(GSL_GROUP_STYLE_DEFAULT_HEADERS) do
			args['M' .. matchIndex .. 'header'] = Logic.emptyOr(
				args['M' .. matchIndex .. 'header'],
				header[gslGroupStyle],
				header.default
			)
		end
	end

	return Array.map(matchKeys, function(matchKey, matchIndex)
			local matchId = MatchGroupInput._matchlistMatchIdFromIndex(matchIndex)
			local matchArgs = Json.parse(args[matchKey])

			local context = MatchGroupInput.readContext(matchArgs, args)
			MatchGroupInput.persistContextChanges(context)

			matchArgs.bracketid = bracketId
			matchArgs.matchid = matchId
			local match = MatchGroupInput._processMatch(matchArgs)

			-- Add more fields to bracket data
			match.bracketdata = match.bracketdata or {}
			local bracketData = match.bracketdata

			bracketData.type = 'matchlist'
			bracketData.title = matchIndex == 1 and args.title or nil
			bracketData.header = args['M' .. matchIndex .. 'header'] or bracketData.header
			bracketData.inheritedheader = MatchGroupInput._inheritedHeader(bracketData.header)
			bracketData.matchIndex = matchIndex

			match.parent = context.tournamentParent
			match.matchsection = context.matchSection
			bracketData.bracketindex = context.bracketIndex
			bracketData.groupRoundIndex = context.groupRoundIndex
			bracketData.sectionheader = context.sectionHeader
			bracketData.dateheader = Logic.readBool(match.dateheader) or nil

			bracketData.matchpage = match.matchPage

			local nextMatchId = bracketId .. '_' .. MatchGroupInput._matchlistMatchIdFromIndex(matchIndex + 1)
			bracketData.next = matchIndex ~= #matchKeys and nextMatchId or nil

			return match
		end
	)
end

---@param matchIndex integer
---@return string
function MatchGroupInput._matchlistMatchIdFromIndex(matchIndex)
	return string.format('%04d', matchIndex)
end

---@param bracketId string
---@param matchId string
---@param matchInput table
---@return table[]
function MatchGroupInput.readMatchpage(bracketId, matchId, matchInput)
	local matchArgs = {}
	for key, value in pairs(matchInput) do
		matchArgs[key] = Json.parseIfTable(value) or value
	end

	local function setMatchPageContext()
		local tournamentPage = (mw.ext.LiquipediaDB.lpdb('match2', {
			query = 'parent',
			conditions = '[[match2id::'.. table.concat({bracketId, matchId}, '_') .. ']]',
			limit = 1,
		})[1] or {}).parent
		if not tournamentPage then return end

		local HiddenDataBox = Lua.import('Module:HiddenDataBox/Custom')
		local HdbProps = Table.merge({parent = tournamentPage}, matchArgs)
		HdbProps.date = nil
		HiddenDataBox.run(HdbProps)
	end

	setMatchPageContext()
	matchArgs.parent = globalVars:get('tournament_parent')
	matchArgs.bracketid = bracketId
	matchArgs.matchid = matchId
	local match = MatchGroupInput._processMatch(matchArgs, {isMatchPage = true})
	match.bracketid = 'MATCH_' .. match.bracketid
	return {match}
end

---@param bracketId string
---@param args table
---@param options MatchGroupBaseOptions
---@return table[]
---@return string[]?
function MatchGroupInput.readBracket(bracketId, args, options)
	local warnings = {}
	local templateId = args[1]
	assert(templateId, 'argument \'1\' (templateId) is empty')

	local bracketDatasById = Logic.try(function()
		return MatchGroupInput._fetchBracketDatas(templateId, bracketId)
	end)
		:catch(function(error)
			if String.endsWith(error.message, 'does not exist') then
				table.insert(warnings, error.message .. ' (Maybe [[Template:' .. templateId .. ']] needs to be purged?)')
				return {}
			else
				error(error.message)
			end
		end)
		:get()

	local missingMatchKeys = {}
	local function readMatch(matchId)
		local matchKey = MatchGroupUtil.matchIdToKey(matchId)

		local matchArgs = args[matchKey]
		if not matchArgs then
			if matchKey == 'RxMBR' or matchKey == 'RxMTP' then
				return nil
			end
			table.insert(missingMatchKeys, matchKey)
		end

		matchArgs = Json.parseIfString(matchArgs)
			or Json.parse(Lua.import('Module:Match').toEncodedJson({}))

		local context = MatchGroupInput.readContext(matchArgs, args)
		MatchGroupInput.persistContextChanges(context)

		matchArgs.bracketid = bracketId
		matchArgs.matchid = matchId
		local match = MatchGroupInput._processMatch(matchArgs)

		-- Add more fields to bracket data
		local bracketData = bracketDatasById[matchId]

		---@type MatchGroupUtilBracketData
		match.bracketdata = Table.mergeInto(bracketData, match.bracketdata or {})

		bracketData.type = 'bracket'
		bracketData.header = args[matchKey .. 'header'] or bracketData.header
		bracketData.qualifiedheader = MatchGroupInput._readQualifiedHeader(bracketData, args, matchKey)
		bracketData.inheritedheader = MatchGroupInput._inheritedHeader(bracketData.header)

		bracketData.matchpage = match.matchPage

		match.parent = context.tournamentParent
		match.matchsection = context.matchSection
		bracketData.bracketindex = context.bracketIndex
		bracketData.groupRoundIndex = context.groupRoundIndex
		bracketData.sectionheader = context.sectionHeader

		if match.winnerto then
			bracketData.winnerto = (match.winnertobracket and match.winnertobracket .. '_' or '')
				.. MatchGroupUtil.matchIdFromKey(match.winnerto)
		end
		if match.loserto then
			bracketData.loserto = (match.losertobracket and match.losertobracket .. '_' or '')
				.. MatchGroupUtil.matchIdFromKey(match.loserto)
		end

		-- Remove bracketData.thirdplace if no 3rd place match
		-- TODO omit field instead of storing empty string
		if not args.RxMTP then
			bracketData.thirdplace = nil
		end
		bracketData.thirdplace = bracketData.thirdplace or ''

		-- Remove bracketData.bracketreset if no reset match
		if not args.RxMBR then
			bracketData.bracketreset = nil
		end
		bracketData.bracketreset = bracketData.bracketreset or ''

		if not bracketData.loweredges then
			local opponentCount = 0
			for _, _ in Table.iter.pairsByPrefix(match, 'opponent') do
				opponentCount = opponentCount + 1
			end
			bracketData.loweredges = Array.map(
				MatchGroupUtil.autoAssignLowerEdges(#bracketData.lowerMatchIds, opponentCount),
				MatchGroupUtil.indexTableToRecord
			)
		end

		return match
	end

	local matchIds = Array.extractKeys(bracketDatasById)
	table.sort(matchIds)
	local matches = Array.map(matchIds, readMatch)

	if #missingMatchKeys ~= 0 and options.shouldWarnMissing then
		table.insert(warnings, 'Missing matches: ' .. table.concat(missingMatchKeys, ', '))
	end

	return matches, warnings
end

---@param bracketData table
---@param args table
---@param matchKey string
---@return string?
function MatchGroupInput._readQualifiedHeader(bracketData, args, matchKey)
	if args[matchKey .. 'qualifiedHeader'] then
		return args[matchKey .. 'qualifiedHeader']
	end

	if Logic.isEmpty(bracketData.header) or not Logic.readBool(bracketData.qualwin) then
		return
	end

	return args.qualifiedHeader
end

-- Retrieve bracket data from the template generated bracket on commons
---@param templateId string
---@param bracketId string
---@return table<string, table>
function MatchGroupInput._fetchBracketDatas(templateId, bracketId)
	local matches = mw.ext.Brackets.getCommonsBracketTemplate(templateId)
	assert(type(matches) == 'table')
	assert(#matches ~= 0, 'Template ' .. templateId .. ' does not exist')

	local function replaceBracketId(matchId)
		local _, baseMatchId = MatchGroupUtil.splitMatchId(matchId)
		return (bracketId or '') .. '_' .. baseMatchId
	end

	-- Convert 0 based array to 1 based array
	local function shiftArrayIndex(elems)
		return Array.extend(elems[0], elems)
	end

	return Table.map(matches, function(_, match)
		local bracketData = match.match2bracketdata

		-- Convert 0 based array to 1 based array
		-- TODO this can be removed if the bracketa data is fetched using cross wiki lpdb
		bracketData.loweredges = bracketData.loweredges and shiftArrayIndex(bracketData.loweredges)
		bracketData.lowerMatchIds = bracketData.lowerMatchIds and shiftArrayIndex(bracketData.lowerMatchIds)

		-- Rewrite bracket name of match IDs
		bracketData.bracketreset = String.nilIfEmpty(bracketData.bracketreset) and replaceBracketId(bracketData.bracketreset)
		bracketData.lowerMatchIds = bracketData.lowerMatchIds and Array.map(bracketData.lowerMatchIds, replaceBracketId)
		bracketData.thirdplace = String.nilIfEmpty(bracketData.thirdplace) and replaceBracketId(bracketData.thirdplace)
		bracketData.tolower = String.nilIfEmpty(bracketData.tolower) and replaceBracketId(bracketData.tolower)
		bracketData.toupper = String.nilIfEmpty(bracketData.toupper) and replaceBracketId(bracketData.toupper)
		bracketData.upperMatchId = bracketData.upperMatchId and replaceBracketId(bracketData.upperMatchId)

		-- Remove/convert deprecated fields
		bracketData.lowerMatchIds = bracketData.lowerMatchIds or MatchGroupUtil.computeLowerMatchIdsFromLegacy(bracketData)
		bracketData.tolower = bracketData.lowerMatchIds[#bracketData.lowerMatchIds] or ''
		bracketData.toupper = bracketData.lowerMatchIds[#bracketData.lowerMatchIds - 1] or ''
		bracketData.rootIndex = nil

		-- Don't store advanceSpots
		bracketData.advancespots = nil

		local _, baseMatchId = MatchGroupUtil.splitMatchId(match.match2id)
		return baseMatchId, bracketData
	end)
end

---@param matches table<string, table>
---@param args table
function MatchGroupInput.applyOverrideArgs(matches, args)
	local matchGroupType = matches[1].bracketData.type

	if args.title then
		matches[1].bracketData.title = args.title
	end

	if matchGroupType == 'matchlist' then
		for index, match in ipairs(matches) do
			match.bracketData.header = args['M' .. index .. 'header'] or match.bracketData.header
		end
	else
		for _, match in ipairs(matches) do
			local _, baseMatchId = MatchGroupUtil.splitMatchId(match.matchId)
			assert(baseMatchId, 'Invalid matchId "' .. match.matchId .. '"')
			local matchKey = MatchGroupUtil.matchIdToKey(baseMatchId)
			match.bracketData.header = args[matchKey .. 'header'] or match.bracketData.header
		end
	end
end

local getContentLanguage = FnUtil.memoize(mw.getContentLanguage)

---@param headerInput string?
---@return string?
function MatchGroupInput._inheritedHeader(headerInput)
	local inheritedHeader = headerInput or globalVars:get('inheritedHeader')
	globalVars:set('inheritedHeader', inheritedHeader)
	return inheritedHeader
end

---@param dateString string?
---@param dateFallbacks string[]?
---@return {date: string, dateexact: boolean, timestamp: integer, timezoneId: string?, timezoneOffset: string?}
function MatchGroupInput.readDate(dateString, dateFallbacks)
	if dateString then
		-- Extracts the '-4:00' out of <abbr data-tz="-4:00" title="Eastern Daylight Time (UTC-4)">EDT</abbr>
		local timezoneOffset = dateString:match('data%-tz%=[\"\']([%d%-%+%:]+)[\"\']')
		local timezoneId = dateString:match('>(%a-)<')
		local matchDate = mw.text.split(dateString, '<', true)[1]:gsub('-', '')
		local isDateExact = String.contains(matchDate .. (timezoneOffset or ''), '[%+%-]')
		local date = getContentLanguage():formatDate('c', matchDate .. (timezoneOffset or ''))
		return {
			date = date,
			dateexact = isDateExact,
			timezoneId = timezoneId,
			timezoneOffset = timezoneOffset,
			timestamp = DateExt.readTimestamp(dateString),
		}

	elseif dateFallbacks then
		table.insert(dateFallbacks, DateExt.defaultDate)
		local suggestedDate = Variables.varDefaultMulti(unpack(dateFallbacks))
		local missingDateCount = globalVars:get('num_missing_dates') or 0
		globalVars:set('num_missing_dates', missingDateCount + 1)
		local inexactDateString = (suggestedDate or '') .. ' + ' .. missingDateCount .. ' second'
		local date = getContentLanguage():formatDate('c', inexactDateString)
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

---Parses the match group context.
---The match group context describes where a match group is relative to the tournament page.
---@param matchArgs table
---@param matchGroupArgs table
---@return MatchGroupContext
function MatchGroupInput.readContext(matchArgs, matchGroupArgs)
	return {
		bracketIndex = tonumber(globalVars:get('match2bracketindex')) or 0,
		groupRoundIndex = MatchGroupInput.readGroupRoundIndex(matchArgs, matchGroupArgs),
		matchSection = matchArgs.matchsection or matchGroupArgs.matchsection or globalVars:get('matchsection'),
		sectionHeader = matchGroupArgs.section or globalVars:get('bracket_header'),
		tournamentParent = globalVars:get('tournament_parent'),
	}
end

---@param matchArgs table
---@param matchGroupArgs table
---@return number?
function MatchGroupInput.readGroupRoundIndex(matchArgs, matchGroupArgs)
	if matchArgs.round then
		return tonumber(matchArgs.round)
	end
	if matchGroupArgs.round then
		return tonumber(matchGroupArgs.round)
	end

	local matchSection = matchArgs.matchsection or matchGroupArgs.matchsection or globalVars:get('matchsection')
	-- Usually 'Round N' but can also be 'Day N', 'Week N', etc.
	local roundIndex = matchSection and matchSection:match(' (%d+)$')
	return roundIndex and tonumber(roundIndex)
end

---Saves changes to the match group context, as set by match group args, in page variables.
---@param context MatchGroupContext
function MatchGroupInput.persistContextChanges(context)
	globalVars:set('bracket_header', context.sectionHeader)
	globalVars:set('matchsection', context.matchSection)
end

---Fetches the LPDB records of a match group containing standalone matches.
---Standalone matches are specified from individual match pages in the Match namespace.
---@param bracketId string
---@return match2[]
MatchGroupInput.fetchStandaloneMatchGroup = FnUtil.memoize(function(bracketId)
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
function MatchGroupInput.fetchStandaloneMatch(matchId)
	local bracketId, _ = MatchGroupUtil.splitMatchId(matchId)
	assert(bracketId, 'Invalid matchId "' .. matchId .. '"')
	local matches = MatchGroupInput.fetchStandaloneMatchGroup(bracketId)
	return Array.find(matches, function(match)
		return match.match2id == matchId
	end)
end

---@param match table
---@param opponentIndex integer
---@param options readOpponentOptions
---@return table?
function MatchGroupInput.readOpponent(match, opponentIndex, options)
	options = options or {}
	local opponentInput = Json.parseIfString(Table.extract(match, 'opponent' .. opponentIndex))
	if not opponentInput then
		return opponentIndex <= 2 and Opponent.blank() or nil
	end

	local opponent = Opponent.readOpponentArgs(opponentInput)
	if Opponent.isBye(opponent) then
		return {type = Opponent.literal, name = 'BYE'}
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
	opponent.name = Opponent.toName(opponent)

	local substitutions
	if opponent.type == Opponent.team and Logic.isNotEmpty(opponent.name) then
		local manualPlayersInput = MatchGroupInput.extractManualPlayersInput(match, opponentIndex, opponentInput)
		substitutions = manualPlayersInput.substitutions
		--a variation of `MatchGroupInput.readPlayersOfTeam` that returns a player array and the substitutions data
		opponent.players = MatchGroupInput.readPlayersOfTeamNew(
			opponent.name,
			manualPlayersInput,
			options,
			{timestamp = match.timestamp, timezoneOffset = match.timezoneOffset}
		)
	end

	if options.pagifyOpponentName then
		opponent.name = Page.pageifyLink(opponent.name)
	end

	if options.pagifyPlayerNames then
		Array.forEach(opponent.players, function(player)
			player.pageName = Page.pageifyLink(player.pageName)
		end)
	end

	return MatchGroupInput.mergeRecordWithOpponent(opponentInput, opponent, substitutions)
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
---@return table
function MatchGroupInput.mergeRecordWithOpponent(record, opponent, substitutions)
	if opponent.type == Opponent.team then
		record.template = opponent.template or record.template
		record.icon = opponent.icon or record.icon
		record.icondark = opponent.icondark or record.icondark
	end

	if not record.match2players and Logic.isNotEmpty(opponent.players) then
		record.match2players = Array.map(opponent.players, function(player)
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
function MatchGroupInput.getCommonTournamentVars(obj, parent)
	parent = parent or {}
	obj.game = Logic.emptyOr(obj.game, parent.game, Variables.varDefault('tournament_game'))
	obj.icon = Logic.emptyOr(obj.icon, parent.icon, Variables.varDefault('tournament_icon'))
	obj.icondark = Logic.emptyOr(obj.iconDark, parent.icondark, Variables.varDefault('tournament_icondark'))
	obj.liquipediatier = Logic.emptyOr(
		obj.liquipediatier,
		parent.liquipediatier,
		Variables.varDefault('tournament_liquipediatier')
	)
	obj.liquipediatiertype = Logic.emptyOr(
		obj.liquipediatiertype,
		parent.liquipediatiertype,
		Variables.varDefault('tournament_liquipediatiertype')
	)
	obj.series = Logic.emptyOr(obj.series, parent.series, Variables.varDefault('tournament_series'))
	obj.shortname = Logic.emptyOr(obj.shortname, parent.shortname, Variables.varDefault('tournament_shortname'))
	obj.tickername = Logic.emptyOr(obj.tickername, parent.tickername, Variables.varDefault('tournament_tickername'))
	obj.tournament = Logic.emptyOr(obj.tournament, parent.tournament, Variables.varDefault('tournament_name'))
	obj.type = Logic.emptyOr(obj.type, parent.type, Variables.varDefault('tournament_type'))
	obj.patch = Logic.emptyOr(obj.patch, parent.patch, Variables.varDefault('tournament_patch'))
	obj.date = Logic.emptyOr(obj.date, parent.date)
	obj.mode = Logic.emptyOr(obj.mode, parent.mode)

	return obj
end

---@param match table
---@return {players: MatchGroupMvpPlayer[], points: integer}?
function MatchGroupInput.readMvp(match)
	if not match.mvp then return end
	local mvppoints = match.mvppoints or 1

	-- Split the input
	local players = mw.text.split(match.mvp, ',')

	-- parse the players to get their information
	local parsedPlayers = Array.map(players, function(player, playerIndex)
		local link = mw.ext.TeamLiquidIntegration.resolve_redirect(mw.text.split(player, '|')[1]):gsub(' ', '_')
		for _, opponent in Table.iter.pairsByPrefix(match, 'opponent') do
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
function MatchGroupInput.extractManualPlayersInput(match, opponentIndex, opponentInput)
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
			pageName = playerName,
			displayName = playersData[playerPrefix .. 'dn'],
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
function MatchGroupInput.readPlayersOfTeamNew(teamName, manualPlayersInput, options, dateTimeInfo)
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

		local joinDate = DateExt.readTimestamp(Variables.varDefault(varPrefix .. 'joindate'))
		local leaveDate = DateExt.readTimestamp(Variables.varDefault(varPrefix .. 'leavedate'))

		if (not joinDate) and (not leaveDate) then return true end

		-- need to offset match time to correct timezone as transfers do not have a time associated with them
		local timestampLocal = dateTimeInfo.timestamp + DateExt.getOffsetSeconds(dateTimeInfo.timezoneOffset or '')

		return (not joinDate or (joinDate <= timestampLocal)) and
			(not leaveDate or (leaveDate > timestampLocal))
	end

	local playerIndex = 1
	local varPrefix = teamName .. '_p' .. playerIndex
	local name = Variables.varDefault(varPrefix)
	-- if we do not find a player for the teamName try to find them for the teamName with underscores
	if not name then
		teamName = teamName:gsub(' ', '_')
		varPrefix = teamName .. '_p' .. playerIndex
	end

	while name do
		if options.maxNumPlayers and (playersIndex >= options.maxNumPlayers) then break end

		if wasPresentInMatch(varPrefix) then
			insertIntoPlayers{
				pageName = name,
				displayName = Variables.varDefault(varPrefix .. 'dn'),
				flag = Variables.varDefault(varPrefix .. 'flag'),
				faction = Variables.varDefault(varPrefix .. 'faction'),
			}
		end
		playerIndex = playerIndex + 1
		varPrefix = teamName .. '_p' .. playerIndex
		name = Variables.varDefault(varPrefix)
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

---reads the players of a team from input and wiki variables
---@deprecated
---@param match table
---@param opponentIndex integer
---@param teamName string
---@param options MatchGroupInputReadPlayersOfTeamOptions?
---@return table
function MatchGroupInput.readPlayersOfTeam(match, opponentIndex, teamName, options)
	options = options or {}

	local opponent = match['opponent' .. opponentIndex]
	local players = {}
	local playersIndex = 0

	local insertIntoPlayers = function(player)
		if type(player) ~= 'table' or Logic.isEmpty(player) or Logic.isEmpty(player.name or player.pageName) then
			return
		end

		player.name = Logic.emptyOr(player.name, player.pageName) --[[@as string]]
		player.name = options.resolveRedirect and mw.ext.TeamLiquidIntegration.resolve_redirect(player.name) or player.name
		player.name = options.applyUnderScores and player.name:gsub(' ', '_') or player.name
		player.flag = Flags.CountryName(player.flag)
		player.displayname = Logic.emptyOr(player.displayname, player.displayName)
		playersIndex = playersIndex + 1
		player.index = playersIndex

		players[player.name] = players[player.name] or {}
		Table.mergeInto(players[player.name], player)
	end

	local playerIndex = 1
	local varPrefix = teamName .. '_p' .. playerIndex
	local name = Variables.varDefault(varPrefix)
	while name do
		if options.maxNumPlayers and (playersIndex >= options.maxNumPlayers) then break end

		local wasPresentInMatch = function()
			if not match.timestamp then return true end

			local joinDate = DateExt.readTimestamp(Variables.varDefault(varPrefix .. 'joindate', ''))
			local leaveDate = DateExt.readTimestamp(Variables.varDefault(varPrefix .. 'leavedate', ''))

			if (not joinDate) and (not leaveDate) then return true end

			-- need to offset match time to correct timezone as transfers do not have a time associated with them
			local timestampLocal = match.timestamp + DateExt.getOffsetSeconds(match.timezoneOffset or '')

			return (not joinDate or (joinDate <= timestampLocal)) and
				(not leaveDate or (leaveDate > timestampLocal))
		end

		if wasPresentInMatch() then
			insertIntoPlayers{
				pageName = name,
				displayName = Variables.varDefault(varPrefix .. 'dn'),
				flag = Variables.varDefault(varPrefix .. 'flag'),
			}
		end
		playerIndex = playerIndex + 1
		varPrefix = teamName .. '_p' .. playerIndex
		name = Variables.varDefault(varPrefix)
	end

	--players from manual input as `opponnetX_pY`
	for _, player in Table.iter.pairsByPrefix(match, 'opponent' .. opponentIndex .. '_p') do
		local playerTable = Json.parseIfString(player) or {}
		insertIntoPlayers(playerTable)
	end

	--players from manual input in `opponent.players`
	local playersData = Json.parseIfString(opponent.players) or {}
	for playerPrefix, playerName in Table.iter.pairsByPrefix(playersData, 'p') do
		insertIntoPlayers{
			pageName = playerName,
			displayName = playersData[playerPrefix .. 'dn'],
			flag = playersData[playerPrefix .. 'flag'],
		}
	end

	---@param playerData table|string|nil
	---@return standardPlayer?
	local getStandardPlayer = function(playerData)
		if not playerData then return end
		playerData = type(playerData) == 'string' and {playerData} or playerData
		local player = {
			displayName = Logic.emptyOr(playerData.displayName, playerData.displayname, playerData[1] or playerData.name),
			pageName = Logic.emptyOr(playerData.pageName, playerData.pagename, playerData.link),
			flag = playerData.flag,
		}
		if Logic.isEmpty(player.displayName) then return end
		player = PlayerExt.populatePlayer(player)
		player.pageName = options.applyUnderScores and player.pageName:gsub(' ', '_') or player.pageName
		return player
	end

	local substitutions, parseFailure = Json.parseStringified(opponent.substitutes)
	if parseFailure then
		substitutions = {}
	end

	--handle `substitutes` input for opponenets
	Array.forEach(substitutions, function(substitution)
		if type(substitution) ~= 'table' or not substitution['in'] then return end
		local substitute = getStandardPlayer(substitution['in'])

		local subbedGames = substitution['games']

		local player = getStandardPlayer(substitution['out'])
		if player then
			players[player.pageName] = subbedGames and players[player.pageName] or nil
		end

		opponent.extradata = Table.merge({substitutions = {}}, opponent.extradata or {})
		table.insert(opponent.extradata.substitutions, {
			substitute = substitute,
			player = player,
			games = subbedGames and Array.map(mw.text.split(subbedGames, ';'), String.trim) or nil,
			reason = substitution['reason'],
		})

		insertIntoPlayers(substitute)
	end)

	opponent.match2players = Array.extractValues(players)
	Array.sortInPlaceBy(opponent.match2players, function (player)
		return player.index
	end)

	return match
end

---reads the caster input of a match
---@param match table
---@param options {noSort: boolean?}?
---@return string?
function MatchGroupInput.readCasters(match, options)
	options = options or {}
	local casters = {}
	for casterKey, casterName in Table.iter.pairsByPrefix(match, 'caster') do
		table.insert(casters, MatchGroupInput._getCasterInformation(
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
function MatchGroupInput._getCasterInformation(name, flag, displayName)
	flag = Logic.emptyOr(flag, Variables.varDefault(name .. '_flag'))
	displayName = Logic.emptyOr(displayName, Variables.varDefault(name .. 'dn'))

	if String.isEmpty(flag) or String.isEmpty(displayName) then
		local parent = Variables.varDefault(
			'tournament_parent',
			mw.title.getCurrentTitle().text
		)
		local pageName = mw.ext.TeamLiquidIntegration.resolve_redirect(name):gsub(' ', '_')
		local data = mw.ext.LiquipediaDB.lpdb('broadcasters', {
			conditions = '[[page::' .. pageName .. ']] AND [[parent::' .. parent .. ']]',
			query = 'flag, id',
			limit = 1,
		})
		if type(data) == 'table' and data[1] then
			flag = String.isNotEmpty(flag) and flag or data[1].flag
			displayName = String.isNotEmpty(displayName) and displayName or data[1].id
		end
	end

	if String.isNotEmpty(flag) then
		Variables.varDefine(name .. '_flag', flag)
	end

	if String.isEmpty(displayName) then
		displayName = name
	end
	Variables.varDefine(name .. '_dn', displayName)

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
function MatchGroupInput.getMapVeto(match, allowedVetoes)
	if not match.mapveto then return nil end

	allowedVetoes = allowedVetoes or DEFAULT_ALLOWED_VETOES

	match.mapveto = Json.parseIfString(match.mapveto)

	local vetoTypes = Array.parseCommaSeparatedString(match.mapveto.types)
	local deciders = Array.parseCommaSeparatedString(match.mapveto.decider)
	local vetoStart = match.mapveto.firstpick or ''
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
		data[1].vetostart = vetoStart
	end
	return data
end

---@param opponents table[]
---@return boolean
function MatchGroupInput.isDraw(opponents)
	if Logic.isEmpty(opponents) then return true end
	if Array.any(opponents, function (opponent) return opponent.status ~= 'S' and opponent.status ~= 'D' end) then
		return false
	end
	return #Array.unique(Array.map(opponents, Operator.property('score'))) == 1
end

-- Check if any opponent has a none-standard status
---@param opponents table[]
---@return boolean
function MatchGroupInput.hasSpecialStatus(opponents)
	return Array.any(opponents, function (opponent) return opponent.status ~= 'S' end)
end

-- function to check for forfeits
---@param opponents table[]
---@return boolean
function MatchGroupInput.hasForfeit(opponents)
	return Array.any(opponents, function (opponent) return opponent.status == 'FF' end)
end

-- function to check for DQ's
---@param opponents table[]
---@return boolean
function MatchGroupInput.hasDisqualified(opponents)
	return Array.any(opponents, function (opponent) return opponent.status == 'DQ' end)
end

-- function to check for W/L
---@param opponents table[]
---@return boolean
function MatchGroupInput.hasDefaultWinLoss(opponents)
	return Array.any(opponents, function (opponent) return opponent.status == 'L' end)
end

-- Get the winner when resulttype=default
---@param opponents table[]
---@return integer
function MatchGroupInput.getDefaultWinner(opponents)
	local idx = Array.indexOf(opponents, function(opponent) return opponent.status == 'W' end)
	return idx > 0 and idx or -1
end

-- Set the field 'placement' for the two participants in the opponenets list.
-- Set the placementWinner field to the winner, and placementLoser to the other team
-- Special cases:
-- If Winner = 0, that means draw, and placementLoser isn't used. Both teams will get placementWinner
-- If Winner = -1, that mean no team won, and placementWinner isn't used. Both teams will get placementLoser
---@param opponents table[]
---@param winner integer?
---@param placementWinner integer
---@param placementLoser integer
---@return table[]
function MatchGroupInput.setPlacement(opponents, winner, placementWinner, placementLoser)
	if not opponents or #opponents ~= 2 then
		return opponents
	end

	local loserIdx
	local winnerIdx
	if winner == 1 then
		winnerIdx = 1
		loserIdx = 2
	elseif winner == 2 then
		winnerIdx = 2
		loserIdx = 1
	elseif winner == 0 then
		-- Draw; idx of winner/loser doesn't matter
		-- since loser and winner gets the same placement
		placementLoser = placementWinner
		winnerIdx = 1
		loserIdx = 2
	elseif winner == -1 then
		-- No Winner (both loses). For example if both teams DQ.
		-- idx's doesn't matter
		placementWinner = placementLoser
		winnerIdx = 1
		loserIdx = 2
	else
		error('setPlacement: Unexpected winner')
		return opponents
	end
	opponents[winnerIdx].placement = placementWinner
	opponents[loserIdx].placement = placementLoser

	return opponents
end

---@param alias table<string, string>
---@param character string?
---@return string?
function MatchGroupInput.getCharacterName(alias, character)
	if Logic.isEmpty(character) then return nil end
	---@cast character -nil
	return (assert(alias[character:lower()], 'Invalid character:' .. character))
end

return MatchGroupInput
