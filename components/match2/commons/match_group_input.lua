---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Input
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FeatureFlag = require('Module:FeatureFlag')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local globalVars = PageVariableNamespace()

local MatchGroupInput = {}

function MatchGroupInput.readMatchlist(bracketId, args)
	local sectionHeader = args.section or Variables.varDefault('bracket_header') or ''
	Variables.varDefine('bracket_header', sectionHeader)
	local tournamentParent = Variables.varDefault('tournament_parent', '')

	local matches = {}
	for matchKey, matchArgs in Table.iter.pairsByPrefix(args, 'M') do
		local matchIndex = tonumber(matchKey:match('(%d+)$'))
		local matchId = string.format('%04d', matchIndex)

		matchArgs = Json.parse(matchArgs)

		matchArgs.bracketid = bracketId
		matchArgs.matchid = matchId
		local match = require('Module:Brkts/WikiSpecific').processMatch(mw.getCurrentFrame(), matchArgs)
		match.parent = tournamentParent

		table.insert(matches, match)

		-- Add more fields to bracket data
		match.bracketdata = match.bracketdata or {}
		local bracketData = match.bracketdata
		bracketData.type = 'matchlist'
		local nextMatchId = bracketId .. '_' .. string.format('%04d', matchIndex + 1)
		bracketData.next = args['M' .. (matchIndex + 1)] and nextMatchId or nil
		bracketData.title = matchIndex == 1 and args.title or nil
		bracketData.header = args['M' .. matchIndex .. 'header'] or bracketData.header
		bracketData.bracketindex = Variables.varDefault('match2bracketindex', 0)
		bracketData.sectionheader = sectionHeader
	end

	return matches
end

function MatchGroupInput.readBracket(bracketId, args, options)
	local warnings = {}
	local templateId = args[1]
	assert(templateId, 'argument \'1\' (templateId) is empty')

	local sectionHeader = args.section or Variables.varDefault('bracket_header') or ''
	Variables.varDefine('bracket_header', sectionHeader)
	local tournamentParent = Variables.varDefault('tournament_parent', '')

	local bracketDatasById = Logic.try(function()
		return MatchGroupInput._fetchBracketDatas(templateId, bracketId)
	end)
		:catch(function(message)
			if FeatureFlag.get('prompt_purge_bracket_template') and String.endsWith(message, 'does not exist') then
				table.insert(warnings, message .. ' (Maybe [[Template:' .. templateId .. ']] needs to be purged?)')
				return {}
			else
				error(message)
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
			or Json.parse(Lua.import('Module:Match', {requireDevIfEnabled = true}).toEncodedJson({}))

		matchArgs.bracketid = bracketId
		matchArgs.matchid = matchId
		local match = require('Module:Brkts/WikiSpecific').processMatch(mw.getCurrentFrame(), matchArgs)
		match.parent = tournamentParent

		-- Add more fields to bracket data
		local bracketData = bracketDatasById[matchId]
		MatchGroupInput._validateBracketData(bracketData, matchKey)

		match.bracketdata = Table.mergeInto(bracketData, match.bracketdata or {})

		bracketData.type = 'bracket'
		bracketData.header = args[matchKey .. 'header'] or bracketData.header
		bracketData.bracketindex = Variables.varDefault('match2bracketindex', 0)
		bracketData.sectionheader = sectionHeader

		if match.winnerto then
			bracketData.winnerto = (match.winnertobracket and match.winnertobracket .. '_' or '')
				.. MatchGroupUtil.matchIdFromKey(match.winnerto)
		end
		if match.loserto then
			bracketData.loserto = (match.losertobracket and match.losertobracket .. '_' or '')
				.. MatchGroupUtil.matchIdFromKey(match.loserto)
		end

		-- Remove bracketData.thirdplace if no 3rd place match
		if not args.RxMTP then
			bracketData.thirdplace = nil
		end
		bracketData.thirdplace = bracketData.thirdplace or ''

		-- Remove bracketData.bracketreset if no reset match
		if not args.RxMBR then
			bracketData.bracketreset = nil
		end
		bracketData.bracketreset = bracketData.bracketreset or ''

		if not bracketData.lowerEdges then
			local opponentCount = 0
			for _, _ in Table.iter.pairsByPrefix(match, 'opponent') do
				opponentCount = opponentCount + 1
			end
			bracketData.lowerEdges = Array.map(
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

-- Retrieve bracket data from the template generated bracket on commons
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
		bracketData.lowerEdges = bracketData.lowerEdges and shiftArrayIndex(bracketData.lowerEdges)
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
		bracketData.advanceSpots = nil

		local _, baseMatchId = MatchGroupUtil.splitMatchId(match.match2id)
		return baseMatchId, bracketData
	end)
end

local BRACKET_DATA_PARAMS = {'type'}

function MatchGroupInput._validateBracketData(bracketData, matchKey)
	if bracketData == nil then
		error('bracketData of match ' .. matchKey .. ' is missing')
	end

	for _, param in ipairs(BRACKET_DATA_PARAMS) do
		if bracketData[param] == nil then
			error('bracketData of match ' .. matchKey .. ' is missing parameter \'' .. param .. '\'')
		end
	end
end

function MatchGroupInput.applyOverrideArgs(matchGroup, args)
	if args.title and matchGroup.matches[1] then
		matchGroup.matches[1].bracketData.title = args.title
	end

	if matchGroup.type == 'matchlist' then
		for index, match in ipairs(matchGroup.matches) do
			match.bracketData.header = args['M' .. index .. 'header'] or match.bracketData.header
		end
	else
		for _, match in ipairs(matchGroup.matches) do
			local _, baseMatchId = MatchGroupUtil.splitMatchId(match.matchId)
			local matchKey = MatchGroupUtil.matchIdToKey(baseMatchId)
			match.bracketData.header = args[matchKey .. 'header'] or match.bracketData.header
		end
	end
end

local getContentLanguage = FnUtil.memoize(mw.getContentLanguage)

function MatchGroupInput.readDate(dateString)
	-- Extracts the '-4:00' out of <abbr data-tz="-4:00" title="Eastern Daylight Time (UTC-4)">EDT</abbr>
	local timezoneOffset = dateString:match('data%-tz%=[\"\']([%d%-%+%:]+)[\"\']')
	local matchDate = String.explode(dateString, '<', 0):gsub('-', '')
	local isDateExact = String.contains(matchDate .. (timezoneOffset or ''), '[%+%-]')
	local date = getContentLanguage():formatDate('c', matchDate .. (timezoneOffset or ''))
	return {date = date, dateexact = isDateExact}
end

function MatchGroupInput.getInexactDate(suggestedDate)
	suggestedDate = suggestedDate or globalVars:get('tournament_date')
	local missingDateCount = globalVars:get('num_missing_dates') or 0
	globalVars:set('num_missing_dates', missingDateCount + 1)
	local inexactDateString = (suggestedDate or '') .. ' + ' .. missingDateCount .. ' second'
	return getContentLanguage():formatDate('c', inexactDateString)
end

--[[
Fetches the LPDB records of a match group containing standalone matches.
Standalone matches are specified from individual match pages in the Match
namespace.
]]
MatchGroupInput.fetchStandaloneMatchGroup = FnUtil.memoize(function(bracketId)
	return mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = '[[namespace::130]] AND [[match2bracketid::'.. bracketId .. ']]'
	})
end)

--[[
Fetches the LPDB record of a standalone match.

matchId is a full match ID, such as MATCH_wec2CbLWRx_0001
]]
function MatchGroupInput.fetchStandaloneMatch(matchId)
	local bracketId, _ = MatchGroupUtil.splitMatchId(matchId)
	local matches = MatchGroupInput.fetchStandaloneMatchGroup(bracketId)
	return Array.find(matches, function(match)
		return match.match2id == matchId
	end)
end

return MatchGroupInput
