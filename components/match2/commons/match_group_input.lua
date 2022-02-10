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
local Opponent = require('Module:Opponent')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local globalVars = PageVariableNamespace({cached = true})

local MatchGroupInput = {}


--remove this once #1050 is merged;;; use module:Table instead
local TournamentUtil = require('Module:Tournament/Util')

function MatchGroupInput.readMatchlist(bracketId, args)
	local matchKeys = TournamentUtil.mapInterleavedPrefix(args, {'M'}, FnUtil.identity)

	return Array.map(matchKeys, function(matchKey, matchIndex)
			local matchId = string.format('%04d', matchIndex)
			local matchArgs = Json.parse(args[matchKey])

			local context = MatchGroupInput.readContext(matchArgs, args)
			MatchGroupInput.persistContextChanges(context)

			matchArgs.bracketid = bracketId
			matchArgs.matchid = matchId
			local match = require('Module:Brkts/WikiSpecific').processMatch(mw.getCurrentFrame(), matchArgs)

			-- Add more fields to bracket data
			match.bracketdata = match.bracketdata or {}
			local bracketData = match.bracketdata

			bracketData.type = 'matchlist'
			bracketData.title = matchIndex == 1 and args.title or nil
			bracketData.header = args['M' .. matchIndex .. 'header'] or bracketData.header
			bracketData.matchIndex = matchIndex

			match.parent = context.tournamentParent
			bracketData.bracketindex = context.bracketIndex
			bracketData.groupRoundIndex = context.groupRoundIndex
			bracketData.sectionheader = context.sectionHeader
			bracketData.dateheader = Logic.readBool(match.dateheader) or nil

			local nextMatchId = bracketId .. '_' .. string.format('%04d', matchIndex + 1)
			bracketData.next = matchIndex ~= #matchKeys and nextMatchId or nil

			return match
		end
	)
end

function MatchGroupInput.readBracket(bracketId, args, options)
	local warnings = {}
	local templateId = args[1]
	assert(templateId, 'argument \'1\' (templateId) is empty')

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

		local context = MatchGroupInput.readContext(matchArgs, args)
		MatchGroupInput.persistContextChanges(context)

		matchArgs.bracketid = bracketId
		matchArgs.matchid = matchId
		local match = require('Module:Brkts/WikiSpecific').processMatch(mw.getCurrentFrame(), matchArgs)

		-- Add more fields to bracket data
		local bracketData = bracketDatasById[matchId]

		match.bracketdata = Table.mergeInto(bracketData, match.bracketdata or {})

		bracketData.type = 'bracket'
		bracketData.header = args[matchKey .. 'header'] or bracketData.header

		match.parent = context.tournamentParent
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
function MatchGroupInput.readContext(matchArgs, matchGroupArgs)
	return {
		bracketIndex = tonumber(globalVars:get('match2bracketindex')) or 0,
		groupRoundIndex = MatchGroupInput.readGroupRoundIndex(matchArgs, matchGroupArgs),
		matchSection = matchArgs.matchsection or matchGroupArgs.matchsection or globalVars:get('matchsection'),
		sectionHeader = matchGroupArgs.section or globalVars:get('bracket_header'),
		tournamentParent = globalVars:get('tournament_parent'),
	}
end

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

--[[
Saves changes to the match group context, as set by match group args, in page variables.
]]
function MatchGroupInput.persistContextChanges(context)
	globalVars:set('bracket_header', context.sectionHeader)
	globalVars:set('matchsection', context.matchSection)
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

--[[
Merges an opponent struct into a match2 opponent record.
]]
function MatchGroupInput.mergeRecordWithOpponent(record, opponent)
	if opponent.type == Opponent.team then
		record.template = record.template or opponent.template

	elseif Opponent.typeIsParty(opponent.type) then
		record.match2players = record.match2players
			or Array.map(opponent.players, function(player)
				return {
					displayname = player.displayName,
					flag = player.flag,
					name = player.pageName,
				}
			end)
	end

	record.name = Opponent.toName(opponent)
	record.type = opponent.type

	return record
end

return MatchGroupInput
