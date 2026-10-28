---
-- @Liquipedia
-- page=Module:Standings/Parser
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Info = Lua.import('Module:Info', { loadData = true })
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')
local TiebreakerFactory = Lua.import('Module:Standings/Tiebreaker/Factory')
local TiebreakerScope = Lua.import('Module:Standings/Tiebreaker/Scope')

local StandingsParser = {}

---@alias StandingsParserTiebreaker {id: string, tiebreaker: StandingsTiebreaker}

---@class StandingsParserOptions
---@field drawConfig {match: boolean?}? Explicit draw toggles per level; when unset, draws are detected from the data
---@field overtime boolean? Whether overtime results are tracked separately from regulation results
---@field walkoverGames integer? Games a walkover counts as in the game tiebreakers, unset means not counted
---@field walkoverRounds integer? Rounds a walkover map counts as in the round tiebreakers, unset means not counted

---@param rounds {roundNumber: integer, started: boolean, finished:boolean, title: string?}[]
---@param opponents StandingTableOpponentData[]
---@param bgs table<integer, string>
---@param title string?
---@param matches string[]
---@param standingsType StandingsTableTypes
---@param tiebreakerIds string[]
---@param options StandingsParserOptions?
---@return StandingsTableStorage
function StandingsParser.parse(rounds, opponents, bgs, title, matches, standingsType, tiebreakerIds, options)
	options = options or {}
	-- TODO: When all legacy (of all standing type) have been converted, the wiki variable should be updated
	-- to follow the namespace format. Eg new name could be `standings_standingsindex`
	local lastStandingsIndex = tonumber(Variables.varDefault('standingsindex')) or -1
	local standingsindex = lastStandingsIndex + 1
	Variables.varDefine('standingsindex', standingsindex)

	local isFinished = Array.all(rounds, function(round) return round.finished end)

	local entries = Array.flatMap(opponents, function(opponentData)
		local opponent = opponentData.opponent
		local carryData = {
			points = opponentData.startingPoints or 0,
			match = {w = 0, d = 0, l = 0},
			overtime = options.overtime and {w = 0, l = 0} or nil,
		}
		local opponentRounds = opponentData.rounds

		return Array.map(rounds, function(round)
			local pointsFromRound, statusInRound, tiebreakerPoints, matchId, matchOpponentIndex, playedMatches,
				playedMatchPoints
			if opponentRounds and opponentRounds[round.roundNumber] then
				local thisRoundsData = opponentRounds[round.roundNumber]
				if thisRoundsData.scoreboard then
					pointsFromRound = thisRoundsData.scoreboard.points
				end
				statusInRound = thisRoundsData.specialstatus
				tiebreakerPoints = thisRoundsData.tiebreakerPoints
				matchId = thisRoundsData.matchId
				matchOpponentIndex = thisRoundsData.matchOpponentIndex
				if thisRoundsData.scoreboard.match then
					carryData.match.w = carryData.match.w + thisRoundsData.scoreboard.match.w
					carryData.match.d = carryData.match.d + thisRoundsData.scoreboard.match.d
					carryData.match.l = carryData.match.l + thisRoundsData.scoreboard.match.l
				end
				if carryData.overtime and thisRoundsData.scoreboard.overtime then
					carryData.overtime.w = carryData.overtime.w + thisRoundsData.scoreboard.overtime.w
					carryData.overtime.l = carryData.overtime.l + thisRoundsData.scoreboard.overtime.l
				end
				playedMatches = thisRoundsData.matches
				playedMatchPoints = thisRoundsData.matchPoints
			end
			carryData.points = carryData.points + (pointsFromRound or 0)
			---@type {opponent: standardOpponent, standingindex: integer, roundindex: integer, points: number?,
			---match: {w: integer, d: integer, l: integer}, overtime: {w: integer, l: integer}?}
			return {
				opponent = opponent,
				standingsindex = standingsindex,
				roundindex = round.roundNumber,
				points = carryData.points,
				match = Table.copy(carryData.match),
				overtime = carryData.overtime and Table.copy(carryData.overtime) or nil,
				matches = playedMatches or {},
				matchPoints = playedMatchPoints or {},
				startingPoints = opponentData.startingPoints,
				finished = round.finished,
				manualDefiniteStatus = StandingsParser.resolveManualDefiniteStatus(
					opponentData.definiteStatuses, round.roundNumber
				),
				extradata = {
					pointschange = pointsFromRound,
					specialstatus = statusInRound,
					tiebreakerpoints = tiebreakerPoints or 0,
					disqualified = opponentData.disqualifiedFromRound ~= nil
						and round.roundNumber >= opponentData.disqualifiedFromRound or nil,
					matchid = matchId,
					matchopponentindex = matchOpponentIndex,
					additionalStatsValues = {},
				}
			}
		end)
	end)

	-- Resolve draws once for the whole table, so that every round is displayed in the same format.
	---@type table<StandingsDrawLevel, boolean>
	local draws = {
		match = Logic.nilOr(
			(options.drawConfig or {}).match,
			Array.any(entries, function(entry) return entry.match.d > 0 end)
		),
	}
	---@type StandingsTiebreakerOptions
	local tiebreakerOptions = {
		draws = draws,
		walkoverGames = options.walkoverGames,
		walkoverRounds = options.walkoverRounds,
	}

	-- Tiebreakers are built once, as every round evaluates them again
	---@type table<string, StandingsParserTiebreaker>
	local tiebreakerById = {}
	---@param tiebreakerId string
	---@return StandingsParserTiebreaker
	local function loadTiebreaker(tiebreakerId)
		if not tiebreakerById[tiebreakerId] then
			tiebreakerById[tiebreakerId] = {
				id = tiebreakerId,
				tiebreaker = TiebreakerFactory.tiebreakerFromId(tiebreakerId, tiebreakerOptions),
			}
		end
		return tiebreakerById[tiebreakerId]
	end

	---@param tiebreakerId string
	---@return StandingsAdditionalStat
	local loadStat = function(tiebreakerId)
		local tiebreaker = loadTiebreaker(tiebreakerId).tiebreaker
		local tiebreakerContextType = tiebreaker:getContextType()
		if tiebreakerContextType ~= 'full' then
			return {id = tiebreakerId}
		end
		return {
			id = tiebreakerId,
			title = tiebreaker:headerTitle(),
		}
	end

	local tiebreakers = Array.map(tiebreakerIds, function(tiebreakerId)
		return Table.merge(loadStat(tiebreakerId), {tiebreaker = true})
	end)
	local alwaysStats = Array.map(StandingsParser.alwaysShownStatIds(standingsType), loadStat)
	local additionalStats = Array.extend(alwaysStats, tiebreakers)
	local additionalStatsTiebreakers = Array.map(additionalStats, function(stat) return loadTiebreaker(stat.id) end)
	local placementTiebreakers = Array.map(tiebreakerIds, loadTiebreaker)

	---@type table<integer, TiebreakerOpponent[]>
	local entriesByRound = {}
	Array.forEach(entries, function(entry)
		entriesByRound[entry.roundindex] = entriesByRound[entry.roundindex] or {}
		table.insert(entriesByRound[entry.roundindex], entry)
	end)

	Array.forEach(rounds, function(round)
		StandingsParser.calculateAdditionalStatsValues(
			entriesByRound[round.roundNumber] or {}, additionalStatsTiebreakers
		)
	end)

	Array.forEach(rounds, function(round)
		StandingsParser.determinePlacements(entriesByRound[round.roundNumber] or {}, placementTiebreakers)
	end)
	---@cast entries {opponent: standardOpponent, standingindex: integer, roundindex: integer,
	---points: number, placement: integer?, slotindex: integer}[]

	StandingsParser.setPlacementChange(entries)
	---@cast entries {opponent: standardOpponent, standingindex: integer, roundindex: integer,
	---points: number, placement: integer?, slotindex: integer, placementchange: integer?}[]

	StandingsParser.addStatuses(entries, bgs, 'currentstatus')
	if isFinished then
		StandingsParser.addStatuses(Array.filter(entries, function(opponentRound)
			return opponentRound.roundindex == #rounds
		end), bgs, 'definitestatus')
	end
	StandingsParser.applyManualStatuses(entries)
	StandingsParser.applyDisqualifications(entries)
	---@cast entries {opponent: standardOpponent, standingindex: integer, roundindex: integer, points: number,
	---placement: integer?, slotindex: integer, placementchange: integer?,
	---currentstatus: string?, definitestatus: string?}[]

	---@type StandingsTableStorage
	return {
		standingsindex = standingsindex,
		title = title,
		type = standingsType,
		entries = entries,
		matches = matches,
		roundcount = #rounds,
		hasdraw = draws.match,
		hasovertime = Logic.readBool(options.overtime),
		haspoints = true,
		finished = isFinished,
		extradata = {
			rounds = rounds,
			additionalStats = additionalStats,
		}
	}
end

---@param standingsType StandingsTableTypes
---@return string[]
function StandingsParser.alwaysShownStatIds(standingsType)
	local stats = ((Info.config.standings or {}).alwaysShowStats or {})[standingsType] or {}
	return Array.map(stats, function(stat)
		return TiebreakerFactory.validateAndNormalizeInput(stat)
	end)
end

---With `gameScoresIfBo1`, the status of the opponents of a Bo1 match is taken from its first game. That status is
---read by the scoring and by the game stats, so the games are always needed then.
---@param standingsType StandingsTableTypes
---@param tiebreakerIds string[]
---@return boolean
function StandingsParser.needsGames(standingsType, tiebreakerIds)
	if Info.config.match2.gameScoresIfBo1 then
		return true
	end
	return Array.any(
		Array.extend(StandingsParser.alwaysShownStatIds(standingsType), tiebreakerIds),
		TiebreakerFactory.readsGames
	)
end

---Resolves whether a round has started and finished. Manual input takes priority, otherwise it follows
---the phases of all matches in the round. A round without matches has neither started nor finished.
---@param round {started: boolean?, finished: boolean?}
---@param matchPhases MatchPhase[]?
---@return boolean started
---@return boolean finished
function StandingsParser.resolveRoundStatus(round, matchPhases)
	local phases = matchPhases or {}
	local hasMatches = #phases > 0
	local finished = Logic.nilOr(
		round.finished,
		hasMatches and Array.all(phases, function(phase) return phase == 'finished' end)
	)
	local started = finished or Logic.nilOr(
		round.started,
		Array.any(phases, function(phase) return phase ~= 'upcoming' end)
	)
	return started, finished
end

---Calculate tiebreaker values for all opponents in a round.
---Does not calculate H2H legacy or ML, only "full" tiebreaker types, as the values of the others
---depend on which opponents are tied.
---The others are resolved in resolveTieForGroup() called by determinePlacements(),
---and therefore do not get a value shown in the table.
---@param opponentsInRound TiebreakerOpponent[]
---@param tiebreakers StandingsParserTiebreaker[]
function StandingsParser.calculateAdditionalStatsValues(opponentsInRound, tiebreakers)
	Array.forEach(tiebreakers, function(parserTiebreaker)
		local tiebreakerId, tiebreaker = parserTiebreaker.id, parserTiebreaker.tiebreaker
		local tiebreakerContextType = tiebreaker:getContextType()
		if tiebreakerContextType ~= 'full' then
			return
		end
		Array.forEach(opponentsInRound, function(opponent)
			if opponent.extradata.additionalStatsValues[tiebreakerId] then
				-- We have already calculated this value, no need to do it twice
				return
			end
			opponent.extradata.additionalStatsValues[tiebreakerId] = {
				value = tiebreaker:valueOf(opponentsInRound, opponent),
				display = tiebreaker:display(opponentsInRound, opponent),
			}
		end)
	end)
end

---@param allOpponents TiebreakerOpponent[]
---@param tiedOpponents TiebreakerOpponent[]
---@param tiebreakers StandingsParserTiebreaker[]
---@param tiebreakerIndex integer
---@return TiebreakerOpponent[][]
local function resolveTieForGroup(allOpponents, tiedOpponents, tiebreakers, tiebreakerIndex)
	local parserTiebreaker = tiebreakers[tiebreakerIndex]
	if not parserTiebreaker then
		return { tiedOpponents }
	end
	local tiebreakerId, tiebreaker = parserTiebreaker.id, parserTiebreaker.tiebreaker
	local contextType = tiebreaker:getContextType()

	-- H2H legacy is only defined for ties between 2 or 3 opponents, for bigger ties it is skipped
	if contextType == 'h2hlegacy' and #tiedOpponents > 3 then
		return resolveTieForGroup(allOpponents, tiedOpponents, tiebreakers, tiebreakerIndex + 1)
	end

	-- ML and H2H legacy only look at the matches played among the tied opponents.
	-- The scoped opponents are copies, the groups below keep containing the original opponents.
	local scopedOpponentsByOpponent
	local scopedOpponents
	if contextType ~= 'full' then
		scopedOpponents = TiebreakerScope.restrictTo(tiedOpponents)
		scopedOpponentsByOpponent = {}
		Array.forEach(tiedOpponents, function(opponent, index)
			scopedOpponentsByOpponent[opponent] = scopedOpponents[index]
		end)
	end

	---@param opponent TiebreakerOpponent
	---@return StandingsTiebreakerValue
	local function valueOf(opponent)
		if scopedOpponentsByOpponent then
			return tiebreaker:valueOf(scopedOpponents, scopedOpponentsByOpponent[opponent])
		end
		if not opponent.extradata.additionalStatsValues[tiebreakerId] then
			return tiebreaker:valueOf(allOpponents, opponent)
		end
		return opponent.extradata.additionalStatsValues[tiebreakerId].value
	end

	-- Values can be lists, so they are matched by deep equality instead of being used as table keys
	local valueByOpponent = {}
	---@type StandingsTiebreakerValue[]
	local distinctValues = {}
	Array.forEach(tiedOpponents, function(opponent)
		local value = valueOf(opponent)
		valueByOpponent[opponent] = value
		if not Array.any(distinctValues, function(distinctValue) return Logic.deepEquals(distinctValue, value) end) then
			table.insert(distinctValues, value)
		end
	end)
	table.sort(distinctValues, function(a, b)
		return Array.lexicalCompareIfTable(b, a)
	end)

	-- Highest value first, opponents keep their order within a group
	local groupedOpponentsInOrder = Array.map(distinctValues, function(value)
		return Array.filter(tiedOpponents, function(opponent)
			return Logic.deepEquals(valueByOpponent[opponent], value)
		end)
	end)

	return Array.flatMap(groupedOpponentsInOrder, function(group)
		if #group == 1 then
			return { group }
		end
		return resolveTieForGroup(allOpponents, group, tiebreakers, tiebreakerIndex + 1)
	end)
end

---@param opponentsInRound {opponent: standardOpponent, standingindex: integer, roundindex: integer, points: number,
---placement: integer?, slotindex: integer?, extradata: table}[]
---@param tiebreakers StandingsParserTiebreaker[]
function StandingsParser.determinePlacements(opponentsInRound, tiebreakers)
	local opponentsAfterTie = resolveTieForGroup(opponentsInRound, opponentsInRound, tiebreakers, 1)
	local slotIndex = 1
	Array.forEach(opponentsAfterTie, function(opponentGroup)
		local rank = slotIndex
		Array.forEach(opponentGroup, function(opponent)
			---@cast opponent {opponent: standardOpponent, standingindex: integer, roundindex: integer, points: number,
---placement: integer?, slotindex: integer, placementchange: integer?}
			opponent.placement = rank
			opponent.slotindex = slotIndex
			slotIndex = slotIndex + 1
		end)
	end)
end

---@param opponentEnties {opponent: standardOpponent, standingindex: integer, roundindex: integer, points: number,
---placement: integer?, slotindex: integer, placementchange: integer?}[]
---@param bgs table<integer, string>
---@param field 'currentstatus'|'definitestatus'
function StandingsParser.addStatuses(opponentEnties, bgs, field)
	Array.forEach(opponentEnties, function(opponent)
		opponent[field] = bgs[opponent.slotindex]
	end)
end

---Finds the manually set definite status that is in effect in a round,
---which is the one with the highest round number that is not after the given round.
---@param definiteStatuses table<integer, string>?
---@param roundNumber integer
---@return string?
function StandingsParser.resolveManualDefiniteStatus(definiteStatuses, roundNumber)
	if not definiteStatuses then
		return
	end
	for round = roundNumber, 1, -1 do
		if definiteStatuses[round] then
			return definiteStatuses[round]
		end
	end
end

---Overrides the statuses of opponents with a manually set definite status.
---A definite status is also the current status, so both are set.
---@param opponentEntries {manualDefiniteStatus: string?, currentstatus: string?, definitestatus: string?}[]
function StandingsParser.applyManualStatuses(opponentEntries)
	Array.forEach(opponentEntries, function(opponent)
		local manualStatus = opponent.manualDefiniteStatus
		if manualStatus then
			opponent.currentstatus = manualStatus
			opponent.definitestatus = manualStatus
		end
	end)
end

---Overrides the statuses of disqualified opponents with 'dq'. A disqualification is final,
---so the definite status is set regardless of the standings being finished or not.
---@param opponentEntries {extradata: table, currentstatus: string?, definitestatus: string?}[]
function StandingsParser.applyDisqualifications(opponentEntries)
	Array.forEach(opponentEntries, function(opponent)
		if opponent.extradata.disqualified then
			opponent.currentstatus = 'dq'
			opponent.definitestatus = 'dq'
		end
	end)
end

---@param opponents {opponent: standardOpponent, standingindex: integer, roundindex: integer, points: number,
---placement: integer?, slotindex: integer, placementchange: integer?}[]
function StandingsParser.setPlacementChange(opponents)
	local opponentsByRounds = Array.groupBy(opponents, function (opponent)
		return opponent.opponent
	end)

	Array.forEach(opponentsByRounds, function (opponentByRounds)
		Array.sortInPlaceBy(opponentByRounds, function (opponentInRound)
			return opponentInRound.roundindex
		end)
		local lastPlacement
		Array.forEach(opponentByRounds, function(opponent)
			if lastPlacement and opponent.placement then
				opponent.placementchange = lastPlacement - opponent.placement
			end
			lastPlacement = opponent.placement
		end)
	end)
end

return StandingsParser
