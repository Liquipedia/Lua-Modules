---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Input
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local MatchGroupUtil = require('Module:MatchGroup/Util')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInput = {}

function MatchGroupInput.readMatchlist(bracketId, args, matchBuilder)
	local sectionHeader = args.section or Variables.varDefault('bracket_header') or ''
	Variables.varDefine('bracket_header', sectionHeader)
	local tournamentParent = Variables.varDefault('tournament_parent', '')

	local function readMatch(matchIndex)
		local matchId = string.format('%04d', matchIndex)

		local matchArgs = args['M' .. matchIndex]
		if not matchArgs then
			return
		end

		matchArgs = Json.parseIfString(matchArgs)
		local match = require('Module:Brkts/WikiSpecific').processMatch(mw.getCurrentFrame(), matchArgs)
		if matchBuilder then
			match = matchBuilder(mw.getCurrentFrame(), match, bracketId .. '_' .. matchId)
		end
		match.bracketid = bracketId
		match.matchid = matchId
		match.parent = tournamentParent

		-- Add more fields to bracket data
		local bracketData = Json.parse(match.bracketdata or '{}')
		bracketData.type = 'matchlist'
		local nextMatchId = bracketId .. '_' .. string.format('%04d', matchIndex + 1)
		bracketData.next = args['M' .. (matchIndex + 1)] and nextMatchId or nil
		bracketData.title = matchIndex == 1 and args.title or nil
		bracketData.header = args['M' .. matchIndex .. 'header'] or bracketData.header
		bracketData.bracketindex = Variables.varDefault('match2bracketindex', 0)
		bracketData.sectionheader = sectionHeader

		match.bracketdata = Json.stringify(bracketData)

		return match
	end

	return Array.mapIndexes(readMatch)
end

function MatchGroupInput.readBracket(bracketId, args, matchBuilder)
	local templateId = args[1]
	assert(templateId, 'argument \'1\' (templateId) is empty')

	local sectionHeader = args.section or Variables.varDefault('bracket_header') or ''
	Variables.varDefine('bracket_header', sectionHeader)
	local tournamentParent = Variables.varDefault('tournament_parent', '')

	local bracketDatasById = MatchGroupInput._fetchBracketDatas(templateId, bracketId)

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

		matchArgs = Json.parseIfString(matchArgs) or {}
		local match = require('Module:Brkts/WikiSpecific').processMatch(mw.getCurrentFrame(), matchArgs)
		if matchBuilder then
			match = matchBuilder(mw.getCurrentFrame(), match, bracketId .. '_' .. matchKey)
		end
		match.bracketid = bracketId
		match.matchid = matchId
		match.parent = tournamentParent

		-- Add more fields to bracket data
		local bracketData = bracketDatasById[matchId]
		MatchGroupInput._validateBracketData(bracketData, matchKey)

		Table.mergeInto(bracketData, Json.parse(match.bracketdata or '{}'))
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

		-- Kick bracketData.thirdplace if no 3rd place match
		if bracketData.thirdplace ~= '' and not args.RxMTP then
			bracketData.thirdplace = ''
		end
		-- Kick bracketData.bracketreset if no reset match
		if bracketData.bracketreset ~= '' and not args.RxMBR then
			bracketData.bracketreset = ''
		end

		match.bracketdata = Json.stringify(bracketData)
		return match
	end

	local matchIds = Array.fromTableKeys(bracketDatasById)
	table.sort(matchIds)
	local matches = Array.map(matchIds, readMatch)

	local warnings = {}
	if #missingMatchKeys ~= 0 then
		table.insert(warnings, 'Missing matches: ' .. table.concat(missingMatchKeys, ', '))
	end

	return matches, warnings
end

-- Retrieve bracket data from the template generated bracket on commons
function MatchGroupInput._fetchBracketDatas(templateId, bracketId)
	local matches = mw.ext.Brackets.getCommonsBracketTemplate(templateId)
	assert(type(matches) == 'table')
	assert(#matches ~= 0, 'Bracket ' .. templateId .. ' does not exist')

	local function replaceBracketId(matchId)
		local _, baseMatchId = MatchGroupUtil.splitMatchId(matchId)
		return (bracketId or '') .. '_' .. baseMatchId
	end

	return Table.map(matches, function(_, match)
		local bracketData = match.match2bracketdata
		if String.nilIfEmpty(bracketData.toupper) then
			bracketData.toupper = replaceBracketId(bracketData.toupper)
		end
		if String.nilIfEmpty(bracketData.tolower) then
			bracketData.tolower = replaceBracketId(bracketData.tolower)
		end
		if String.nilIfEmpty(bracketData.thirdplace) then
			bracketData.thirdplace = replaceBracketId(bracketData.thirdplace)
		end
		if String.nilIfEmpty(bracketData.bracketreset) then
			bracketData.bracketreset = replaceBracketId(bracketData.bracketreset)
		end

		local _, baseMatchId = MatchGroupUtil.splitMatchId(match.match2id)
		return baseMatchId, bracketData
	end)
end

local BRACKET_DATA_PARAMS = {'header', 'tolower', 'toupper', 'qualwin', 'quallose', 'skipround'}

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

return MatchGroupInput
