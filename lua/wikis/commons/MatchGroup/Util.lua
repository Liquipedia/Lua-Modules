---
-- @Liquipedia
-- page=Module:MatchGroup/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Operator = Lua.import('Module:Operator')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local MatchGroupCoordinates = Lua.import('Module:MatchGroup/Coordinates')
local WikiSpecific = Lua.import('Module:Brkts/WikiSpecific')

local BracketUtil = Lua.import('Module:MatchGroup/Util/Bracket')
local MatchUtil = Lua.import('Module:MatchGroup/Util/Match')
local Types = Lua.import('Module:MatchGroup/Util/Types')

--[[
Fetches match records and assembles them into matchlists and brackets.

The pieces it assembles from live elsewhere: the match model in Module:MatchGroup/Util/Match, the
bracket model in Module:MatchGroup/Util/Bracket, and the shapes of both in
Module:MatchGroup/Util/Types. Display related functions go in Module:MatchGroup/Display/Helper.

Both models are also re-exported here, as a complete mirror: every member of either model has a
re-export, which match_group_util_spec asserts. Prefer importing the models directly. The mirror
exists so that modules written against the combined interface keep working until they are moved
over, and nothing that is not a model member should be added to it.

-- TODO: delete the re-exports once no module outside MatchGroup/ imports this for the models.
]]
---@class MatchGroupUtil
local MatchGroupUtil = {types = Types}

--- Re-exported from Module:MatchGroup/Util/Match. Prefer importing that module directly.
MatchGroupUtil.matchFromRecord = MatchUtil.matchFromRecord
MatchGroupUtil.opponentFromRecord = MatchUtil.opponentFromRecord
MatchGroupUtil.createOpponent = MatchUtil.createOpponent
MatchGroupUtil.playerFromRecord = MatchUtil.playerFromRecord
MatchGroupUtil.gameFromRecord = MatchUtil.gameFromRecord
MatchGroupUtil.groupBySubgroup = MatchUtil.groupBySubgroup
MatchGroupUtil.computeMatchPhase = MatchUtil.computeMatchPhase

--- Re-exported from Module:MatchGroup/Util/Bracket. Prefer importing that module directly.
MatchGroupUtil.splitMatchId = BracketUtil.splitMatchId
MatchGroupUtil.matchIdToKey = BracketUtil.matchIdToKey
MatchGroupUtil.matchIdFromKey = BracketUtil.matchIdFromKey
MatchGroupUtil.bracketDataFromRecord = BracketUtil.bracketDataFromRecord
MatchGroupUtil.bracketDataToRecord = BracketUtil.bracketDataToRecord
MatchGroupUtil.computeLowerMatchIdsFromLegacy = BracketUtil.computeLowerMatchIdsFromLegacy
MatchGroupUtil.autoAssignLowerEdges = BracketUtil.autoAssignLowerEdges
MatchGroupUtil.computeAdvanceSpots = BracketUtil.computeAdvanceSpots
MatchGroupUtil.populateAdvanceSpots = BracketUtil.populateAdvanceSpots
MatchGroupUtil.computeRootMatchIds = BracketUtil.computeRootMatchIds
MatchGroupUtil.backfillUpperMatchIds = BracketUtil.backfillUpperMatchIds
MatchGroupUtil.backfillCoordinates = BracketUtil.backfillCoordinates
MatchGroupUtil.indexTableFromRecord = BracketUtil.indexTableFromRecord
MatchGroupUtil.indexTableToRecord = BracketUtil.indexTableToRecord
MatchGroupUtil.sectionIndexToString = BracketUtil.sectionIndexToString

---Fetches all match ids of matches that satisfy the supplied condition
---@param props {conditions: string|AbstractConditionNode, limit: string|integer?, order: string?}
---@return string[]
function MatchGroupUtil.fetchMatchIds(props)
	---@type string[]
	return Array.map(mw.ext.LiquipediaDB.lpdb('match2', {
		limit = tonumber(props.limit) or 1000,
		query = 'match2id',
		conditions = tostring(props.conditions),
		order = props.order
	}), Operator.property('match2id'))
end

---Fetches all matches in a matchlist or bracket. Tries to read from page variables before fetching from LPDB.
---Returns a list of records ordered lexicographically by matchId.
---@param bracketId string
---@return table[]
function MatchGroupUtil.fetchMatchRecords(bracketId)
	local varData = Variables.varDefault('match2bracket_' .. bracketId)
	if varData then
		return (Json.parse(varData))
	end

	return mw.ext.LiquipediaDB.lpdb(
		'match2',
		{
			conditions = '([[namespace::0]] or [[namespace::>0]]) AND [[match2bracketid::' .. bracketId .. ']]',
			order = 'match2id ASC',
			limit = 5000,
		}
	)
end

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

---Returns a match struct for use in a bracket display or match summary popup. The bracket display and match summary
---popup expects that the finals match also include results from the bracket reset match.
---@param bracketId string
---@param matchId string
---@return MatchGroupUtilMatch, MatchGroupUtilMatch?
function MatchGroupUtil.fetchMatchForBracketDisplay(bracketId, matchId)
	local bracket = MatchGroupUtil.fetchMatchGroup(bracketId)
	local match = bracket.matchesById[matchId]

	local bracketResetMatch = match
		and match.bracketData.bracketResetMatchId
		and bracket.matchesById[match.bracketData.bracketResetMatchId]

	return match, bracketResetMatch
end

return MatchGroupUtil
