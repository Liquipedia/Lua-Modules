---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/ShortenBracket
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local ShortenBracket = {}

local FIRST_MATCH_KEY = 'R01-M001'

--- Fetches and adjusts matches so they can be displayed in the shortened format
---@param props {bracketId: string, shortTemplate: string, args: table}
---@return string
function ShortenBracket.adjustMatchesAndBracketId(props)
	local shortTemplate = 'Bracket/' .. string.gsub(props.shortTemplate, '^[bB]racket/', '')
	local matches = MatchGroupUtil.fetchMatchRecords(props.bracketId)
	assert(#matches ~= 0, 'No data found for bracketId=' .. props.bracketId)

	assert(matches[1].match2bracketdata.type == 'bracket',
		'The data found for id "' .. props.bracketId .. '" is not a bracket')

	local shortenedBracketIndex = (tonumber(Variables.varDefault('shortenedBracketIndex')) or 0) + 1
	Variables.varDefine('shortenedBracketIndex', shortenedBracketIndex)
	local newBracketId = shortenedBracketIndex .. props.bracketId

	local bracketDatasById = MatchGroupInput._fetchBracketDatas(shortTemplate, newBracketId)

	local newMatches = ShortenBracket._processMatches(
		matches,
		string.len(props.bracketId),
		ShortenBracket._getSkipRoundValue(shortTemplate, props.bracketId, matches[1], bracketDatasById),
		newBracketId,
		bracketDatasById
	)

	assert(newMatches[1], 'The provided id and shortTemplate values leave an empty bracket')

	-- store as wiki var so it can be retrieved by the display function
	Variables.varDefine('match2bracket_' .. newBracketId, Json.stringify(newMatches))

	return newBracketId
end

---@param shortTemplate string
---@param bracketId string
---@param firstMatch match2
---@param bracketDatasById table<string, table>
---@return integer
function ShortenBracket._getSkipRoundValue(shortTemplate, bracketId, firstMatch, bracketDatasById)
	local newRoundCount = bracketDatasById[FIRST_MATCH_KEY].coordinates.roundCount
	local oldRoundCount = firstMatch.match2bracketdata.coordinates.roundCount

	return oldRoundCount - newRoundCount
end

---@param matches match2[]
---@param idLength integer
---@param skipRounds integer
---@param newBracketId string
---@param bracketDatasById table<string, table>
---@return match2[]
function ShortenBracket._processMatches(matches, idLength, skipRounds, newBracketId, bracketDatasById)
	return Array.map(matches, function(match)
		local originalMatchId = match.match2id
		local matchId = string.sub(originalMatchId, idLength + 2)
		local round = tonumber(string.sub(matchId, 2, 3))

		-- keep reset/3rd place match, i.e. last round
		if not round then
			match.match2id = newBracketId .. '_' .. matchId
			return match
		elseif round <= skipRounds then return nil end

		local newMatchId = 'R' .. string.format('%02d', round - skipRounds) .. '-M' .. string.sub(matchId, -3)

		assert(bracketDatasById[newMatchId], 'bracket <--> short bracket missmatch: No bracket data found for '
			.. newMatchId .. ' (calculated from ' .. matchId .. ')')

		match.match2id = newBracketId .. '_' .. newMatchId

		-- nil some stuff before merge since it doesn't get nil-ed in merge
		match.match2bracketdata.loweredges = nil
		match.match2bracketdata.skipround = nil

		match.match2bracketdata = Table.merge(match.match2bracketdata, bracketDatasById[newMatchId], {
			header = match.match2bracketdata.header
		})

		-- have to do this after the merge so that correct `match.match2bracketdata.lowerMatchIds` is available
		match.match2bracketdata.loweredges = ShortenBracket._calculateLowerEdges(match)

		-- add the original match id for reference and to be able to use it in e.g. BigMatch linking
		match.extradata.originalmatchid = originalMatchId

		match.match2bracketid = newBracketId

		return match
	end)
end

---@param match match2
---@return table[]
function ShortenBracket._calculateLowerEdges(match)
	return Array.map(
		MatchGroupUtil.autoAssignLowerEdges(#match.match2bracketdata.lowerMatchIds, #match.match2opponents),
		MatchGroupUtil.indexTableToRecord
	)
end

return ShortenBracket
