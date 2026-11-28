---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local HeroPicks = Lua.import('Module:HeroPicks')
local Json = Lua.import('Module:Json')
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local HERO_SLOT_COUNT = 3
local MARTIAL_ARTS_MAP = 'martial arts showdown'

---@class NarakaMapOpponentExtraData
---@field heroes table<string|integer, string>?
---@field tiebreaker integer?

local MapFunctions = {}
local MatchFunctions = {
	OPPONENT_CONFIG = {
		resolveRedirect = true,
		applyUnderScores = true,
		maxNumPlayers = 4,
	},
	DEFAULT_MODE = 'team',
}

local CustomMatchGroupInput = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessFfaMatch(match, MatchFunctions)
end

--
-- map related functions
--

---@param match table
---@param map table
---@param opponents MGIParsedOpponent[]
function MapFunctions.getExtraData(match, map, opponents)
	Array.forEach(map.opponents, function(gameOpponent, opponentIndex)
		gameOpponent.extradata = gameOpponent.extradata or {}
		gameOpponent.extradata.heroes = HeroPicks.readMapOpponent(
			map,
			opponentIndex,
			HERO_SLOT_COUNT,
			map.date or match.date
		)
	end)
end

---@param value string|number|nil
---@param mapIndex integer
---@param opponentIndex integer
---@return integer?
local function readTiePriority(value, mapIndex, opponentIndex)
	if value == nil or value == '' then
		return nil
	end

	local priority = tonumber(value)
	assert(priority and priority >= 0 and priority < math.huge and priority == math.floor(priority),
		'tiebreaker must be a finite non-negative integer (map '
			.. mapIndex .. ', opponent ' .. opponentIndex .. ')')
	return priority
end

--
-- match related functions
--

---@param map table
---@return boolean
local function isMartialArts(map)
	return Array.any({map.map or '', map.mapDisplayName or ''}, function(name)
		return String.trim(name):lower():gsub('_', ' ') == MARTIAL_ARTS_MAP
	end)
end

---@param map table
---@param scoreSettings table[]
---@return table[]
local function getMapScoreSettings(map, scoreSettings)
	local martialArts = isMartialArts(map)
	return Array.map(scoreSettings, function(settings, placement)
		local result = Table.copy(settings)
		local value = map['p' .. placement]
		if value ~= nil and value ~= '' then
			local points = tonumber(value)
			assert(points and points == points and math.abs(points) < math.huge,
				'Map p' .. placement .. ' must be a finite number')
			result.placementPoints = points
		end
		if martialArts then
			result.killPoints = nil
		end
		return result
	end)
end

---@param match table
---@param opponents MGIParsedOpponent[]
---@param scoreSettings table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents, scoreSettings)
	local mapIndexes = {}
	local settingsByMap = {}
	for key, value, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local map = Json.parseIfString(value)
		match[key] = map
		mapIndexes[map] = mapIndex
		settingsByMap[map] = getMapScoreSettings(map, scoreSettings)
	end

	local parser = Table.copy(MapFunctions)

	---@param map table
	---@param matchOpponent MGIParsedOpponent
	---@param opponentIndex integer
	---@return table
	function parser.readMapOpponent(map, matchOpponent, opponentIndex)
		local mapIndex = mapIndexes[map]
		local scoreInput = Json.parseIfString(matchOpponent['m' .. mapIndex]) or {}
		local opponent = MatchGroupInputUtil.makeBattleRoyaleMapOpponentDetails(scoreInput, settingsByMap[map])
		opponent.extradata = opponent.extradata or {}
		opponent.extradata.tiebreaker = readTiePriority(scoreInput.tiebreaker, mapIndex, opponentIndex)
		return opponent
	end

	---@param currentMatch table
	---@param map table
	---@param currentOpponents MGIParsedOpponent[]
	---@return table
	function parser.getExtraData(currentMatch, map, currentOpponents)
		MapFunctions.getExtraData(currentMatch, map, currentOpponents)
		return {
			placementinfo = settingsByMap[map],
		}
	end

	return MatchGroupInputUtil.standardProcessFfaMaps(match, opponents, scoreSettings, parser)
end

---@param opponents MGIParsedOpponent[]
---@param maps table[]
---@return fun(opponentIndex: integer): number
function MatchFunctions.calculateMatchScore(opponents, maps)
	return function(opponentIndex)
		return Array.reduce(Array.map(maps, function(map)
			return map.opponents[opponentIndex].score or 0
		end), Operator.add, 0) + (opponents[opponentIndex].extradata.startingpoints or 0)
	end
end

---@param match table
---@param games table[]
---@param opponents MGIParsedOpponent[]
---@param settings table
---@return table
function MatchFunctions.getExtraData(match, games, opponents, settings)
	return {
		placementinfo = settings.placementInfo,
		settings = settings.settings,
	}
end

return CustomMatchGroupInput
