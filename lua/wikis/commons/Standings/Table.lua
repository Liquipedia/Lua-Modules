---
-- @Liquipedia
-- page=Module:Standings/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')

local StandingsParseWiki = Lua.import('Module:Standings/Parse/Wiki')
local StandingsParseLpdb = Lua.import('Module:Standings/Parse/Lpdb')
local StandingsParser = Lua.import('Module:Standings/Parser')
local StandingsStorage = Lua.import('Module:Standings/Storage')

local StandingsDisplay = Lua.import('Module:Widget/Standings')

local Opponent = Lua.import('Module:Opponent/Custom')

local StandingsTable = {}

---@alias StandingsTableTypes 'ffa'|'swiss'

---@class Scoreboard
---@field points number?
---@field match {w: integer, d: integer, l: integer}

---@class StandingTableOpponentData
---@field rounds {tiebreakerPoints: number?, specialstatus: string, scoreboard: Scoreboard?,
---match: StandingsImportMatch?, matches: StandingsImportMatch[], matchId: string}[]?
---@field opponent standardOpponent
---@field startingPoints number?

---@param frame Frame
---@return Renderable
function StandingsTable.fromTemplate(frame)
	local args = Arguments.getArgs(frame)
	local tableType = args.tabletype
	if tableType ~= 'ffa' and tableType ~= 'swiss' then
		error('Unknown Standing Table Type')
	end
	local title = args.title
	local importScoreFromMatches = Logic.nilOr(Logic.readBoolOrNil(args.import), true)
	local importOpponentFromMatches = Logic.nilOr(Logic.readBoolOrNil(args.importopponents), importScoreFromMatches)

	local parsedData = StandingsParseWiki.parseWikiInput(args)
	local rounds = parsedData.rounds
	local opponents = parsedData.opponents
	local bgs = parsedData.bgs
	local matches = parsedData.matches

	local tiebreakers = StandingsParseWiki.parseTiebreakers(args, tableType)

	if importScoreFromMatches then
		local automaticScoreFunction = StandingsParseWiki.makeScoringFunction(tableType, args)

		local importedOpponents = StandingsParseLpdb.importFromMatches(rounds, automaticScoreFunction)
		opponents = StandingsTable.mergeOpponentsData(opponents, importedOpponents, importOpponentFromMatches)
	end

	local standingsTable = StandingsParser.parse(rounds, opponents, bgs, title, matches, tableType, tiebreakers)

	if tableType == 'swiss' then
		standingsTable.extradata.placemapping = Logic.wrapTryOrLog(StandingsParseWiki.parsePlaceMapping)(args, opponents)
	end

	StandingsStorage.run(standingsTable, {saveVars = true})
	return StandingsDisplay{pageName = mw.title.getCurrentTitle().text, standingsIndex = standingsTable.standingsindex}
end

---Merge a single imported opponent round into a manual opponent round.
---Manual values take priority; imported-only fields (matches, matchId, scoreboard.match) survive.
---@param importedRound table
---@param manualRound table
---@return table
local function mergeRound(importedRound, manualRound)
	local importedScoreboard = importedRound.scoreboard or {}
	local manualScoreboard = manualRound.scoreboard or {}
	return {
		scoreboard = {
			points = manualScoreboard.points ~= nil and manualScoreboard.points or importedScoreboard.points,
			match = importedScoreboard.match,
		},
		specialstatus = manualRound.specialstatus ~= nil and manualRound.specialstatus or importedRound.specialstatus,
		tiebreakerPoints = manualRound.tiebreakerPoints ~= nil
			and manualRound.tiebreakerPoints or importedRound.tiebreakerPoints,
		matches = importedRound.matches,
		matchId = importedRound.matchId,
	}
end

---@param manualOpponents StandingTableOpponentData[]
---@param importedOpponents StandingTableOpponentData[]
---@param addNewOpponents boolean
---@return StandingTableOpponentData[]
function StandingsTable.mergeOpponentsData(manualOpponents, importedOpponents, addNewOpponents)
	--- Add all manual opponents to the new opponents list
	local newOpponents = Array.map(manualOpponents, FnUtil.identity)

	--- Build a name-keyed index of newOpponents for O(1) lookup.
	--- For team opponents a renamed-team fallback (Opponent.same) is used on miss.
	local opponentIndex = {}
	Array.forEach(newOpponents, function(opponentData, idx)
		local name = Opponent.toName(opponentData.opponent)
		if name then
			opponentIndex[name] = idx
		end
	end)

	--- Find all imported opponents
	Array.forEach(importedOpponents, function(importedOpponent)
		local importedName = Opponent.toName(importedOpponent.opponent)
		local manualOpponentId = importedName and opponentIndex[importedName] or 0

		--- On miss, do one fallback linear scan (handles renamed teams via historicaltemplate)
		if manualOpponentId == 0 then
			manualOpponentId = Array.indexOf(newOpponents, function(manualOpponent)
				return Opponent.same(manualOpponent.opponent, importedOpponent.opponent)
			end)
			--- Alias the name so future lookups hit the fast path
			if manualOpponentId ~= 0 and importedName then
				opponentIndex[importedName] = manualOpponentId
			end
		end

		--- If there isn't one, means this is a new opponent
		if manualOpponentId == 0 then
			if addNewOpponents then
				table.insert(newOpponents, importedOpponent)
				local name = Opponent.toName(importedOpponent.opponent)
				if name then
					opponentIndex[name] = #newOpponents
				end
			end
			return
		end

		--- Manual data has priority over imported data; build a new merged opponent table
		local manualOpponent = newOpponents[manualOpponentId]
		local importedRounds = importedOpponent.rounds or {}
		local manualRounds = manualOpponent.rounds or {}

		-- Determine the union of round indices present on either side
		local maxRoundIndex = math.max(#importedRounds, #manualRounds)
		local mergedRounds = {}
		for i = 1, maxRoundIndex do
			local importedRound = importedRounds[i]
			local manualRound = manualRounds[i]
			if importedRound and manualRound then
				mergedRounds[i] = mergeRound(importedRound, manualRound)
			elseif manualRound then
				mergedRounds[i] = manualRound
			else
				mergedRounds[i] = importedRound
			end
		end

		newOpponents[manualOpponentId] = {
			opponent = manualOpponent.opponent,
			startingPoints = manualOpponent.startingPoints ~= nil
				and manualOpponent.startingPoints
				or importedOpponent.startingPoints,
			rounds = mergedRounds,
		}
	end)

	return newOpponents
end

return StandingsTable
