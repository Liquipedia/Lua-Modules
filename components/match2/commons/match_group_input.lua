---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Input
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local WikiSpecific = Lua.import('Module:Brkts/WikiSpecific')

local globalVars = PageVariableNamespace{cached = true}

local MatchGroupInput = {}

---@class MatchGroupContext
---@field bracketIndex integer
---@field groupRoundIndex number?
---@field matchSection string?
---@field sectionHeader string?
---@field tournamentParent string

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
	for _, map in ipairs(MatchGroupUtil.normalizeSubtype(match, 'map')) do
		MatchGroupInputUtil.getCommonTournamentVars(map, match)
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

	return Array.map(matchKeys, Logic.wrapTryOrLog(function(matchKey, matchIndex)
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
	))
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
		local match = Logic.wrapTryOrLog(MatchGroupInput._processMatch)(matchArgs)

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
			local opponents = MatchGroupUtil.normalizeSubtype(match, 'opponent')
			bracketData.loweredges = Array.map(
				MatchGroupUtil.autoAssignLowerEdges(#bracketData.lowerMatchIds, #opponents),
				MatchGroupUtil.indexTableToRecord
			)
		end

		return match
	end

	local matchIds = Array.extractKeys(bracketDatasById)
	table.sort(matchIds)
	local matches = Array.map(matchIds, Logic.wrapTryOrLog(readMatch))

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

---@param headerInput string?
---@return string?
function MatchGroupInput._inheritedHeader(headerInput)
	local inheritedHeader = headerInput or globalVars:get('inheritedHeader')
	globalVars:set('inheritedHeader', inheritedHeader)
	return inheritedHeader
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

return MatchGroupInput
