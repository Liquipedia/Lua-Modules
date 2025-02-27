---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Parser
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Variables = require('Module:Variables')

local StandingsParser = {}

---@param rounds {roundNumber: integer, started: boolean, finished:boolean, title: string?}[]
---@param opponents StandingTableOpponentData[]
---@param bgs table<integer, string>
---@param title string?
---@param matches string[]
---@param standingsType StandingsTableTypes
---@return StandingsTableStorage
function StandingsParser.parse(rounds, opponents, bgs, title, matches, standingsType)
	-- TODO: When all legacy (of all standing type) have been converted, the wiki variable should be updated
	-- to follow the namespace format. Eg new name could be `standings_standingsindex`
	local lastStandingsIndex = tonumber(Variables.varDefault('standingsindex')) or -1
	local standingsindex = lastStandingsIndex + 1
	Variables.varDefine('standingsindex', standingsindex)

	local isFinished = Array.all(rounds, function(round) return round.finished end)

	local entries = Array.flatMap(opponents, function(opponentData)
		local opponent = opponentData.opponent
		local scoreboardCarry = {
			points = opponentData.startingPoints or 0,
			match = {w = 0, d = 0, l = 0},
		}
		local opponentRounds = opponentData.rounds

		return Array.map(rounds, function(round)
			local pointsFromRound, statusInRound, tiebreakerPoints
			if opponentRounds and opponentRounds[round.roundNumber] then
				local thisRoundsData = opponentRounds[round.roundNumber]
				if thisRoundsData.scoreboard then
					pointsFromRound = thisRoundsData.scoreboard.points
				end
				statusInRound = thisRoundsData.specialstatus
				tiebreakerPoints = thisRoundsData.tiebreakerPoints
				scoreboardCarry.match.w = scoreboardCarry.match.w + thisRoundsData.scoreboard.match.w
				scoreboardCarry.match.d = scoreboardCarry.match.d + thisRoundsData.scoreboard.match.d
				scoreboardCarry.match.l = scoreboardCarry.match.l + thisRoundsData.scoreboard.match.l
			end
			scoreboardCarry.points = scoreboardCarry.points + (pointsFromRound or 0)
			---@type {opponent: standardOpponent, standingindex: integer, roundindex: integer, points: number?}
			return {
				opponent = opponent,
				standingsindex = standingsindex,
				roundindex = round.roundNumber,
				points = scoreboardCarry.points,
				match = scoreboardCarry.match,
				extradata = {
					pointschange = pointsFromRound,
					specialstatus = statusInRound,
					tiebreakerpoints = tiebreakerPoints or 0,
				}
			}
		end)
	end)

	Array.forEach(rounds, function(round)
		StandingsParser.determinePlacements(Array.filter(entries, function(opponentRound)
			return opponentRound.roundindex == round.roundNumber
		end))
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

---@param opponentsInRound {opponent: standardOpponent, standingindex: integer, roundindex: integer, points: number,
---placement: integer?, slotindex: integer?, extradata: table}[]
function StandingsParser.determinePlacements(opponentsInRound)
	table.sort(opponentsInRound, function(opponent1, opponent2)
		if opponent1.points ~= opponent2.points then
			return opponent1.points > opponent2.points
		end
		return opponent1.extradata.tiebreakerpoints > opponent2.extradata.tiebreakerpoints
	end)

	local lastPts = math.huge
	Array.forEach(opponentsInRound, function(opponent, slotindex)
		opponent.slotindex = slotindex
		opponent.placement = lastPts == opponent.points and opponentsInRound[slotindex - 1].placement or slotindex
		lastPts = opponent.points
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
