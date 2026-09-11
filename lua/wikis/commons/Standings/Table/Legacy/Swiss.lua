---
-- @Liquipedia
-- page=Module:Standings/Table/Legacy/Swiss
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local StandingTable = Lua.import('Module:Standings/Table')
local TournamentStructure = Lua.import('Module:TournamentStructure')
local Condition = Lua.import('Module:Condition')

local Opponent = Lua.import('Module:Opponent/Custom')

local StandingTableLegacySwiss = {}

local TIEBREAKER_MAPPING_TABLE = {
	points = 'points',
	pts = 'points',
	buchholz = 'buchholz',
	series = 'matchdiff',
	diff = 'gamediff',
	['games won'] = 'gamewins',
}

---@param args table
---@return table
function StandingTableLegacySwiss.getStandardParameter(args)
	return {
		tabletype = 'swiss',
		import = true,
		importopponents = false,
		started = true,
		finished = true,
		exclusive = Logic.nilOr(Logic.readBoolOrNil(args.exclusive), true),
		title = args.title,
		placements = args.placements,
	}
end

---Common local Module:SwissTableLeague
---@param frame Frame
---@return Renderable
function StandingTableLegacySwiss.classic(frame)
	local args = Arguments.getArgs(frame)

	local matchesForRound = StandingTableLegacySwiss.mapTournamentInputToMatchesInRounds(args)
	local rounds = Table.map(Array.range(1, tonumber(args.rounds) or 1), function(roundIndex)
		return 'round' .. roundIndex, StandingTableLegacySwiss.parseRoundInput(args, roundIndex, matchesForRound[roundIndex])
	end)

	---@type StandingTableOpponentData[]
	local opponents = Array.mapIndexes(function(teamIndex)
		return StandingTableLegacySwiss.parseTeamInput(args, teamIndex)
	end)

	local bgs = StandingTableLegacySwiss.parseWikiBgs(args, 'pbg')

	local tiebreakers = StandingTableLegacySwiss.parseTiebreaker(args)

	return StandingTable.fromTemplate(Table.merge(
		StandingTableLegacySwiss.getStandardParameter(args), {bg = bgs}, rounds, opponents, {tiebreakers = tiebreakers}
	))
end

---@param args table
---@param roundIndex integer
---@param matches {id: string}[]
---@return {title: string, started: boolean, finished: boolean, matches: string}
function StandingTableLegacySwiss.parseRoundInput(args, roundIndex, matches)
	local title = (args.roundtitle or 'Round') .. ' ' .. roundIndex
	return {
		title = title,
		-- Legacy, so let's assume finished
		started = true,
		finished = true,
		matches = table.concat(Array.map(matches or {}, function(match) return match.id end), ','),
	}
end

---@param args table
---@param teamIndex integer
---@return {type: OpponentType, [1]: string, tiebreaker: string?, startingpoints: string?, r1: string?}?
function StandingTableLegacySwiss.parseTeamInput(args, teamIndex)
	local team = args['team' .. teamIndex]
	if not team then
		return nil
	end

	local tiebreaker = args['temp_tie' .. teamIndex]
	local startingPoints = args['temp_p' .. teamIndex]

	return Table.merge(
		{type = Opponent.team, team, tiebreaker = tiebreaker, startingpoints = startingPoints}
	)
end

---@param args table
---@param prefix 'bg'|'pbg'
---@return string
function StandingTableLegacySwiss.parseWikiBgs(args, prefix)
	local bgs = {}
	for _, value, index in Table.iter.pairsByPrefix(args, prefix, {requireIndex = true}) do
		table.insert(bgs, index .. '=' .. value)
	end
	return table.concat(bgs, ',')
end

---@param args table
---@return string[]
function StandingTableLegacySwiss.parseTiebreaker(args)
	local tiebreakers = {}
	for _, value in Table.iter.pairsByPrefix(args, 'tiebreaker', {requireIndex = true}) do
		local mappedTiebreaker = TIEBREAKER_MAPPING_TABLE[value]
		if not mappedTiebreaker then
			error('Unknown tiebreaker: ' .. value)
		end
		table.insert(tiebreakers, mappedTiebreaker)
	end
	return tiebreakers
end

---@param args table
---@return table<integer, {id: string}>
function StandingTableLegacySwiss.mapTournamentInputToMatchesInRounds(args)
	local tournamentStructureSpec = TournamentStructure.readMatchGroupsSpec(args) or TournamentStructure.currentPageSpec()
	local match2Filter = TournamentStructure.getMatch2Filter(tournamentStructureSpec)
	local conditions = Condition.Tree(Condition.BooleanOperator.all):add(match2Filter)

	local sdate, edate = DateExt.readTimestampOrNil(args.sdate), DateExt.readTimestampOrNil(args.edate)
	if sdate then
		conditions:add(Condition.Node(Condition.ColumnName('date'), Condition.Comparator.ge, sdate))
	end
	if edate then
		conditions:add(Condition.Node(Condition.ColumnName('date'), Condition.Comparator.le, edate))
	end

	local matches = mw.ext.LiquipediaDB.lpdb('match2',
		{
			conditions = tostring(conditions),
			query = 'match2id, extradata',
			limit = 1000,
		}
	)

	matches = Array.map(matches, function(match)
		local roundText = match.extradata.matchsection or ''
		return {id = match.match2id, round = tonumber(string.match(roundText, 'Round%s*(%d+)'))}
	end)
	local _, matchesByRound = Array.groupBy(matches, function(match)
		return match.round
	end)
	return matchesByRound
end

return StandingTableLegacySwiss
