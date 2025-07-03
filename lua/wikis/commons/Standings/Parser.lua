---
-- @Liquipedia
-- page=Module:Standings/Parser
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local StandingsParser = {}

---@param rounds {roundNumber: integer, started: boolean, finished:boolean, title: string?}[]
---@param opponents StandingTableOpponentData[]
---@param bgs table<integer, string>
---@param title string?
---@param matches string[]
---@param standingsType StandingsTableTypes
---@param tiebreakers StandingsTiebreaker[]
---@return StandingsTableStorage
function StandingsParser.parse(rounds, opponents, bgs, title, matches, standingsType, tiebreakers)
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
			local pointsFromRound, statusInRound, tiebreakerPoints, matchId, playedMatches
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
			end
			carryData.points = carryData.points + (pointsFromRound or 0)
			---@type {opponent: standardOpponent, standingindex: integer, roundindex: integer, points: number?}
			return {
				opponent = opponent,
				standingsindex = standingsindex,
				roundindex = round.roundNumber,
				points = carryData.points,
				match = carryData.match,
				matches = playedMatches or {},
				extradata = {
					pointschange = pointsFromRound,
					specialstatus = statusInRound,
					tiebreakerpoints = tiebreakerPoints or 0,
					matchid = matchId,
				}
			}
		end)
	end)

	Array.forEach(rounds, function(round)
		StandingsParser.determinePlacements(Array.filter(entries, function(opponentRound)
			return opponentRound.roundindex == round.roundNumber
		end), tiebreakers)
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
		hasdraw = false,
		hasovertime = false,
		haspoints = true,
		finished = isFinished,
		extradata = {
			rounds = rounds,
		},
	}
end

---@param allOpponents {opponent: standardOpponent, standingindex: integer, roundindex: integer, points: number,
---placement: integer?, slotindex: integer?, matches: MatchGroupUtilMatch[], extradata: table}[]
---@param tiedOpponents {opponent: standardOpponent, standingindex: integer, roundindex: integer, points: number,
---placement: integer?, slotindex: integer?, matches: MatchGroupUtilMatch[], extradata: table}[]
---@param tiebreakers StandingsTiebreaker[]
---@param tiebreakerIndex integer
---@return {opponent: standardOpponent, standingindex: integer, roundindex: integer, points: number,
---placement: integer?, slotindex: integer?, matches: MatchGroupUtilMatch[], extradata: table}[][]
local function resolveTieForGroup(allOpponents, tiedOpponents, tiebreakers, tiebreakerIndex)
	local tiebreaker = tiebreakers[tiebreakerIndex]
	if not tiebreaker then
		return { tiedOpponents }
	end

	--TODO: add support for ml & h2h tiebreakers
	local tiebreakerContextType = tiebreaker:getContextType()
	if tiebreakerContextType == 'h2h' or tiebreakerContextType == 'ml' then
		error('Tiebreakers for head-to-head and minileague are not yet supported')
	end

	local _, groupedOpponents = Array.groupBy(tiedOpponents, function(opponent)
		return tiebreaker:valueOf(allOpponents, opponent)
	end)

	local groupedOpponentsInOrder = Array.extractValues(groupedOpponents, Table.iter.spairs, function(_, a, b)
		return a > b
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
---@param tiebreakers StandingsTiebreaker[]
function StandingsParser.determinePlacements(opponentsInRound, tiebreakers)
	local opponentsAfterTie = resolveTieForGroup(opponentsInRound, opponentsInRound, tiebreakers, 1)
	local slotIndex = 1
	Array.forEach(opponentsAfterTie, function(opponentGroup)
		local rank = slotIndex
		Array.forEach(opponentGroup, function(opponent)
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
