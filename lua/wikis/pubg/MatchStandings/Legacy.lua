---
-- @Liquipedia
-- page=Module:MatchStandings/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local MatchGroup = Lua.import('Module:MatchGroup')
local Opponent = Lua.import('Module:Opponent/Custom')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local MatchStandingsLegacy = {}

---@param frame Frame
function MatchStandingsLegacy.run(frame)
	local args = Arguments.getArgs(frame)

	MatchStandingsLegacy.readMaps(args)
	MatchStandingsLegacy.readOpponents(args)
	MatchStandingsLegacy.readBackground(args)

	Variables.varDefine('islegacy', '')
	return MatchGroup.MatchList(Json.stringifySubTables{
		isLegacy = true,
		id = Table.extract(args, 'id'),
		M1header = Table.extract(args, 'title'),
		M1 = args
	})
end

---@param args table
function MatchStandingsLegacy.readMaps(args)
	for key, _, index in Table.iter.pairsByPrefix(args, 'details') do
		args['map' .. index] = Json.parseIfString(Table.extract(args, key))
	end
end

---@param args table
function MatchStandingsLegacy.readOpponents(args)
	local opponents = Array.mapIndexes(function (opponentIndex)
		local prefix = 'p' .. opponentIndex
		local team = String.trim(Table.extract(args, prefix .. 'team') or '')
		if String.isEmpty(team) then
			return
		end

		---@type string[][]
		local teamResults = Array.map(
			Array.parseCommaSeparatedString(Table.extract(args, prefix .. 'results')),
			function (teamResult)
				return Array.parseCommaSeparatedString(teamResult, '-')
			end
		)

		local teamOffset = Table.extract(args, prefix .. 'changes')

		---@type table<string, any>
		local parsedOpponent = {
			type = Opponent.team,
			template = team,
			startingpoints = tonumber(teamOffset),
		}

		Array.forEach(teamResults, function (result, resultIndex)
			parsedOpponent['m' .. resultIndex] = result
		end)

		return parsedOpponent
	end)

	Array.forEach(opponents, function (opponent, opponentIndex)
		args['opponent' .. opponentIndex] = opponent
	end)
end

---@param args table
function MatchStandingsLegacy.readBackground(args)
	local backgrounds = Table.mapArgumentsByPrefix(args, {'bg'}, function (key, index, prefix)
		return Table.extract(args, key)
	end, true)
	args.bg = table.concat(Array.map(backgrounds, function (background, index)
		return index .. '=' .. background
	end), ',')
end

return MatchStandingsLegacy
