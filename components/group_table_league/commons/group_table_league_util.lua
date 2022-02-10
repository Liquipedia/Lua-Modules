---
-- @Liquipedia
-- wiki=commons
-- page=Module:GroupTableLeague/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local ArrayExt = require('Module:Array/Ext')
local DateExt = require('Module:Date/Ext')
local FeatureFlag = require('Module:FeatureFlag')
local Logic = require('Module:Logic')
local MathUtil = require('Module:MathUtil')
local Opponent = require('Module:Opponent')
local Table = require('Module:Table')
local TournamentUtil = require('Module:Tournament/Util')
local Wdl = require('Module:Wdl')

local GroupTableLeagueUtil = {}

GroupTableLeagueUtil.blankResult = {
	bg = nil,
	dq = nil,
	finalTiebreak = nil,
	gameScore = {0, 0, 0},
	matchScore = {0, 0, 0},
	points = 0,
	rank = nil,
	rankChange = nil,
	slotIndex = nil,
}

function GroupTableLeagueUtil.blankResults(entryCount)
	return Array.map(Array.range(1, entryCount), function()
		return Table.deepCopy(GroupTableLeagueUtil.blankResult)
	end)
end


--[[
Section: LPDB Data Import
]]

function GroupTableLeagueUtil.fetchMatchRecords(rounds, entries, config)
	local startTimeFilter
	if rounds[1].range[1] ~= DateExt.minTimestamp then
		local dateString = DateExt.formatTimestamp('c', rounds[1].range[1] - 1)
		startTimeFilter = '[[date::>' .. dateString .. ']]'
	end

	local endTimeFilter
	if rounds[#rounds].range[2] ~= DateExt.maxTimestamp then
		local dateString = DateExt.formatTimestamp('c', rounds[#rounds].range[2])
		endTimeFilter = '[[date::<' .. dateString .. ']]'
	end

	local expandOpponents = config.importOpponents
		or config.importOpponents == nil and #entries == 0
		or #config.matchGroupsSpec.matchGroupIds ~= 0
	local opponentFilter
	if not expandOpponents then
		local opponentClauses = Array.map(entries, function(entry)
			return '[[opponent::' .. Opponent.toName(entry.opponent) .. ']]'
		end)
		opponentFilter = '(' .. table.concat(opponentClauses, ' or ') .. ')'
	end

	local query = {
		table = 'match2',
		conditions = table.concat(Array.extend(
			TournamentUtil.getMatch2Filter(config.matchGroupsSpec),
			startTimeFilter,
			endTimeFilter,
			opponentFilter
		), ' and '),
		order = 'date asc',
		limit = '1000',
		query = 'match2opponents, winner, date, dateexact, resulttype, finished, match2bracketdata',
	}

	if FeatureFlag.get('debug_query') then
		TournamentUtil.logQueryCall(query)
	end
	local matchRecords = mw.ext.LiquipediaDB.lpdb(query.table, query)

	if #matchRecords == 0 then
		mw.log('Warning: GroupTableLeagueUtil.fetchMatchRecords returned zero match records')
		mw.log('query = ' .. mw.dumpObject(query))
	end

	return matchRecords
end

function GroupTableLeagueUtil.groupMatchRecordsByRound(matchRecords, rounds)
	local function getRound(matchRecord)
		local roundIndex = matchRecord.match2bracketdata.groupRoundIndex
		if type(roundIndex) == 'number'
			and 1 <= roundIndex and roundIndex <= #rounds then
			return roundIndex
		else
			return ArrayExt.findIndex(rounds, function(round)
				return DateExt.readTimestamp(matchRecord.date) < round.range[2]
			end)
		end
	end

	local byRound = Array.map(rounds, function() return {} end)
	for _, matchRecord in ipairs(matchRecords) do
		table.insert(byRound[getRound(matchRecord)], matchRecord)
	end
	return byRound
end

function GroupTableLeagueUtil.importEntries(entries, matchRecords, config)
	local expandOpponents = config.importOpponents
		or config.importOpponents == nil and #entries == 0
	if expandOpponents then
		local opponentsByName = GroupTableLeagueUtil.getOpponentsFromMatchRecords(
			matchRecords,
			{opponentFromRecord = config.opponentFromRecord}
		)
		GroupTableLeagueUtil.mergeOpponents(entries, opponentsByName)
	end
end

function GroupTableLeagueUtil.getOpponentsFromMatchRecords(matchRecords, options)
	options = options or {}
	local opponentFromRecord = options.opponentFromRecord or Opponent.fromMatch2Record

	local opponentsByName = {}
	for _, matchRecord in ipairs(matchRecords) do
		local date = DateExt.toYmdInUtc(matchRecord.date)
		for _, opponentRecord in ipairs(matchRecord.match2opponents) do
			local opponent = Opponent.resolve(opponentFromRecord(opponentRecord), date)
			opponentsByName[Opponent.toName(opponent)] = opponent
		end
	end
	return opponentsByName
end

function GroupTableLeagueUtil.mergeOpponents(entries, opponentsByName)
	local entryIxsByName = GroupTableLeagueUtil.buildEntryIxsByName(entries)
	local opponentNames = Array.extractKeys(opponentsByName)
	-- TODO use a diferent order maybe?
	table.sort(opponentNames)

	for _, name in ipairs(opponentNames) do
		if not entryIxsByName[name] then
			table.insert(entries, {
				opponent = opponentsByName[name],
				aliases = {},
			})
		end
	end
end

function GroupTableLeagueUtil.buildEntryIxsByName(entries)
	local entryIxsByName = {}
	for oppIx, entry in ipairs(entries) do
		entryIxsByName[Opponent.toName(entry.opponent)] = oppIx
		for _, alias in ipairs(entry.aliases) do
			entryIxsByName[alias] = oppIx
		end
	end
	return entryIxsByName
end

function GroupTableLeagueUtil.importRounds(rounds, matchRecords, config)
	if config.importRounds then
		local lpdbStartTimes = GroupTableLeagueUtil.computeStartTimesFromSections(config.importRoundCount, matchRecords)
		local lpdbEndTime = GroupTableLeagueUtil.computeEndTime(matchRecords)
		GroupTableLeagueUtil.mergeRounds(rounds, config.importRoundCount, lpdbStartTimes, lpdbEndTime)
	end
end

GroupTableLeagueUtil.maxImportRoundCount = 30

--[[
Infer rounds from match2.match2bracketdata.groupRoundIndex, set via
Template:MatchSection or {{Match|round=}}.
]]
function GroupTableLeagueUtil.computeStartTimesFromSections(importRoundCount, matchRecords)
	local roundLimit = importRoundCount or GroupTableLeagueUtil.maxImportRoundCount

	local startTimes = {}
	for _, matchRecord in ipairs(matchRecords) do
		local roundIndex = matchRecord.match2bracketdata.groupRoundIndex
		if type(roundIndex) == 'number'
			and 1 <= roundIndex and roundIndex <= roundLimit
			and not startTimes[roundIndex]
			and Logic.readBool(matchRecord.dateexact) then
			startTimes[roundIndex] = DateExt.readTimestamp(matchRecord.date)
		end
	end

	return startTimes
end

--[[
Infer the end time of the last round to be the a hour after the final match.
]]
function GroupTableLeagueUtil.computeEndTime(matchRecords)
	local lastMatch = matchRecords[#matchRecords]
	if lastMatch then
		local date = DateExt.readTimestamp(lastMatch.date)
		return Logic.readBool(lastMatch.dateexact)
			and date + 3600
			or date + 24 * 3600
	else
		return nil
	end
end

function GroupTableLeagueUtil.mergeRounds(rounds, importRoundCount, lpdbStartTimes, lpdbEndTime)
	assert(#rounds > 0)
	local roundCount = math.max(
		#rounds,
		importRoundCount or 0,
		Array.max(Array.extractKeys(lpdbStartTimes)) or 0
	)

	local startTimes = {}
	for roundIx = roundCount, 1, -1 do
		local nextStartTime = startTimes[roundIx + 1] or DateExt.maxTimestamp
		local startTime = roundIx <= #rounds and rounds[roundIx].range[1]
			or lpdbStartTimes[roundIx]
			or nextStartTime
		startTimes[roundIx] = math.min(startTime, nextStartTime)
	end

	local endTime = math.max(
		startTimes[#startTimes],
		rounds[#rounds].range[2] ~= DateExt.maxTimestamp and rounds[#rounds].range[2]
			or lpdbEndTime
			or DateExt.maxTimestamp
	)

	local newRounds = Array.map(startTimes, function(startTime, roundIx)
		local range = {
			startTime,
			startTimes[roundIx + 1] or endTime,
		}
		return {range = range}
	end)

	-- Clear and replace rounds
	for roundIx = 1, #rounds do
		rounds[roundIx] = nil
	end
	Array.extendWith(rounds, newRounds)
end


--[[
Section: Results Computation
]]

function GroupTableLeagueUtil.computeResults(groupTable)
	local results = Table.deepCopy(groupTable.manualResultsByRound.initial)

	for _, matchRecord in ipairs(groupTable.matchRecords) do
		GroupTableLeagueUtil.applyMatchRecord(results, matchRecord, groupTable.entryIxsByName, groupTable.config)
	end

	for roundIx = 1, #groupTable.rounds do
		local manualResults = groupTable.manualResultsByRound[roundIx]
		if manualResults then
			GroupTableLeagueUtil.mergeResultsInto(results, manualResults)
		end
	end

	GroupTableLeagueUtil.addMatchPoints(results, groupTable.config)

	local ranks = GroupTableLeagueUtil.computeRanks(groupTable, results)
	GroupTableLeagueUtil.mergeRanks(results, ranks)

	return results
end

function GroupTableLeagueUtil.applyMatchRecord(results, matchRecord, entryIxsByName, config)
	if #matchRecord.match2opponents ~= 2 then
		return
	end

	local oppIx1 = entryIxsByName[matchRecord.match2opponents[1].name]
	local oppIx2 = entryIxsByName[matchRecord.match2opponents[2].name]
	if config.exclusive and not (oppIx1 and oppIx2) then
		return
	end

	local finished = Logic.readBool(matchRecord.finished)

	local winner = tonumber(matchRecord.winner)
	local matchScore = matchRecord.resulttype == 'draw' and {0, 1, 0}
		or winner == 1 and {1, 0, 0}
		or winner == 2 and {0, 0, 1}
		or {0, 0, 0}

	local function nonNegative(x) return math.max(tonumber(x) or 0, 0) end
	local opponentScores = Array.map(matchRecord.match2opponents, function(record)
		return nonNegative(record.score)
	end)
	local gameScore = matchRecord.resulttype ~= 'default' and {opponentScores[1], 0, opponentScores[2]}
		or winner == 1 and {config.gamesPerWalkover, 0, 0}
		or winner == 2 and {0, 0, config.gamesPerWalkover}
		or {0, 0, 0}

	local function getGamePoints(gameScore_)
		return config.pointsByGameScore[table.concat(gameScore_, '-')] or 0
	end

	if oppIx1 then
		local result = results[oppIx1]
		Wdl.addTo(result.matchScore, matchScore)
		Wdl.addTo(result.gameScore, gameScore)
		if finished then
			result.points = result.points + getGamePoints(gameScore)
		end
	end
	if oppIx2 then
		local result = results[oppIx2]
		Wdl.addTo(result.matchScore, Wdl.swap(matchScore))
		Wdl.addTo(result.gameScore, Wdl.swap(gameScore))
		if finished then
			result.points = result.points + getGamePoints(Wdl.swap(gameScore))
		end
	end
end

function GroupTableLeagueUtil.addMatchPoints(results, config)
	for _, result in ipairs(results) do
		result.points = result.points
			+ MathUtil.dotProduct(config.pointsPerMatch, result.matchScore)
	end
end

function GroupTableLeagueUtil.computeRanks(groupTable, results, roundIx)
	local rankGroups, finalGroups = GroupTableLeagueUtil.computeOrdering(groupTable, results, roundIx)
	return GroupTableLeagueUtil.groupsToRanks(rankGroups, finalGroups)
end

function GroupTableLeagueUtil.mergeRanks(results, ranks)
	for oppIx, rankEntry in ipairs(ranks) do
		results[oppIx].rank = rankEntry.rank
		results[oppIx].slotIndex = rankEntry.slotIndex
	end
end

--[[
Computes the ordering of opponents in a round using the metrics specified on
config.metricNames.
]]
function GroupTableLeagueUtil.computeOrdering(groupTable, results, roundIx)
	roundIx = roundIx or #groupTable.rounds

	local oppIndexGroups = {Array.range(1, #groupTable.entries)}
	local rankGroups

	for metricIx, metricName in ipairs(groupTable.config.metricNames) do
		local evalMethod, tiedMetricName = metricName:match('^(%w+)%.(%w+)$')
		local metric = groupTable.config.getMetric(tiedMetricName or metricName)

		local scoreGroup
		if not evalMethod then
			scoreGroup = function(oppIxs)
				return Array.map(oppIxs, function(oppIx)
					return metric(results[oppIx])
				end)
			end
		elseif evalMethod == 'ml' then
			-- Mini-league tiebreaks evaluate tied opponents as a group
			scoreGroup = function(tiedOppIxs)
				local tiedEntries = Array.map(tiedOppIxs, function(oppIx) return groupTable.entries[oppIx] end)
				local mlResults = GroupTableLeagueUtil.computeMiniLeagueResults(
					tiedEntries,
					Array.sub(groupTable.matchRecordsByRound, 1, roundIx),
					groupTable.config
				)
				return Array.map(tiedOppIxs, function(_, ix)
					return metric(mlResults[ix])
				end)
			end
		elseif evalMethod == 'h2h' then
			-- Head-to-head tiebreaks evaluate opponents pairwise in a group
			scoreGroup = function(tiedOppIxs)
				local tiedEntries = Array.map(tiedOppIxs, function(oppIx) return groupTable.entries[oppIx] end)
				local h2hResults = GroupTableLeagueUtil.computeHeadToHeadResults(
					tiedEntries,
					Array.sub(groupTable.matchRecordsByRound, 1, roundIx),
					groupTable.config
				)
				local scores = GroupTableLeagueUtil.scoreH2hResults(h2hResults, metric)
				return Array.map(tiedOppIxs, function(_, ix) return scores[ix] end)
			end
		end

		oppIndexGroups = GroupTableLeagueUtil.sortGroupsBy(oppIndexGroups, scoreGroup)

		-- Use up to the second to last metric for ranking. Only use the final
		-- metric for display.
		if metricIx == math.max(#groupTable.config.metricNames - 1, 1) then
			rankGroups = oppIndexGroups
		end
	end

	return rankGroups, oppIndexGroups
end

--[[
Computes result.rank and result.slotIndex from the result of
GroupTableLeagueUtil.computeRoundRanks
]]
function GroupTableLeagueUtil.groupsToRanks(rankGroups, finalGroups)
	local ranks = {}

	local rank = 1
	for _, group in ipairs(Array.reverse(rankGroups)) do
		for _, oppIx in ipairs(group) do
			ranks[oppIx] = {rank = rank}
		end
		rank = rank + #group
	end

	for slotIndex, oppIx in ipairs(Array.flatten(Array.reverse(finalGroups))) do
		ranks[oppIx].slotIndex = slotIndex
	end

	return ranks
end

--[[
Sorts an array of arrays. The outer array is already sorted. The inner arrays
are the tied entries from previous calls to GroupTableLeagueUtil.sortGroupsBy.

Repeated calls to sortGroupsBy with different tiebreaker criteria effectively
sorts an array based on the tiebreakers. The sorting is complete when each
group has size 1, or when the tiebreakers run out.
]]
function GroupTableLeagueUtil.sortGroupsBy(groups, scoreGroup)
	return Array.flatMap(groups, function(group)
		return #group > 1
			and GroupTableLeagueUtil.sortAndGroup(group, scoreGroup(group))
			or {group}
	end)
end

function GroupTableLeagueUtil.sortAndGroup(elems, scores)
	local ixs = Array.range(1, #elems)
	Array.sortInPlaceBy(ixs, function(ix) return scores[ix] end)
	local ixGroups = ArrayExt.groupAdjacentBy(ixs, function(ix) return scores[ix] end)
	return Array.map(ixGroups, function(ixGroup)
		return Array.map(ixGroup, function(ix) return elems[ix] end)
	end)
end

--[[
Sets up a mini-league with with the specified opponents, and computes the
results of opponents within the mini-league. Used to evaluate mini-league
tiebreakers.
]]
function GroupTableLeagueUtil.computeMiniLeagueResults(entries, matchRecordsByRound, config_)
	local entryIxsByName = GroupTableLeagueUtil.buildEntryIxsByName(entries)
	local config = Table.merge(config_, {exclusive = true})

	local results = GroupTableLeagueUtil.blankResults(#entries)
	for _, matchRecords in ipairs(matchRecordsByRound) do
		for _, matchRecord in ipairs(matchRecords) do
			GroupTableLeagueUtil.applyMatchRecord(results, matchRecord, entryIxsByName, config)
		end
	end
	return results
end

--[[
Sets up a mini-league with with the specified opponents, and computes the
head-to-head results for each pair of opponents in the mini-league. Used to
evaluate head-to-head tiebreakers.
]]
function GroupTableLeagueUtil.computeHeadToHeadResults(entries, matchRecordsByRound, config_)
	local entryIxsByName = GroupTableLeagueUtil.buildEntryIxsByName(entries)
	local config = Table.merge(config_, {exclusive = true})

	local h2hResults = Array.map(Array.range(1, #entries), function()
		return Array.map(Array.range(1, #entries), function()
			return Table.deepCopy(GroupTableLeagueUtil.blankResult)
		end)
	end)

	local function applyMatchRecord(matchRecord)
		local oppIx1 = entryIxsByName[matchRecord.match2opponents[1].name]
		local oppIx2 = entryIxsByName[matchRecord.match2opponents[2].name]
		if oppIx1 and oppIx2 then
			local resultsProxy = {
				[oppIx1] = h2hResults[oppIx1][oppIx2],
				[oppIx2] = h2hResults[oppIx2][oppIx1],
			}
			GroupTableLeagueUtil.applyMatchRecord(resultsProxy, matchRecord, entryIxsByName, config)
		end
	end

	for _, matchRecords in ipairs(matchRecordsByRound) do
		for _, matchRecord in ipairs(matchRecords) do
			if #matchRecord.match2opponents == 2 then
				applyMatchRecord(matchRecord)
			end
		end
	end

	return h2hResults
end

--[[
Compute placements in a tied group using a head to head metric.

For each pair of opponents in the mini-league, results are compiled from matches
between the pair. If an opponent has a higher or equal metric value in every
head-to-head result, then they are placed at the top. If an opponent has a
lower or equal metric value in every head-to-head result, then they are placed
at the bottom. The process is then repeated for the remaining opponents in
successively smaller mini-leagues, until the mini-league is void of top and
bottom opponents.
]]
function GroupTableLeagueUtil.scoreH2hResults(h2hResults, metric)
	-- Indexes of opponents that have yet to be placed at top or bottom
	local oppIxs = {}
	for oppIx = 1, #h2hResults do
		oppIxs[oppIx] = true
	end

	local scores = {}

	local function scoreTopsAndBottoms(roundIx)
		for oppIx1, _ in pairs(oppIxs) do
			local hasWon = false
			local hasLost = false
			for oppIx2, _ in pairs(oppIxs) do
				if hasWon and hasLost then
					break
				end
				if oppIx1 ~= oppIx2 then
					local opp1Value = metric(h2hResults[oppIx1][oppIx2])
					local opp2Value = metric(h2hResults[oppIx2][oppIx1])
					if Array.lexicalCompareIfTable(opp1Value, opp2Value) then
						hasLost = true
					elseif Array.lexicalCompareIfTable(opp2Value, opp1Value) then
						hasWon = true
					end
				end
			end

			-- Score if top opponent
			if not hasLost then
				scores[oppIx1] = #h2hResults - roundIx
				oppIxs[oppIx1] = nil

			-- Score if bottom opponent
			elseif not hasWon then
				scores[oppIx1] = -#h2hResults + roundIx
				oppIxs[oppIx1] = nil
			end
		end
	end

	-- Repeatedly extract top and bottom opponents
	local prevSize = 0
	for roundIx = 1, math.huge do
		scoreTopsAndBottoms(roundIx)
		local size = Table.size(scores)
		if size == prevSize then
			-- All remaining opponents are not top or bottom
			break
		end
		prevSize = size
	end

	-- Remaining opponents are assigned neutral score
	for oppIx, _ in pairs(oppIxs) do
		scores[oppIx] = 0
	end

	return scores
end

--[[
Merges the second opponent result into the first opponent result.
]]
function GroupTableLeagueUtil.mergeResultsInto(results, resultUpdates)
	for oppIx, result in ipairs(results) do
		local update = resultUpdates[oppIx]

		Wdl.addTo(result.matchScore, update.matchScore)
		Wdl.addTo(result.gameScore, update.gameScore)
		result.bg = update.bg or result.bg
		result.dq = Logic.nilOr(update.dq, result.dq)
		result.finalTiebreak = update.finalTiebreak or result.finalTiebreak
		result.points = result.points + update.points
	end
end

local Metric = {}

function Metric.matchScore(result)
	return {result.matchScore[1], -result.matchScore[3]}
end
function Metric.matchDiff(result)
	return result.matchScore[1] - result.matchScore[3]
end
function Metric.matchWins(result)
	return result.matchScore[1]
end
function Metric.matchDraws(result)
	return result.matchScore[2]
end
function Metric.matchLosses(result)
	return -result.matchScore[3]
end
function Metric.matchCount(result)
	return MathUtil.sum(result.matchScore)
end
function Metric.matchWinRate(result)
	local matchCount = MathUtil.sum(result.matchScore)
	return matchCount ~= 0 and result.matchScore[1] / matchCount or 0.5
end

function Metric.gameScore(result)
	return {result.gameScore[1], -result.gameScore[3]}
end
function Metric.gameDiff(result)
	return result.gameScore[1] - result.gameScore[3]
end
function Metric.gameWins(result)
	return result.gameScore[1]
end
function Metric.gameLosses(result)
	return -result.gameScore[3]
end
function Metric.gameCount(result)
	return MathUtil.sum(result.gameScore)
end

function Metric.points(result)
	return result.points
end

function Metric.finalTiebreak(result)
	return result.finalTiebreak
end

function Metric.dq(result)
	return result.dq and 0 or 1
end

GroupTableLeagueUtil.Metric = Metric

return GroupTableLeagueUtil
