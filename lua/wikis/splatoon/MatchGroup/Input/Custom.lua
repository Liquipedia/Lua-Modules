---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local WeaponNames = mw.loadData('Module:WeaponNames')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}
MatchFunctions.DEFAULT_MODE = 'team'
MatchFunctions.getBestOf = MatchGroupInputUtil.getBestOf

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions)
end

---@param match table
---@param opponents table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

--
-- match related functions
--

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
		mapveto = MatchGroupInputUtil.getMapVeto(match),
		mvp = MatchGroupInputUtil.readMvp(match, opponents),
	}
end

--
-- map related functions
--

---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	return {
		maptype = map.maptype,
	}
end

---@param map table
---@param opponent table
---@param opponentIndex integer
---@return table[]
function MapFunctions.getPlayersOfMapOpponent(map, opponent, opponentIndex)
	local players = Array.mapIndexes(function(playerIndex)
		return map['t' .. opponentIndex .. 'w' .. playerIndex] or map['t' .. opponentIndex .. 'w' .. playerIndex]
	end)
	return MatchGroupInputUtil.parseMapPlayers(
		opponent.match2players,
		players,
		function(playerIndex)
			local player = map['t' .. opponentIndex .. 'p' .. playerIndex]
			return player and {name = player} or nil
		end,
		function(playerIndex, playerIdData)
			local weapon = map['t' .. opponentIndex .. 'w' .. playerIndex]
			return {
				player = playerIdData.name,
				weapon = MapFunctions._cleanWeaponName(weapon),
			}
		end
	)
end

---@param weaponRaw string
---@return string?
function MapFunctions._cleanWeaponName(weaponRaw)
	if not weaponRaw then
		return nil
	end
	return assert(WeaponNames[string.lower(weaponRaw)], 'Unsupported weapon input: ' .. weaponRaw)
end

---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	local winner = tonumber(map.winner)
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner then
			return
		end
		return winner == opponentIndex and 1 or 0
	end
end

---@param props {walkover: string|integer?, winner: string|integer?, score: string|integer?, opponentIndex: integer}
---@param autoScore? fun(opponentIndex: integer): integer?
---@return integer|string? #SCORE
---@return string? #STATUS
function MapFunctions.computeOpponentScore(props, autoScore)
	if props.score then
		props.score = props.score:gsub('%%', '')
	end

	return MatchGroupInputUtil.computeOpponentScore(props, autoScore)
end

return CustomMatchGroupInput
