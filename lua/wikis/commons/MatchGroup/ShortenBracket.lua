---
-- @Liquipedia
-- page=Module:MatchGroup/ShortenBracket
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

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

	-- in case of a third place match we need to adjust that after the finals match was processed
	-- as we need the data of the processed finals match, hence adjust it here
	newMatches = ShortenBracket._adjustThirdPlaceMatch(newMatches)

	assert(newMatches[1], 'The provided id and shortTemplate values leave an empty bracket')

	-- store as wiki var so it can be retrieved by the display function
	Variables.varDefine('match2bracket_' .. newBracketId, Json.stringify(newMatches))

	return newBracketId
end

---@param newMatches match2[]
---@return match2[]
function ShortenBracket._adjustThirdPlaceMatch(newMatches)
	local thirdPlaceMatch = Array.filter(newMatches, function(match)
		return string.match(match.match2id, '_RxMTP$') ~= nil
	end)[1]

	if not thirdPlaceMatch then return newMatches end

	local finals = Array.filter(newMatches, function(match)
		return Logic.isNotEmpty(match.match2bracketdata.thirdplace)
	end)[1]

	local finalsCoordinates = finals.match2bracketdata.coordinates

	thirdPlaceMatch.match2bracketdata.coordinates = Table.merge(finalsCoordinates, {
		depthCount = finalsCoordinates.depthCount - 1,
		matchIndexInRound = finalsCoordinates.matchIndexInRound + 1,
		rootIndex = finalsCoordinates.rootIndex + 1,
	})
	thirdPlaceMatch.match2bracketdata.coordinates.semanticDepth = nil

	return newMatches
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

		assert(bracketDatasById[newMatchId], 'bracket <--> short bracket mismatch: No bracket data found for '
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
