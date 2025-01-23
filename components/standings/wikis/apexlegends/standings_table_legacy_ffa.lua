---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:Standings/Table/Legacy/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local StandingTable = Lua.import('Module:Standings/Table')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local StandingTableLegacyFfa = {}

---@param frame Frame
---@return table
function StandingTableLegacyFfa.run(frame)
	local args = Arguments.getArgs(frame)
	local rounds = Array.map(Array.range(1, tonumber(args.rounds) or 1), function(roundIndex)
		return StandingTableLegacyFfa.parseRoundInput(args, roundIndex)
	end)

	---@type StandingTableOpponentData[]
	local opponents = {}
	for _, _, teamIndex in Table.iter.pairsByPrefix(args, 'team', {requireIndex = true}) do
		table.insert(opponents, StandingTableLegacyFfa.parseTeamInput(args, teamIndex))
	end

	return StandingTable.fromTemplate(Table.merge({
		tabletype = 'ffa',
		import = false,
		title = args.title,
		matches = args.matches,
		bg = StandingTableLegacyFfa.parseWikiBgs(args),
	}, rounds, opponents))
end

---@param args table
---@param roundIndex integer
---@return {title: string, started: boolean, finished: boolean}
function StandingTableLegacyFfa.parseRoundInput(args, roundIndex)
	return {
		title = args['r' .. roundIndex],
		-- Legacy, so let's assume finished
		started = true,
		finished = true,
	}
end

---@param args table
---@param teamIndex integer
---@return {type: OpponentType, [1]: string, tiebreaker: string?, r1: string?}
function StandingTableLegacyFfa.parseTeamInput(args, teamIndex)
	local roundData = Array.parseCommaSeparatedString(args['standings' .. teamIndex])
	local rounds = Table.map(roundData, function (roundIndex, value)
		return 'r' .. roundIndex, value
	end)
	return Table.merge(
		{type = Opponent.team, args['team' .. teamIndex], tiebreaker = args['tiebreaker' .. teamIndex]},
		rounds
	)
end

---@param args table
---@return string
function StandingTableLegacyFfa.parseWikiBgs(args)
	local bgs = {}
	for _, value, index in Table.iter.pairsByPrefix(args, 'bg', {requireIndex = true}) do
		table.insert(bgs, index .. '=' .. value)
	end
	return table.concat(bgs, ',')
end

return StandingTableLegacyFfa
