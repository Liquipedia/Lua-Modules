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
	local rounds = Table.map(Array.range(1, tonumber(args.rounds) or 1), function(roundIndex)
		return 'round' .. roundIndex, StandingTableLegacyFfa.parseRoundInput(args, roundIndex)
	end)

	---@type StandingTableOpponentData[]
	local opponents = Array.mapIndexes(function(teamIndex)
		return StandingTableLegacyFfa.parseTeamInput(args, teamIndex)
	end)

	return StandingTable.fromTemplate(Table.merge({
		tabletype = 'ffa',
		import = false,
		started = true,
		finished = true,
		title = args.title,
		matches = args.matches,
		bg = StandingTableLegacyFfa.parseWikiBgs(args),
	}, rounds, opponents))
end

---@param args table
---@param roundIndex integer
---@return {title: string, started: boolean, finished: boolean}
function StandingTableLegacyFfa.parseRoundInput(args, roundIndex)
	local title = args['r' .. roundIndex]
	if not title then
		title = (args.rname or 'Round') .. ' ' .. roundIndex
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
---@return {type: OpponentType, [1]: string, tiebreaker: string?, r1: string?}?
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

	return Table.merge(
		{type = Opponent.team, team, tiebreaker = args['tiebreaker' .. teamIndex]},
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
