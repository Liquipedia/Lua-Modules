---
-- @Liquipedia
-- page=Module:MatchGroup/Legacy/BMS
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Table = require('Module:Table')

local NUMBER_OF_OPPONENTS = 2
local NUMBER_OF_PLAYERS = 5

local LegacyBracketMatchSummary = {}

---@param frame Frame
---@return string
function LegacyBracketMatchSummary.run(frame)
	local args = Arguments.getArgs(frame)

	local maps = Array.mapIndexes(FnUtil.curry(LegacyBracketMatchSummary.handleMap, args))

	local processedArgs = Table.copy(args)
	Array.forEach(maps, function(map, mapIndex)
		processedArgs['map' .. mapIndex] = map
	end)

	return Json.stringify(processedArgs)
end

---@param args table
---@param mapIndex integer
---@return table?
function LegacyBracketMatchSummary.handleMap(args, mapIndex)
	local prefix = 'g' .. mapIndex

	local scores = Array.parseCommaSeparatedString(args[prefix .. 'score'], '-')

	local map = {
		winner = args[prefix .. 'win'],
		score1 = scores[1],
		score2 = scores[2],
		vod = args['vodgame' .. mapIndex],
	}

	Array.forEach(Array.range(1, NUMBER_OF_OPPONENTS), function(opponentIndex)
		Array.forEach(Array.range(1, NUMBER_OF_PLAYERS), function(playerIndex)
			local playerPrefix = 't' .. opponentIndex .. 'p' .. playerIndex
			map[playerPrefix] = args[prefix .. playerPrefix]
			map[playerPrefix .. 'link'] = args[prefix .. playerPrefix .. 'link']
			map[playerPrefix .. 'flag'] = args[prefix .. playerPrefix .. 'flag']
		end)
	end)

	return Logic.nilIfEmpty(map)
end

return LegacyBracketMatchSummary
