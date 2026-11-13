---
-- @Liquipedia
-- page=Module:MatchGroup/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Table = Lua.import('Module:Table')

local MatchGroupCoordinates = Lua.import('Module:Domain/Bracket/Coordinates')
local WikiSpecific = Lua.import('Module:Brkts/WikiSpecific')

local BracketUtil = Lua.import('Module:Domain/Bracket/Model')
local MatchStore = Lua.import('Module:Domain/Match/Store')
local MatchUtil = Lua.import('Module:Domain/Match/Model')
local Types = Lua.import('Module:MatchGroup/Util/Types')

--[[
Fetches match records and assembles them into matchlists and brackets.

The pieces it assembles from live elsewhere: the match model in Module:Domain/Match/Model, the
bracket model in Module:Domain/Bracket/Model, and the shapes of both in
Module:MatchGroup/Util/Types. Display related functions go in Module:MatchGroup/Display/Helper.

Both models are also re-exported here, as a complete mirror: every member of either model has a
re-export, which match_group_util_spec asserts. Prefer importing the models directly. The mirror
exists so that modules written against the combined interface keep working until they are moved
over, and nothing that is not a model member should be added to it.

-- TODO: delete the re-exports once no module outside MatchGroup/ imports this for the models.
]]
---@class MatchGroupUtil
local MatchGroupUtil = {types = Types}

--- Re-exported from Module:Domain/Match/Store. Prefer importing that module directly.
MatchGroupUtil.fetchMatchIds = MatchStore.fetchMatchIds
MatchGroupUtil.fetchMatchRecords = MatchStore.fetchMatchRecords

--- Re-exported from Module:Domain/Match/Model. Prefer importing that module directly.
MatchGroupUtil.matchFromRecord = MatchUtil.matchFromRecord
MatchGroupUtil.opponentFromRecord = MatchUtil.opponentFromRecord
MatchGroupUtil.createOpponent = MatchUtil.createOpponent
MatchGroupUtil.playerFromRecord = MatchUtil.playerFromRecord
MatchGroupUtil.gameFromRecord = MatchUtil.gameFromRecord
MatchGroupUtil.groupBySubgroup = MatchUtil.groupBySubgroup
MatchGroupUtil.computeMatchPhase = MatchUtil.computeMatchPhase

--- Re-exported from Module:Domain/Bracket/Model. Prefer importing that module directly.
MatchGroupUtil.splitMatchId = BracketUtil.splitMatchId
MatchGroupUtil.matchIdToKey = BracketUtil.matchIdToKey
MatchGroupUtil.matchIdFromKey = BracketUtil.matchIdFromKey
MatchGroupUtil.bracketDataFromRecord = BracketUtil.bracketDataFromRecord
MatchGroupUtil.bracketDataToRecord = BracketUtil.bracketDataToRecord
MatchGroupUtil.computeLowerMatchIdsFromLegacy = BracketUtil.computeLowerMatchIdsFromLegacy
MatchGroupUtil.autoAssignLowerEdges = BracketUtil.autoAssignLowerEdges
MatchGroupUtil.computeAdvanceSpots = BracketUtil.computeAdvanceSpots
MatchGroupUtil.populateAdvanceSpots = BracketUtil.populateAdvanceSpots
MatchGroupUtil.resetMatch = BracketUtil.resetMatch
MatchGroupUtil.computeRootMatchIds = BracketUtil.computeRootMatchIds
MatchGroupUtil.backfillUpperMatchIds = BracketUtil.backfillUpperMatchIds
MatchGroupUtil.backfillCoordinates = BracketUtil.backfillCoordinates
MatchGroupUtil.indexTableFromRecord = BracketUtil.indexTableFromRecord
MatchGroupUtil.indexTableToRecord = BracketUtil.indexTableToRecord
MatchGroupUtil.sectionIndexToString = BracketUtil.sectionIndexToString

MatchGroupUtil.fetchMatchGroup = FnUtil.memoize(function(bracketId)
	local matchRecords = MatchGroupUtil.fetchMatchRecords(bracketId)
	return MatchGroupUtil.makeMatchGroup(matchRecords)
end)

---Creates a match group structure from its match records. Returns a value of type MatchGroupUtil.types.MatchGroup.
---@param matchRecords table[]
---@return MatchGroupUtilMatchGroup
function MatchGroupUtil.makeMatchGroup(matchRecords)
	local type = matchRecords[1] and matchRecords[1].match2bracketdata.type or 'matchlist'
	if type == 'matchlist' then
		return MatchGroupUtil.makeMatchlistFromRecords(matchRecords)
	elseif type == 'bracket' then
		return MatchGroupUtil.makeBracketFromRecords(matchRecords)
	else
		error('Invalid match2bracketdata.type: ' .. type .. '. Expected matchlist or bracket.')
	end
end

---@param matchRecords table[]
---@return MatchGroupUtilMatchlist
function MatchGroupUtil.makeMatchlistFromRecords(matchRecords)
	local matches = Array.map(matchRecords, WikiSpecific.matchFromRecord)

	local matchesById = Table.map(matches, function(_, match) return match.matchId, match end)
	local bracketDatasById = Table.mapValues(matchesById, function(match) return match.bracketData end)

	return {
		bracketDatasById = bracketDatasById,
		matches = matches,
		matchesById = matchesById,
		type = 'matchlist',
	}
end

---@param matchRecords table[]
---@return MatchGroupUtilBracket
function MatchGroupUtil.makeBracketFromRecords(matchRecords)
	local matches = Array.map(matchRecords, WikiSpecific.matchFromRecord) --[[@as MatchGroupUtilMatch[] ]]

	local matchesById = Table.map(matches, function(_, match) return match.matchId, match end)
	local bracketDatasById = Table.mapValues(matchesById, function(match) return match.bracketData end)

	local firstCoordinates = matches[1] and matches[1].bracketData.coordinates
	if not firstCoordinates then
		MatchGroupUtil.backfillUpperMatchIds(bracketDatasById)
	end

	local bracket = {
		bracketDatasById = bracketDatasById,
		coordinatesByMatchId = Table.mapValues(matchesById, function(match) return match.bracketData.coordinates end),
		matches = matches,
		matchesById = matchesById,
		rootMatchIds = MatchGroupUtil.computeRootMatchIds(bracketDatasById),
		type = 'bracket',
	}

	if firstCoordinates then
		Table.mergeInto(bracket, {
			rounds = MatchGroupCoordinates.getRoundsFromCoordinates(bracket),
			sections = MatchGroupCoordinates.getSectionsFromCoordinates(bracket),
		})
	else
		MatchGroupUtil.backfillCoordinates(bracket)
	end

	MatchGroupUtil.populateAdvanceSpots(bracket)

	return bracket
end

---Fetches all matches in a matchlist or bracket.
---Returns a list of structurally typed matches lexicographically ordered by matchId.
---@param bracketId string
---@return MatchGroupUtilMatch[]
function MatchGroupUtil.fetchMatches(bracketId)
	return MatchGroupUtil.fetchMatchGroup(bracketId).matches
end

---Returns a match together with its bracket reset match, if it has one. Callers that display the
---pair as a single match merge them with Module:MatchGroup/Display/Helper.mergeBracketResetMatch.
---@param bracketId string
---@param matchId string
---@return MatchGroupUtilMatch, MatchGroupUtilMatch?
function MatchGroupUtil.fetchMatchWithBracketReset(bracketId, matchId)
	local bracket = MatchGroupUtil.fetchMatchGroup(bracketId)
	local match = bracket.matchesById[matchId]

	local bracketResetMatch = match and BracketUtil.resetMatch(bracket.matchesById, match.bracketData)

	return match, bracketResetMatch
end

return MatchGroupUtil
