---
-- @Liquipedia
-- wiki=halo
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local CustomMatchGroupInput = {}
local MatchFunctions = {
	DEFAULT_MODE = 'team',
}
local MapFunctions = {}
local FfaMatchFunctions = {
	DEFAULT_MODE = 'ffa',
}
local FfaMapFunctions = {}
local DEFAULT_BESTOF = 3

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions, FfaMatchFunctions)
end

-- "Mormal" match

---@param match table
---@param opponents table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

---@param games table[]
---@return table[]
function MatchFunctions.removeUnsetMaps(games)
	return Array.filter(games, function(map)
		return map.map ~= nil
	end)
end

---@param bestofInput string|integer?
---@return integer?
function MatchFunctions.getBestOf(bestofInput)
	local bestof = tonumber(bestofInput)

	if bestof then
		Variables.varDefine('bestof', bestof)
		return bestof
	end

	return tonumber(Variables.varDefault('bestof')) or DEFAULT_BESTOF
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param match table
---@param games table[]
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	return {
		mvp = MatchGroupInputUtil.readMvp(match, opponents),
	}
end

---@param match table
---@param opponents table[]
---@return string?
function MatchFunctions.getHeadToHeadLink(match, opponents)
	if
		opponents[1].type ~= Opponent.team or
		opponents[2].type ~= Opponent.team or
		not opponents[1].name or
		not opponents[2].name then

		return nil
	end

	local team1, team2 = string.gsub(opponents[1].name, ' ', '_'), string.gsub(opponents[2].name, ' ', '_')
	local buildQueryFormLink = function(form, template, arguments)
		return tostring(mw.uri.fullUrl('Special:RunQuery/' .. form,
			mw.uri.buildQueryString(Table.map(arguments, function(key, value) return template .. key, value end))
				.. '&_run'
		))
	end

	local headtoheadArgs = {
		['[team1]'] = team1,
		['[team2]'] = team2,
		['[games][is_list]'] = 1,
		['[tiers][is_list]'] = 1,
		['[fromdate][day]'] = '01',
		['[fromdate][month]'] = '01',
		['[fromdate][year]'] = string.sub(match.date,1,4)
	}

	return buildQueryFormLink('Head2head', 'Headtohead', headtoheadArgs)
end

---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	return {
		points1 = map.points1,
		points2 = map.points2,
	}
end

--- FFA Match

---@param match table
---@param opponents table[]
---@param scoreSettings table
---@return table[]
function FfaMatchFunctions.extractMaps(match, opponents, scoreSettings)
	return MatchGroupInputUtil.standardProcessFfaMaps(match, opponents, scoreSettings, FfaMapFunctions)
end

---@param opponents table[]
---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function FfaMatchFunctions.calculateMatchScore(opponents, maps)
	return function(opponentIndex)
		return Array.reduce(Array.map(maps, function(map)
			return map.opponents[opponentIndex].score or 0
		end), Operator.add, 0) + (opponents[opponentIndex].extradata.startingpoints or 0)
	end
end

return CustomMatchGroupInput
