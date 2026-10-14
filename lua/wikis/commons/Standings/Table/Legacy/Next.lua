---
-- @Liquipedia
-- page=Module:Standings/Table/Legacy/Next
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
local StandingTableLegacySwiss = Lua.import('Module:Standings/Table/Legacy/Swiss')
local TournamentStructure = Lua.import('Module:TournamentStructure')
local Condition = Lua.import('Module:Condition')

---Adaptor for the swiss tables of Module:GroupTableLeague/next
local StandingTableLegacyNext = {}

local MAX_ROUND_COUNT = 30

---Common local Module:GroupTableLeague
---@param frame Frame
---@return Renderable
function StandingTableLegacyNext.run(frame)
	local args = Arguments.getArgs(frame)

	local matchesByRound, roundCount = StandingTableLegacyNext.fetchMatchesByRound(args)
	local rounds = Table.map(Array.range(1, roundCount), function(roundIndex)
		return 'round' .. roundIndex, StandingTableLegacySwiss.parseRoundInput(args, roundIndex, matchesByRound[roundIndex])
	end)

	local opponents = Array.mapIndexes(function(teamIndex)
		if args.opptype == 'solo' then
			return StandingTableLegacySwiss.parseSoloInput(args, teamIndex)
		end
		return StandingTableLegacySwiss.parseTeamInput(args, teamIndex)
	end)

	return StandingTable.fromTemplate(Table.merge(
		StandingTableLegacySwiss.getStandardParameter(args),
		{bg = StandingTableLegacySwiss.parseWikiBgs(args, 'pbg')},
		rounds,
		opponents,
		{tiebreakers = StandingTableLegacySwiss.parseTiebreaker(args)}
	))
end

---Assigns the matches to rounds by their round index (set via `|round=` or the match section),
---falling back to the `round<R>edate` time windows for matches without one.
---@param args table
---@return table<integer, {id: string}[]>, integer
function StandingTableLegacyNext.fetchMatchesByRound(args)
	local matches = Array.map(StandingTableLegacyNext.fetchMatches(args), function(match)
		return {
			id = match.match2id,
			time = DateExt.readTimestamp(match.date),
			round = tonumber((match.match2bracketdata or {}).groupRoundIndex),
		}
	end)

	local roundEndTimes = Array.mapIndexes(function(roundIndex)
		return DateExt.readTimestamp(args['round' .. roundIndex .. 'edate'])
	end)

	local roundCount = StandingTableLegacyNext.computeRoundCount(args, matches, #roundEndTimes)

	local _, matchesByRound = Array.groupBy(matches, function(match)
		if match.round and match.round >= 1 and match.round <= roundCount then
			return match.round
		end
		local roundIndex = Array.indexOf(roundEndTimes, function(endTime)
			return match.time <= endTime
		end)
		return roundIndex ~= 0 and roundIndex or roundCount
	end)

	return matchesByRound, roundCount
end

---`rounds=<n>` sets the number of rounds and `rounds=false` disables reading it from the matches.
---Otherwise it is the highest round index of the matches.
---@param args table
---@param matches {round: integer?}[]
---@param inputRoundCount integer
---@return integer
function StandingTableLegacyNext.computeRoundCount(args, matches, inputRoundCount)
	local roundCount = tonumber(args.rounds)
	if roundCount then
		return roundCount
	end
	local importedRoundCount = 0
	if Logic.readBoolOrNil(args.rounds) ~= false then
		importedRoundCount = Array.max(Array.filter(Array.map(matches, Operator.property('round')), function(round)
			return round <= MAX_ROUND_COUNT
		end)) or 0
	end
	return math.max(inputRoundCount, importedRoundCount, 1)
end

---@param args table
---@return table[]
function StandingTableLegacyNext.fetchMatches(args)
	local tournamentStructureSpec = TournamentStructure.readMatchGroupsSpec(args) or TournamentStructure.currentPageSpec()
	local conditions = Condition.Tree(Condition.BooleanOperator.all)
		:add(TournamentStructure.getMatch2Filter(tournamentStructureSpec))

	local sdate, edate = DateExt.readTimestampOrNil(args.sdate), DateExt.readTimestampOrNil(args.edate)
	if sdate then
		conditions:add(Condition.Node(Condition.ColumnName('date'), Condition.Comparator.ge, sdate))
	end
	if edate then
		conditions:add(Condition.Node(Condition.ColumnName('date'), Condition.Comparator.le, edate))
	end

	return mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = tostring(conditions),
		query = 'match2id, date, match2bracketdata',
		order = 'date asc',
		limit = 1000,
	})
end

return StandingTableLegacyNext
