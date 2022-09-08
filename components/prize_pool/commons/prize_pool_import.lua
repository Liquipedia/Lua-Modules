---
-- @Liquipedia
-- wiki=commons
-- page=Module:PrizePool/Import
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Array = require('Module:Array')
local ArrayExt = require('Module:Array/Ext')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local MathUtil = require('Module:MathUtil')
local Ordinal = require('Module:Ordinal')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MatchGroupCoordinates = Lua.import('Module:MatchGroup/Coordinates', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local Placement = Lua.import('Module:PrizePool/Placement', {requireDevIfEnabled = true})
local TournamentUtil = Lua.import('Module:Tournament/Util', {requireDevIfEnabled = true})

local GROUPSCORE_DELIMITER = '-'
local SCORE_STATUS = 'S'
local DEFAULT_ELIMINATION_STATUS = 'down'
local THIRD_PLACE_MATCH_ID = 'RxMTP'
local GSL_GROUP_OPPONENT_NUMBER = 4
local SWISS_GROUP_TYPE = 'swiss'
local GSL_STYLE_SCORES = {
	{2, 0, 0},
	{2, 0, 1},
	{1, 0, 2},
	{0, 0, 2},
}

local Import = {}

function Import.run(placements, args)
	Import.config = Import._getConfig(args, placements)

	if Import.config.importLimit == 0 or not Import.config.matchGroupsSpec then
		return placements
	end

	return Import._importPlacements(placements)
end

function Import._getConfig(args, placements)
	if String.isEmpty(args.matchGroupId1) and String.isEmpty(args.tournament1)
		and not Import._enableImport(args.import, args.importEnableStartDate) then

		return {}
	end

	return {
		importLimit = Import._importLimit(args.importLimit, placements),
		matchGroupsSpec = TournamentUtil.readMatchGroupsSpec(args)
			or TournamentUtil.currentPageSpec(),
		groupElimStatuses = Table.mapValues(
			mw.text.split(args.groupElimStatuses or DEFAULT_ELIMINATION_STATUS, ','),
			mw.text.trim
		),
		groupScoreDelimiter = args.groupScoreDelimiter or GROUPSCORE_DELIMITER,
		allGroupsUseWdl = Logic.readBool(args.allGroupsUseWdl),
	}
end

function Import._enableImport(importInput, importEnableStartDate)
	local date = TournamentUtil.getContextualDate()
	return Logic.nilOr(
		Logic.readBoolOrNil(importInput),
		importEnableStartDate and (not date or date >= importEnableStartDate)
	)
end

function Import._importLimit(importLimitInput, placements)
	local importLimit = tonumber(importLimitInput)
	if not importLimit then
		return
	end

	-- if the number of entered entries is higher use that instead
	return math.max(placements[#placements].placeEnd or 0, importLimit)
end

-- fills in placements and opponents using data fetched from LPDB
function Import._importPlacements(inputPlacements)
	local stages = TournamentUtil.fetchStages(Import.config.matchGroupsSpec)
	local placementEntries = Array.flatMap(Array.reverse(stages), function(stage, reverseStageIndex)
		return Import._computeStagePlacementEntries(stage, {
					isFinalStage = reverseStageIndex == 1,
					groupElimStatuses = Import.config.groupElimStatuses
				})
	end)

	-- Apply importLimit if set
	if Import.config.importLimit then
		local sums = MathUtil.partialSums(Array.map(placementEntries, function(entries) return #entries end))
		local index = ArrayExt.findIndex(sums, function(sum) return Import.config.importLimit <= sum end)
		if index ~= 0 then
			placementEntries = Array.sub(placementEntries, 1, index - 1)
		end
	end

	return Import._mergePlacements(placementEntries, inputPlacements)
end

-- Compute placements and their entries of all brackets or all group tables in a
-- tournament stage. The placements are ordered from high placement to low.
function Import._computeStagePlacementEntries(stage, options)
	local groupPlacementEntries = Array.map(stage, function(matchGroup)
		return TournamentUtil.isGroupTable(matchGroup)
			and Import._computeGroupTablePlacementEntries(matchGroup, options)
			or Import._computeBracketPlacementEntries(matchGroup, options)
	end)

	local maxPlacementCount = Array.max(Array.map(
			groupPlacementEntries,
			function(placementEntries) return #placementEntries end
		))
	return Array.map(Array.range(1, maxPlacementCount or 0), function(placementIndex)
		return Array.flatMap(groupPlacementEntries, function(placementEntries)
			return placementEntries[placementIndex]
		end)
	end)
end

-- Compute placements and their entries from a GroupTableLeague record.
function Import._computeGroupTablePlacementEntries(standingRecords, options)
	local needsLastVs = Import._needsLastVs(standingRecords)
	local placementEntries = {}
	local placementIndexes = {}

	for _, record in ipairs(standingRecords) do
		if options.isFinalStage or Table.includes(options.groupElimStatuses, record.currentstatus) then
			local entry = {
				date = record.extradata.endTime and DateExt.toYmdInUtc(record.extradata.endTime),
				showMatchDraws = record.extradata.showMatchDraws or false,
			}

			if not record.extradata.placeRange then
				record.extradata.placeRange = {record.placement, record.placement}
			end
			if record.extradata.placeRange[1] == record.extradata.placeRange[2] then
				Table.mergeInto(entry, {
					matchScore = record.scoreboard.match,
					opponent = record.extradata.opponent,
				})
				if entry.opponent.template then
					entry.opponent.name = entry.opponent.template
				else
					entry.opponent.isResolved = true
				end
			end

			entry.needsLastVs = needsLastVs
			entry.matches = record.matches

			if not placementIndexes[record.placement] then
				table.insert(placementEntries, {entry})
				placementIndexes[record.placement] = #placementEntries
			else
				table.insert(placementEntries[placementIndexes[record.placement]], entry)
			end
		end
	end

	return placementEntries
end

function Import._needsLastVs(standingRecords)
	if Import.config.allGroupsUseWdl then
		return false
	elseif (standingRecords[1] or {}).type == SWISS_GROUP_TYPE then
		return true
	elseif #standingRecords ~= GSL_GROUP_OPPONENT_NUMBER then
		return false
	end

	for _, record in pairs(standingRecords) do
		local placement = record.placement
		if not placement or not GSL_STYLE_SCORES[placement] or
			not Table.deepEquals(GSL_STYLE_SCORES[placement], record.scoreboard.match) then
			return false
		end
	end

	return true
end

-- Compute placements and their entries from the match records of a bracket.
function Import._computeBracketPlacementEntries(matchRecords, options)
	local bracket = MatchGroupUtil.makeBracketFromRecords(matchRecords)
	return Array.map(
		Import._computeBracketPlacementGroups(bracket, options),
		function(group)
			return Array.map(group, function(placementEntry)
				local match = bracket.matchesById[placementEntry.matchId]
				return Import._makeEntryFromMatch(placementEntry, match)
			end)
		end
	)
end

function Import._makeEntryFromMatch(placementEntry, match)
	local entry = {
		date = match.date:match('^[%d-]+'),
	}

	if match.winner and 1 <= match.winner and #match.opponents == 2 then
		local entryOpponentIndex = placementEntry.matchPlacement == 1
			and match.winner
			or #match.opponents - match.winner + 1
		local opponent = match.opponents[entryOpponentIndex]
		local vsOpponent = match.opponents[#match.opponents - entryOpponentIndex + 1]
		opponent.isResolved = true
		vsOpponent.isResolved = true

		Table.mergeInto(entry, {
			lastGameScore = {opponent.score, 0, vsOpponent.score},
			lastStatuses = {opponent.status, vsOpponent.status},
			opponent = opponent,
			vsOpponent = vsOpponent,
		})
	end

	return entry
end

-- Computes the placements of a LPDB bracket
-- @options.isFinalStage: If on the last stage, then include placements for
-- winners of final matches.
function Import._computeBracketPlacementGroups(bracket, options)
	local firstDeRoundIndex = Import._findDeRoundIndex(bracket)
	local preTiebreakMatchIds = Import._getPreTiebreakMatchIds(bracket)

	local function getGroupKeys(matchId)
		local coordinates = bracket.coordinatesByMatchId[matchId]

		-- Winners and losers of grand finals
		if coordinates.semanticDepth == 0 then
			return Array.append({},
				options.isFinalStage and {1, coordinates.sectionIndex, 1} or nil,
				{1, coordinates.sectionIndex, 2}
			)

		-- Third place match
		elseif String.endsWith(matchId, THIRD_PLACE_MATCH_ID) then
			return {
				{2, coordinates.depth + 0.5, 1},
				{2, coordinates.depth + 0.5, 2},
			}

		-- Semifinals into third place match
		elseif preTiebreakMatchIds[matchId] then
			return {}

		else
			local groupKeys = {}

			-- Winners of root matches
			if coordinates.depth == 0 and options.isFinalStage then
				table.insert(groupKeys, {0, coordinates.sectionIndex, 1})
			end

			-- Opponents knocked out from sole section (se) or lower bracket (de)
			if coordinates.sectionIndex == #bracket.sections

				-- Include opponents directly knocked out from the upper bracket
				or firstDeRoundIndex and coordinates.roundIndex < firstDeRoundIndex then

				table.insert(groupKeys, {2, coordinates.depth, 2})
			end

			return groupKeys
		end
	end

	local placementEntries = {}
	for matchId in MatchGroupCoordinates.dfs(bracket) do
		for _, groupKey in ipairs(getGroupKeys(matchId)) do
			table.insert(placementEntries, {
				groupKey = groupKey,
				matchId = matchId,
				matchPlacement = groupKey[3],
			})
		end
	end

	Array.sortInPlaceBy(placementEntries, function(entry)
		return Array.extend(
			entry.groupKey,
			bracket.coordinatesByMatchId[entry.matchId].matchIndexInRound
		)
	end)

	return Array.groupBy(placementEntries, function(entry)
		return table.concat(entry.groupKey, '.')
	end)
end

-- Returns the semifinals match IDs of a bracket if the losers also play in a
-- third place match to determine placement.
function Import._getPreTiebreakMatchIds(bracket)
	local firstBracketData = bracket.bracketDatasById[bracket.rootMatchIds[1]]
	local thirdPlaceMatchId = firstBracketData.thirdPlaceMatchId

	local sfMatchIds = {}
	if thirdPlaceMatchId and bracket.matchesById[thirdPlaceMatchId] then
		for _, lowerMatchId in ipairs(firstBracketData.lowerMatchIds) do
			sfMatchIds[lowerMatchId] = true
		end
	end
	return sfMatchIds
end

-- Finds the first round in where upper bracket opponents drop to the lower
-- bracket. Returns nil if it cannot be determined unambiguously, or if the
-- bracket is not double elimination.
function Import._findDeRoundIndex(bracket)
	if #bracket.sections ~= 2 then
		return
	end
	local countsByRound = MatchGroupCoordinates.computeRawCounts(bracket)

	for roundIndex = 1, #bracket.rounds do
		local lbCount = countsByRound[roundIndex][2]
		if lbCount == 0 then
			return roundIndex
		elseif lbCount > 0 then
			return
		end
	end
end

function Import._mergePlacements(lpdbEntries, placements)
	for placementIndex, lpdbPlacement in ipairs(lpdbEntries) do
		placements[placementIndex] = Import._mergePlacement(
			lpdbPlacement,
			placements[placementIndex] or Import._emptyPlacement(placements[placementIndex - 1], #lpdbPlacement)
		)
	end

	return placements
end

function Import._emptyPlacement(priorPlacement, placementSize)
	priorPlacement = priorPlacement or {}
	local placeStart = (priorPlacement.placeEnd or 0) + 1
	local placeEnd = (priorPlacement.placeEnd or 0) + placementSize

	return Placement(
		{placeStart = placeStart, placeEnd = placeEnd},
		priorPlacement.parent,
		priorPlacement.placeEnd or 0
	)
end

function Import._getPlaceDisplay(placeStart, placeEnd)
	local display = Ordinal._ordinal(placeStart)
	if placeEnd > placeStart then
		return display .. '-' .. Ordinal._ordinal(placeEnd)
	end

	return display
end

function Import._mergePlacement(lpdbEntries, placement)
	for opponentIndex, opponent in ipairs(lpdbEntries) do
		placement.opponents[opponentIndex] = Import._mergeEntry(
			opponent,
			Table.mergeInto(placement:_parseOpponents{{}}[1], placement.opponents[opponentIndex]),
			placement
		)
	end

	assert(
		#placement.opponents <= 1 + placement.placeEnd - placement.placeStart,
		'Import: Too many opponents returned from query for placement range '
			.. Import._getPlaceDisplay(placement.placeStart, placement.placeEnd)
	)

	return placement
end

function Import._mergeEntry(lpdbEntry, entry, placement)
	if
		not Opponent.isTbd(entry.opponentData) -- valid manual input
		or Table.isEmpty(lpdbEntry.opponent) -- irrelevant lpdbEntry
		or Opponent.isTbd(lpdbEntry.opponent)
	then
		return entry
	end

	return Table.deepMergeInto(entry, Import._entryToOpponent(lpdbEntry, placement))
end

function Import._entryToOpponent(lpdbEntry, placement)
	local additionalData = {}
	if lpdbEntry.needsLastVs then
		additionalData = Import._groupLastVsAdditionalData(lpdbEntry)
	end

	local score = Import._getScore(lpdbEntry.opponent)
	local vsScore = Import._getScore(lpdbEntry.vsOpponent)
	local lastVsScore
	if score or vsScore then
		lastVsScore = (score or '') .. '-' .. (vsScore or '')
	end

	return placement:_parseOpponents{{
		Import._removeIfTbd(lpdbEntry.opponent),
		wdl = (not lpdbEntry.needsLastVs) and Import._makeGroupScore(lpdbEntry) or nil,
		lastvs = additionalData.lastVs or Import._removeIfTbd(lpdbEntry.vsOpponent),
		lastvsscore = additionalData.score or lastVsScore,
		date = lpdbEntry.date,
		isAlreadyParsed = true,
	}}[1]
end

function Import._removeIfTbd(opponent)
	return (Table.isEmpty(opponent) or Opponent.isTbd(opponent))
		and {} or Table.merge(opponent, {isAlreadyParsed = true})
end

function Import._makeGroupScore(lpdbEntry)
	if not lpdbEntry.matchScore then
		return
	end

	if not lpdbEntry.showMatchDraws then
		table.remove(lpdbEntry.matchScore, 2)
	end

	return table.concat(lpdbEntry.matchScore, Import.config.groupScoreDelimiter)
end

function Import._getScore(opponentData)
	if not opponentData then
		return
	end

	return opponentData.status == SCORE_STATUS and opponentData.score
		or opponentData.status
end

function Import._groupLastVsAdditionalData(lpdbEntry)
	local opponentName = Opponent.toName(lpdbEntry.opponent)
	local matchConditions = {}
	for _, matchId in pairs(lpdbEntry.matches) do
		table.insert(matchConditions, '[[match2id::' .. matchId .. ']]')
	end

	local matchData = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = '[[opponent::' .. opponentName .. ']] AND (' .. table.concat(matchConditions, ' OR ') .. ')',
		order = 'date desc',
		query = 'match2opponents, winner',
		limit = 1
	})

	if not type(matchData) == 'table' or not matchData[1] then
		return {}
	end

	return Import._makeAdditionalDataFromMatch(opponentName, matchData[1])
end

function Import._makeAdditionalDataFromMatch(opponentName, match)
	-- catch unfinished or invalid match
	local winner = tonumber(match.winner)
	if not winner or winner < 1 or #match.match2opponents ~= 2 then
		return {}
	end

	local score, vsScore, lastVs
	for _, opponent in pairs(match.match2opponents) do
		if opponent.name == opponentName then
			score = Import._getScore(opponent)
		else
			vsScore = Import._getScore(opponent)
			lastVs = MatchGroupUtil.opponentFromRecord(opponent)
		end
	end

	local lastVsScore
	if score or vsScore then
		lastVsScore = (score or '') .. '-' .. (vsScore or '')
	end

	return {
		lastVs = lastVs,
		score = lastVsScore,
	}
end

return Import
