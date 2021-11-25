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
local TournamentUtil = require('Module:Tournament/Util')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local globalVars = PageVariableNamespace()

local MatchGroupInput = {}

function MatchGroupInput.readMatchlist(bracketId, args)
	local context = MatchGroupInput.readContext(args)

	local matchKeys = TournamentUtil.mapInterleavedPrefix(args, {'M'}, FnUtil.identity)

	return Array.map(matchKeys, function(matchKey, matchIndex)
		local matchId = MatchGroupUtil.matchIdFromKey(matchIndex)
		local matchArgs = Json.parse(args[matchKey])

		matchArgs.bracketid = bracketId
		matchArgs.matchid = matchId
		local match = require('Module:Brkts/WikiSpecific').processMatch(mw.getCurrentFrame(), matchArgs)
		match.parent = context.tournamentParent

		-- Add more fields to bracket data
		match.bracketdata = match.bracketdata or {}
		local bracketData = match.bracketdata

		bracketData.type = 'matchlist'
		bracketData.title = matchIndex == 1 and args.title or nil
		bracketData.header = args['M' .. matchIndex .. 'header'] or bracketData.header
		local nextMatchId = bracketId .. '_' .. MatchGroupUtil.matchIdFromKey(matchIndex + 1)
		bracketData.next = matchIndex ~= #matchKeys and nextMatchId or nil

		bracketData.bracketindex = context.bracketIndex
		bracketData.groupRoundIndex = tonumber(match.round) or context.groupRoundIndex
		bracketData.pageSection = context.pageSection
		bracketData.sectionheader = context.stage --Deprecated
		bracketData.stage = context.stage

		return match
	end)
end

function MatchGroupInput.readBracket(bracketId, args, options)
	local warnings = {}
	local templateId = args[1]
	assert(templateId, 'argument \'1\' (templateId) is empty')

	local context = MatchGroupInput.readContext(args)

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
		match.parent = context.tournamentParent

		-- Add more fields to bracket data
		local bracketData = bracketDatasById[matchId]
		MatchGroupInput._validateBracketData(bracketData, matchKey)

		match.bracketdata = Table.mergeInto(bracketData, match.bracketdata or {})

		bracketData.type = 'bracket'
		bracketData.header = args[matchKey .. 'header'] or bracketData.header

		bracketData.bracketindex = context.bracketIndex
		bracketData.groupRoundIndex = tonumber(match.round) or context.groupRoundIndex
		bracketData.pageSection = context.pageSection
		bracketData.sectionheader = context.stage --Deprecated
		bracketData.stage = context.stage

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

		-- Remove bracketData.bracketreset if no reset match
		if not args.RxMBR then
			bracketData.bracketreset = nil
		end

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
		bracketData.advanceSpots = bracketData.advanceSpots and shiftArrayIndex(bracketData.advanceSpots)
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
		bracketData.tolower = bracketData.lowerMatchIds[#bracketData.lowerMatchIds]
		bracketData.toupper = bracketData.lowerMatchIds[#bracketData.lowerMatchIds - 1]
		bracketData.rootIndex = nil

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
Parses the match group context. The match group context describes where a match
group is relative to the tournament page.
]]
function MatchGroupInput.readContext(args)
	local context = {
		bracketIndex = tonumber(globalVars:get('match2bracketindex')) or 0,
		groupRoundIndex = MatchGroupInput.readGroupRoundIndex(args),
		pageSection = args.matchsection or globalVars:get('matchsection'),
		stage = args.stage or args.section or globalVars:get('bracket_header'), -- args.section is deprecated
		tournamentParent = globalVars:get('tournament_parent'),
	}

	globalVars:set('bracket_header', context.stage)
	globalVars:set('matchsection', context.pageSection)

	return context
end

function MatchGroupInput.readGroupRoundIndex(args)
	if args.round then
		return tonumber(args.round)
	end

	local pageSection = args.matchsection or globalVars:get('matchsection')
	-- Usually 'Round N' but can also be 'Day N', 'Week N', etc.
	local roundIndex = pageSection and pageSection:match(' (%d+)$')
	if roundIndex then
		return tonumber(roundIndex)
	end
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
