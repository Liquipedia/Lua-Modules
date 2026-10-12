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

---@param rounds {roundNumber: integer, started: boolean, finished:boolean, title: string?}[]
---@param opponents StandingTableOpponentData[]
---@param bgs table<integer, string>
---@param title string?
---@param matches string[]
---@param standingsType StandingsTableTypes
---@param tiebreakerIds string[]
---@param drawConfig {match: boolean?}? Explicit draw toggles per level; when unset, draws are detected from the data
---@return StandingsTableStorage
function StandingsParser.parse(rounds, opponents, bgs, title, matches, standingsType, tiebreakerIds, drawConfig)
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
		}
		local opponentRounds = opponentData.rounds

		return Array.map(rounds, function(round)
			local pointsFromRound, statusInRound, tiebreakerPoints, matchId, playedMatches, playedMatchPoints
			if opponentRounds and opponentRounds[round.roundNumber] then
				local thisRoundsData = opponentRounds[round.roundNumber]
				if thisRoundsData.scoreboard then
					pointsFromRound = thisRoundsData.scoreboard.points
				end
				statusInRound = thisRoundsData.specialstatus
				tiebreakerPoints = thisRoundsData.tiebreakerPoints
				matchId = thisRoundsData.matchId
				if thisRoundsData.scoreboard.match then
					carryData.match.w = carryData.match.w + thisRoundsData.scoreboard.match.w
					carryData.match.d = carryData.match.d + thisRoundsData.scoreboard.match.d
					carryData.match.l = carryData.match.l + thisRoundsData.scoreboard.match.l
				end
				playedMatches = thisRoundsData.matches
				playedMatchPoints = thisRoundsData.matchPoints
			end
			carryData.points = carryData.points + (pointsFromRound or 0)
			---@type {opponent: standardOpponent, standingindex: integer, roundindex: integer, points: number?,
			---match: {w: integer, d: integer, l: integer}}
			return {
				opponent = opponent,
				standingsindex = standingsindex,
				roundindex = round.roundNumber,
				points = carryData.points,
				match = Table.copy(carryData.match),
				matches = playedMatches or {},
				matchPoints = playedMatchPoints or {},
				startingPoints = opponentData.startingPoints,
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
					additionalStatsValues = {},
				}
			}
		end)
	end)

	-- Resolve draws once for the whole table, so that every round is displayed in the same format.
	---@type table<StandingsDrawLevel, boolean>
	local draws = {
		match = Logic.nilOr(
			(drawConfig or {}).match,
			Array.any(entries, function(entry) return entry.match.d > 0 end)
		),
	}
	---@type StandingsTiebreakerOptions
	local tiebreakerOptions = {draws = draws}

	---@param tiebreakerId string
	---@return {id: string, title: string?}
	local loadTiebreaker = function(tiebreakerId)
		local tiebreaker = TiebreakerFactory.tiebreakerFromId(tiebreakerId, tiebreakerOptions)
		local tiebreakerContextType = tiebreaker:getContextType()
		if tiebreakerContextType ~= 'full' then
			return {id = tiebreakerId}
		end
		return {
			id = tiebreakerId,
			title = tiebreaker:headerTitle(),
		}
	end

	local tiebreakers = Array.map(tiebreakerIds, loadTiebreaker)
	local alwaysStatsToLoad = ((Info.config.standings or {}).alwaysShowStats or {})[standingsType] or {}
	alwaysStatsToLoad = Array.map(alwaysStatsToLoad, function (stat)
		return TiebreakerFactory.validateAndNormalizeInput(stat)
	end)
	local alwaysStats = Array.map(alwaysStatsToLoad, loadTiebreaker)
	local additionalStats = Array.extend(alwaysStats, tiebreakers)
	local additionalStatsIds = Array.map(additionalStats, function(stat) return stat.id end)

	Array.forEach(rounds, function(round)
		StandingsParser.calculateAdditionalStatsValues(Array.filter(entries, function(opponentRound)
			return opponentRound.roundindex == round.roundNumber
		end), additionalStatsIds, tiebreakerOptions)
	end)

	Array.forEach(rounds, function(round)
		StandingsParser.determinePlacements(Array.filter(entries, function(opponentRound)
			return opponentRound.roundindex == round.roundNumber
		end), tiebreakerIds, tiebreakerOptions)
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
		hasovertime = false,
		haspoints = true,
		finished = isFinished,
		extradata = {
			rounds = rounds,
			additionalStats = additionalStats,
		}
	}
end

---Calculate tiebreaker values for all opponents in a round.
---Does not calculate ML, only "full" tiebreaker types, as ML values depend on which opponents are tied.
---ML is resolved in resolveTieForGroup() called by determinePlacements(),
---and therefore does not get a value shown in the table.
---@param opponentsInRound TiebreakerOpponent[]
---@param tiebreakerIds string[]
---@param tiebreakerOptions StandingsTiebreakerOptions?
function StandingsParser.calculateAdditionalStatsValues(opponentsInRound, tiebreakerIds, tiebreakerOptions)
	Array.forEach(tiebreakerIds, function(tiebreakerId)
		local tiebreaker = TiebreakerFactory.tiebreakerFromId(tiebreakerId, tiebreakerOptions)
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
---@param tiebreakerIds string[]
---@param tiebreakerIndex integer
---@param tiebreakerOptions StandingsTiebreakerOptions?
---@return TiebreakerOpponent[][]
local function resolveTieForGroup(allOpponents, tiedOpponents, tiebreakerIds, tiebreakerIndex, tiebreakerOptions)
	local tiebreakerId = tiebreakerIds[tiebreakerIndex]
	if not tiebreakerId then
		return { tiedOpponents }
	end
	local tiebreaker = TiebreakerFactory.tiebreakerFromId(tiebreakerId, tiebreakerOptions)

	-- ML only looks at the matches played among the tied opponents.
	-- The scoped opponents are copies, the groups below keep containing the original opponents.
	local scopedOpponentsByOpponent
	local scopedOpponents
	if tiebreaker:getContextType() ~= 'full' then
		scopedOpponents = TiebreakerScope.restrictTo(tiedOpponents)
		scopedOpponentsByOpponent = {}
		Array.forEach(tiedOpponents, function(opponent, index)
			scopedOpponentsByOpponent[opponent] = scopedOpponents[index]
		end)
	end

	local _, groupedOpponents = Array.groupBy(tiedOpponents, function(opponent)
		if scopedOpponentsByOpponent then
			return tiebreaker:valueOf(scopedOpponents, scopedOpponentsByOpponent[opponent])
		end
		if not opponent.extradata.additionalStatsValues[tiebreakerId] then
			return tiebreaker:valueOf(allOpponents, opponent)
		end
		return opponent.extradata.additionalStatsValues[tiebreakerId].value
	end)

	local groupedOpponentsInOrder = Array.extractValues(groupedOpponents, Table.iter.spairs, function(_, a, b)
		return a > b
	end)

	return Array.flatMap(groupedOpponentsInOrder, function(group)
		if #group == 1 then
			return { group }
		end
		return resolveTieForGroup(allOpponents, group, tiebreakerIds, tiebreakerIndex + 1, tiebreakerOptions)
	end)
end

---@param opponentsInRound {opponent: standardOpponent, standingindex: integer, roundindex: integer, points: number,
---placement: integer?, slotindex: integer?, extradata: table}[]
---@param tiebreakerIds string[]
---@param tiebreakerOptions StandingsTiebreakerOptions?
function StandingsParser.determinePlacements(opponentsInRound, tiebreakerIds, tiebreakerOptions)
	local opponentsAfterTie = resolveTieForGroup(opponentsInRound, opponentsInRound, tiebreakerIds, 1, tiebreakerOptions)
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
