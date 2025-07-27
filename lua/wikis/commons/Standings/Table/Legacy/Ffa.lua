---
-- @Liquipedia
-- page=Module:Standings/Table/Legacy/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local StandingTable = Lua.import('Module:Standings/Table')

local OpponentLibrary = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local StandingTableLegacyFfa = {}

---@param args table
---@return table
function StandingTableLegacyFfa.getStandardParameter(args)
	return {
		tabletype = 'ffa',
		import = false,
		started = true,
		finished = true,
		title = args.title,
		matches = args.matches,
	}
end

---Template:League standings without lobby & Template:League standings without lobby ranked
---@param frame Frame
---@return table
function StandingTableLegacyFfa.withoutLobby(frame)
	local args = Arguments.getArgs(frame)
	local rounds = Table.map(Array.range(1, tonumber(args.rounds) or 1), function(roundIndex)
		return 'round' .. roundIndex, StandingTableLegacyFfa.parseRoundInput(args, roundIndex)
	end)

	---@type StandingTableOpponentData[]
	local opponents = Array.mapIndexes(function(teamIndex)
		return StandingTableLegacyFfa.parseTeamInput(args, teamIndex)
	end)

	local bgs = StandingTableLegacyFfa.parseWikiBgs(args, 'bg')

	return StandingTable.fromTemplate(Table.merge(
		StandingTableLegacyFfa.getStandardParameter(args), {bg = bgs}, rounds, opponents
	))
end

---Template:League_standings_with_past_results & Template:League standings without lobby custom
---@param frame Frame
---@return table
function StandingTableLegacyFfa.pastResults(frame)
	local args = Arguments.getArgs(frame)
	local rounds = Table.map(Array.range(1, tonumber(args.rounds) or 1), function(roundIndex)
		return 'round' .. roundIndex, StandingTableLegacyFfa.parseRoundInput(args, roundIndex)
	end)

	---@type StandingTableOpponentData[]
	local opponents = Array.mapIndexes(function(teamIndex)
		return StandingTableLegacyFfa.parseTeamInput(args, teamIndex)
	end)

	local bgs = StandingTableLegacyFfa.parseWikiBgs(args, 'pbg')

	return StandingTable.fromTemplate(Table.merge(
		StandingTableLegacyFfa.getStandardParameter(args), {bg = bgs}, rounds, opponents
	))
end

---Template:league standings start
---@param frame Frame
function StandingTableLegacyFfa.slotStart(frame)
	local args = Arguments.getArgs(frame)
	Variables.varDefine('standings_legacy_start', Json.stringify(args))
	Variables.varDefine('standings_legacy_count', 0)
end

---Template:league standings slot & Template:league standings slot2
---@param frame Frame
function StandingTableLegacyFfa.slot(frame)
	local args = Arguments.getArgs(frame)
	local cnt = (tonumber(Variables.varDefault('standings_legacy_count')) or 0) + 1
	Variables.varDefine('standings_legacy_slot_' .. cnt, Json.stringify(args))
	Variables.varDefine('standings_legacy_count', cnt)
end

---Template:league standings end & Template:league standings end2
---@param frame Frame
---@return table?
function StandingTableLegacyFfa.templateEnd(frame)
	local cnt = tonumber(Variables.varDefault('standings_legacy_count'))
	if not cnt then
		return
	end
	local startArgs = Json.parseIfString(Variables.varDefault('standings_legacy_start'))
	if not startArgs then
		return
	end
	Variables.varDefine('standings_legacy_start', nil)
	local slots = Array.map(Array.range(1, cnt), function(index)
		local data = (Json.parseIfString(Variables.varDefault('standings_legacy_slot_' .. index)))
		Variables.varDefine('standings_legacy_slot_' .. index, nil)
		return data
	end)

	local rounds = Table.map(Array.range(1, tonumber(startArgs.rounds) or 1), function(roundIndex)
		return 'round' .. roundIndex, StandingTableLegacyFfa.parseRoundInput(startArgs, roundIndex)
	end)

	---@type StandingTableOpponentData[]
	local opponents = Array.map(slots, function(slot)
		return StandingTableLegacyFfa.parseTeamInputManualSlots(slot)
	end)

	-- TODO BGS are gonna be impossible to do cleanly? Ignoring them for now

	return StandingTable.fromTemplate(Table.merge(
		StandingTableLegacyFfa.getStandardParameter(startArgs), rounds, opponents
	))
end

---@param args table
---@param roundIndex integer
---@return {title: string, started: boolean, finished: boolean}
function StandingTableLegacyFfa.parseRoundInput(args, roundIndex)
	local title = args['r' .. roundIndex]
	if not title then
		title = (args.rname or args.roundname or 'Round') .. ' ' .. roundIndex
	end
	return {
		title = title,
		-- Legacy, so let's assume finished
		started = true,
		finished = true,
	}
end

---@param args table
---@param teamIndex integer
---@return {type: OpponentType, [1]: string, tiebreaker: string?, startingpoints: string?, r1: string?}?
function StandingTableLegacyFfa.parseTeamInput(args, teamIndex)
	local team = args['team' .. teamIndex] or args['p' .. teamIndex .. 'team']
	if not team then
		return nil
	end
	local pointsInput = args['standings' .. teamIndex] or args['p' .. teamIndex .. 'results']
	local roundData = Array.parseCommaSeparatedString(pointsInput)
	local rounds = Table.map(roundData, function (roundIndex, value)
		return 'r' .. roundIndex, value
	end)

	local tiebreaker = args['tiebreaker' .. teamIndex] or args['p' .. teamIndex .. 'temp_tie']
	local startingPoints = args['changes' .. teamIndex] or args['p' .. teamIndex .. 'changes']

	return Table.merge(
		{type = Opponent.team, team, tiebreaker = tiebreaker, startingpoints = startingPoints},
		rounds
	)
end

---@param args table
---@return {type: OpponentType, [1]: string, startingpoints: string?, r1: string?}?
function StandingTableLegacyFfa.parseTeamInputManualSlots(args)
	if not args then
		return nil
	end
	local roundDatas = Array.parseCommaSeparatedString(args.results)
	local rounds = Table.map(roundDatas, function (roundIndex, roundData)
		local data = Array.parseCommaSeparatedString(roundData, '-')
		return 'r' .. roundIndex, data[2]
	end)

	local startingPoints = -(tonumber(args.penalty) or 0)

	return Table.merge(
		{type = Opponent.team, args.team, startingpoints = startingPoints},
		rounds
	)
end

--- Ususually can just do an or between the prefix, but one uses both bg and pbg.
--- And one uses only bg, but for the thing that the other one uses pbg.
---@param args table
---@param prefix 'bg'|'pbg'
---@return string
function StandingTableLegacyFfa.parseWikiBgs(args, prefix)
	local bgs = {}
	for _, value, index in Table.iter.pairsByPrefix(args, prefix, {requireIndex = true}) do
		table.insert(bgs, index .. '=' .. value)
	end
	return table.concat(bgs, ',')
end

return StandingTableLegacyFfa
