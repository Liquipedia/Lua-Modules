---
-- @Liquipedia
-- page=Module:MatchGroup/Util/Bracket
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local MatchGroupCoordinates = Lua.import('Module:MatchGroup/Coordinates')

local nilIfEmpty = String.nilIfEmpty

--[[
Where a match sits in its match group and how that group is laid out. Reads and writes bracket data
records, works out lower edges, advance spots, root matches and coordinates, and owns the id
namespace that addresses a match within its group.

A matchlist counts as a bracket here: it is the flat case of the same structure, which is why the
matchlist id form lives alongside the bracket ones.
]]
local BracketUtil = {}

---@param data table?
---@return MatchGroupUtilBracketData
function BracketUtil.bracketDataFromRecord(data)
	if not data then
		return {}
	end
	if data.type == 'bracket' then
		local advanceSpots = data.advancespots or BracketUtil.computeAdvanceSpots(data)
		return {
			advanceSpots = advanceSpots,
			bracketResetMatchId = nilIfEmpty(data.bracketreset),
			coordinates = data.coordinates and BracketUtil.indexTableFromRecord(data.coordinates),
			header = nilIfEmpty(data.header),
			inheritedHeader = nilIfEmpty(data.inheritedheader),
			lowerEdges = data.loweredges and Array.map(data.loweredges, BracketUtil.indexTableFromRecord),
			lowerMatchIds = data.lowerMatchIds or BracketUtil.computeLowerMatchIdsFromLegacy(data),
			qualifiedHeader = nilIfEmpty(data.qualifiedheader),
			qualLose = advanceSpots[2] and advanceSpots[2].type == 'qualify',
			qualLoseLiteral = nilIfEmpty(data.qualloseLiteral),
			qualSkip = tonumber(data.qualskip) or data.qualskip == 'true' and 1 or 0,
			qualWin = advanceSpots[1] and advanceSpots[1].type == 'qualify',
			qualWinLiteral = nilIfEmpty(data.qualwinLiteral),
			matchPage = nilIfEmpty(data.matchpage),
			skipRound = tonumber(data.skipround) or data.skipround == 'true' and 1 or 0,
			bracketType = nilIfEmpty(data.bracketType),
			thirdPlaceMatchId = nilIfEmpty(data.thirdplace),
			type = 'bracket',
			upperMatchId = nilIfEmpty(data.upperMatchId),
		}
	else
		return {
			dateHeader = nilIfEmpty(data.dateheader),
			header = nilIfEmpty(data.header),
			inheritedHeader = nilIfEmpty(data.inheritedheader),
			matchIndex = nilIfEmpty(data.matchIndex),
			matchPage = nilIfEmpty(data.matchpage),
			title = nilIfEmpty(data.title),
			type = 'matchlist',
		}
	end
end

---@param bracketData MatchGroupUtilBracketData
---@return table
function BracketUtil.bracketDataToRecord(bracketData)
	local coordinates = bracketData.coordinates
	return {
		bracketreset = bracketData.bracketResetMatchId,
		bracketsection = coordinates
			and BracketUtil.sectionIndexToString(coordinates.sectionIndex, coordinates.sectionCount),
		coordinates = coordinates and BracketUtil.indexTableToRecord(coordinates),
		header = bracketData.header,
		lowerMatchIds = bracketData.lowerMatchIds,
		loweredges = bracketData.lowerEdges and Array.map(bracketData.lowerEdges, BracketUtil.indexTableToRecord),
		quallose = bracketData.qualLose and 'true' or nil,
		qualloseLiteral = bracketData.qualLoseLiteral,
		qualskip = bracketData.qualSkip ~= 0 and bracketData.qualSkip or nil,
		qualwin = bracketData.qualWin and 'true' or nil,
		qualwinLiteral = bracketData.qualWinLiteral,
		skipround = bracketData.skipRound ~= 0 and bracketData.skipRound or nil,
		bracketType = bracketData.bracketType,
		thirdplace = bracketData.thirdPlaceMatchId,
		tolower = bracketData.lowerMatchIds[#bracketData.lowerMatchIds],
		toupper = bracketData.lowerMatchIds[#bracketData.lowerMatchIds - 1],
		type = bracketData.type,
		upperMatchId = bracketData.upperMatchId,
	}
end

---@param data table
---@return string[]
function BracketUtil.computeLowerMatchIdsFromLegacy(data)
	local lowerMatchIds = {}
	if nilIfEmpty(data.toupper) then
		table.insert(lowerMatchIds, data.toupper)
	end
	if nilIfEmpty(data.tolower) then
		table.insert(lowerMatchIds, data.tolower)
	end
	return lowerMatchIds
end

---Auto compute lower edges, which encode the connector lines between lower matches and this match.
---@param lowerMatchCount integer
---@param opponentCount integer
---@return {lowerMatchIndex: integer, opponentIndex: integer}[]
function BracketUtil.autoAssignLowerEdges(lowerMatchCount, opponentCount)
	local lowerEdges = {}
	if lowerMatchCount <= opponentCount then
		-- More opponents than lower matches: connect lower matches to opponents near the middle.
		local skip = math.ceil((opponentCount - lowerMatchCount) / 2)
		for lowerMatchIndex = 1, lowerMatchCount do
			table.insert(lowerEdges, {
				lowerMatchIndex = lowerMatchIndex,
				opponentIndex = lowerMatchIndex + skip,
			})
		end
	else
		-- More lower matches than opponents: The excess lower matches are all connected to the final opponent.
		for lowerMatchIndex = 1, lowerMatchCount do
			table.insert(lowerEdges, {
				lowerMatchIndex = lowerMatchIndex,
				opponentIndex = math.min(lowerMatchIndex, opponentCount),
			})
		end
	end
	return lowerEdges
end

---Computes just the advance spots that can be determined from a match bracket data.
---More are found in populateAdvanceSpots.
---@param data table
---@return table<1|2, {bg: string, type: string, matchId: string}>
function BracketUtil.computeAdvanceSpots(data)
	local advanceSpots = {}

	if data.upperMatchId then
		advanceSpots[1] = {bg = 'up', type = 'advance', matchId = data.upperMatchId}
	end

	if nilIfEmpty(data.winnerto) then
		advanceSpots[1] = {bg = 'up', type = 'custom', matchId = data.winnerto}
	end
	if nilIfEmpty(data.loserto) then
		advanceSpots[2] = {bg = 'stayup', type = 'custom', matchId = data.loserto}
	end

	if Logic.readBool(data.qualwin) then
		advanceSpots[1] = Table.merge(advanceSpots[1], {bg = 'up', type = 'qualify'})
	end
	if Logic.readBool(data.quallose) then
		advanceSpots[2] = Table.merge(advanceSpots[2], {bg = 'stayup', type = 'qualify'})
	end

	return advanceSpots
end

---@param bracket MatchGroupUtilBracket
function BracketUtil.populateAdvanceSpots(bracket)
	if #bracket.matches == 0 then
		return
	end

	-- Loser of semifinals play in third place match
	local firstBracketData = bracket.bracketDatasById[bracket.rootMatchIds[1]]
	local thirdPlaceMatchId = firstBracketData.thirdPlaceMatchId
	if thirdPlaceMatchId and bracket.matchesById[thirdPlaceMatchId] then
		for _, lowerMatchId in ipairs(firstBracketData.lowerMatchIds) do
			local bracketData = bracket.bracketDatasById[lowerMatchId]
			bracketData.advanceSpots[2] = bracketData.advanceSpots[2]
				or {bg = 'stayup', type = 'advance', matchId = thirdPlaceMatchId}
		end
	end

	-- Custom advance spots set via pbg params
	for _, match in ipairs(bracket.matches) do
		local pbgs = Array.mapIndexes(function(ix)
			return Table.extract(match.extradata, 'pbg' .. ix)
		end)
		for i = 1, #pbgs do
			match.bracketData.advanceSpots[i] = Table.merge(
				match.bracketData.advanceSpots[i],
				{bg = pbgs[i], type = 'custom'}
			)
		end
	end
end

---Returns an array of all the IDs of root matches. The matches are sorted in display order.
---@param bracketDatasById table<string, MatchGroupUtilBracketData>
---@return string[]
function BracketUtil.computeRootMatchIds(bracketDatasById)
	-- Matches without upper matches
	local rootMatchIds = {}
	for matchId, bracketData in pairs(bracketDatasById) do
		if not bracketData.upperMatchId
			and not String.endsWith(matchId, 'RxMBR') then
			table.insert(rootMatchIds, matchId)
		end
	end

	Array.sortInPlaceBy(rootMatchIds, function(matchId)
		local coordinates = bracketDatasById[matchId].coordinates
		return coordinates and {coordinates.rootIndex} or {-1, matchId}
	end)

	return rootMatchIds
end

---Populate bracketData.upperMatchId if it is missing. This can happen if the bracket template is missing data.
---@param bracketDatasById table<string, MatchGroupUtilBracketData>
function BracketUtil.backfillUpperMatchIds(bracketDatasById)
	local upperMatchIds = MatchGroupCoordinates.computeUpperMatchIds(bracketDatasById)

	for matchId, bracketData in pairs(bracketDatasById) do
		bracketData.upperMatchId = upperMatchIds[matchId]
	end
end

---Populate bracketData.coordinates if it is missing.
---This can happen if the bracket template has not been recently purged.
---@param matchGroup MatchGroupUtilBracket
function BracketUtil.backfillCoordinates(matchGroup)
	local bracketCoordinates = MatchGroupCoordinates.computeCoordinates(matchGroup)

	Table.mergeInto(matchGroup, bracketCoordinates)
	for matchId, bracketData in pairs(matchGroup.bracketDatasById) do
		bracketData.coordinates = bracketCoordinates.coordinatesByMatchId[matchId]
	end
end

---Convert 0-based indexes to 1-based
---@param record table
---@return table
function BracketUtil.indexTableFromRecord(record)
	return Table.map(record, function(key, value)
		if key:match('Index') and type(value) == 'number' then
			return key, value + 1
		else
			return key, value
		end
	end)
end

---Convert 1-based indexes to 0-based
---@param coordinates table
---@return table
function BracketUtil.indexTableToRecord(coordinates)
	return Table.map(coordinates, function(key, value)
		if key:match('Index') and type(value) == 'number' then
			return key, value - 1
		else
			return key, value
		end
	end)
end

---@param sectionIndex integer
---@param sectionCount integer
---@return string
function BracketUtil.sectionIndexToString(sectionIndex, sectionCount)
	if sectionIndex == 1 then
		return 'upper'
	elseif sectionIndex == sectionCount then
		return 'lower'
	else
		return 'mid'
	end
end


---Converts R01-M003 to R1M3
---@param matchId string
---@return string
function BracketUtil.matchIdToKey(matchId)
	if matchId == 'RxMBR' or matchId == 'RxMTP' then
		return matchId
	end
	local round, matchInRound = matchId:match('^R(%d+)%-M(%d+)$')
	return 'R' .. tonumber(round) .. 'M' .. tonumber(matchInRound)
end

---Converts R1M3 to R01-M003
---@param matchKey string
---@return string
function BracketUtil.matchIdFromKey(matchKey)
	if matchKey == 'RxMBR' or matchKey == 'RxMTP' then
		return matchKey
	end
	local round, matchInRound = matchKey:match('^R(%d+)M(%d+)$')
	if round and matchInRound then
		-- Bracket format
		return 'R' .. string.format('%02d', round) .. '-M' .. string.format('%03d', matchInRound)
	else
		-- Matchlist format
		return string.format('%04d', matchKey)
	end
end

---Splits a matchId like h5HXaqbSVP_R02-M002 into the bracket ID h5HXaqbSVP and the base match ID R02-M002.
---@param matchId string
---@return string?, string?
function BracketUtil.splitMatchId(matchId)
	return matchId:match('^(.-)_([%w-]+)$')
end

return BracketUtil
