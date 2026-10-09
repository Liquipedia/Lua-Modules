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
local Operator = Lua.import('Module:Operator')
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
	series = 'matchscore',
	diff = 'gamediff',
	['games won'] = 'gamewins',
	['games loss'] = 'gamelosses',
	-- These will map to h2hlegacy once it exists. Until then ml is used, which only differs from it
	-- for ties of more than 3 opponents (h2hlegacy skips those).
	['h2h series'] = 'ml.matchscore',
	['h2h games'] = 'ml.gamediff',
	['minileague points'] = 'ml.points',
	['minileague series%'] = 'ml.matchwinrate',
	['minileague games'] = 'ml.gamediff',
	['minileague games won'] = 'ml.gamewins',
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
		matchdraws = Logic.readBoolOrNil(args.ties),
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

	local opponents = Array.mapIndexes(function(teamIndex)
		if args.opptype == 'solo' then
			return StandingTableLegacySwiss.parseSoloInput(args, teamIndex)
		end
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
		matches = table.concat(Array.map(matches or {}, Operator.property('id')), ','),
	}
end

---@param args table
---@param index integer
---@return string?, string?, string?
local function parseCoreInput(args, index)
	local tiebreaker = args['temp_tie' .. index]
	local startingPoints = args['temp_p' .. index]
	local dq = args['dq' .. index]
	return tiebreaker, startingPoints, dq
end

---Legacy `r<round>bg<index>` maps to `r<round>bg` on the opponent
---@param args table
---@param index integer
---@return table<string, string>
local function parseDefiniteStatuses(args, index)
	return Table.map(Array.range(1, tonumber(args.rounds) or 1), function(roundIndex)
		return 'r' .. roundIndex .. 'bg', args['r' .. roundIndex .. 'bg' .. index]
	end)
end

---@param args table
---@param teamIndex integer
---@return {type: OpponentType, [1]: string, tiebreaker: string?, startingpoints: string?, dq: string?, r1bg: string?}?
function StandingTableLegacySwiss.parseTeamInput(args, teamIndex)
	local team = args['team' .. teamIndex]
	if not team then
		return nil
	end

	local tiebreaker, startingPoints, dq = parseCoreInput(args, teamIndex)

	return Table.merge({
		type = Opponent.team,
		team,
		tiebreaker = tiebreaker,
		startingpoints = startingPoints,
		dq = dq,
	}, parseDefiniteStatuses(args, teamIndex))
end

---@param args table
---@param playerIndex integer
---@return {type: OpponentType, [1]: string, tiebreaker: string?, startingpoints: string?, dq: string?, r1bg: string?}?
function StandingTableLegacySwiss.parseSoloInput(args, playerIndex)
	local player = args['player' .. playerIndex] or args['p' .. playerIndex]
	if not player then
		return nil
	end

	local tiebreaker, startingPoints, dq = parseCoreInput(args, playerIndex)

	return Table.merge({
		type = Opponent.solo,
		player,
		flag = args['player' .. playerIndex .. 'flag'] or args['p' .. playerIndex .. 'flag'],
		link = args['player' .. playerIndex .. 'link'] or args['p' .. playerIndex .. 'link'],
		tiebreaker = tiebreaker,
		startingpoints = startingPoints,
		dq = dq,
	}, parseDefiniteStatuses(args, playerIndex))
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
		assert(mappedTiebreaker, 'Unknown tiebreaker: ' .. value)
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
	if Array.all(matches, function(match) return match.round == nil end) then
		mw.ext.TeamLiquidIntegration.add_category('Pages with missing matches in swiss table')
	end
	local _, matchesByRound = Array.groupBy(matches, function(match)
		return match.round
	end)
	return matchesByRound
end

return StandingTableLegacySwiss
