---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local MapFunctions = {}
local MatchFunctions = {
	OPPONENT_CONFIG = {
		resolveRedirect = true,
		applyUnderScores = true,
		maxNumPlayers = 4,
	},
	DEFAULT_MODE = 'team'
}

local CustomMatchGroupInput = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessFfaMatch(match, MatchFunctions)
end

--
-- match related functions
--
---@param match table
---@param opponents table[]
---@param scoreSettings table
---@return table[]
function MatchFunctions.extractMaps(match, opponents, scoreSettings)
	return MatchGroupInputUtil.standardProcessFfaMaps(match, opponents, scoreSettings, MapFunctions)
end

---@param opponents table[]
---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(opponents, maps)
	return function(opponentIndex)
		return Array.reduce(Array.map(maps, function(map)
			return map.opponents[opponentIndex].score or 0
		end), Operator.add, 0) + (opponents[opponentIndex].extradata.startingpoints or 0)
	end
end

---@param match table
---@param games table[]
---@param opponents table[]
---@param settings table
---@return table
function MatchFunctions.getExtraData(match, games, opponents, settings)
	return {
		placementinfo = settings.placementInfo,
		settings = settings.settings,
	}
end

return CustomMatchGroupInput
