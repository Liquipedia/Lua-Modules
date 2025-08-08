---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local BrawlerNames = Lua.import('Module:BrawlerNames', {loadData = true})
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local FIRST_PICK_CONVERSION = {
	blue = 1,
	['1'] = 1,
	red = 2,
	['2'] = 2,
}

local DEFAULT_BESTOF_MATCH = 5
local DEFAULT_BESTOF_MAP = 3

-- containers for process helper functions
local MatchFunctions = {}
local MapFunctions = {
	BREAK_ON_EMPTY = true,
}

MatchFunctions.DEFAULT_MODE = 'team'
MatchFunctions.DATE_FALLBACKS = {
	'tournament_enddate',
}

local CustomMatchGroupInput = {}

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
	local games = MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
	Array.forEach(games, function(game, gameIndex)
		game.vod = game.vod or String.nilIfEmpty(match['vodgame' .. gameIndex])
	end)
	return games
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

---@param bestofInput string|integer?
---@return integer?
function MatchFunctions.getBestOf(bestofInput)
	local bestof = tonumber(Logic.emptyOr(bestofInput, Variables.varDefault('bestof')))
	Variables.varDefine('bestof', bestof)
	return bestof or DEFAULT_BESTOF_MATCH
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

---@param map table
---@return integer
function MapFunctions.getMapBestOf(map)
	local bestof = tonumber(Logic.emptyOr(map.bestof, Variables.varDefault('map_bestof')))
	Variables.varDefine('map_bestof', bestof)
	return bestof or DEFAULT_BESTOF_MAP
end

---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	local extradata = {
		bestof = map.bestof,
		maptype = map.maptype,
		firstpick = FIRST_PICK_CONVERSION[string.lower(map.firstpick or '')]
	}

	local bans = {}
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, BrawlerNames)
	for opponentIndex = 1, #opponents do
		bans['team' .. opponentIndex] = {}
		for _, ban in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'b') do
			ban = getCharacterName(ban)
			table.insert(bans['team' .. opponentIndex], ban)
		end
	end

	extradata.bans = bans

	return extradata
end

---@param map table
---@param opponent table
---@param opponentIndex integer
---@return table[]
function MapFunctions.getPlayersOfMapOpponent(map, opponent, opponentIndex)
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, BrawlerNames)
	local players = Array.mapIndexes(function(playerIndex)
		return map['t' .. opponentIndex .. 'p' .. playerIndex] or map['t' .. opponentIndex .. 'c' .. playerIndex]
	end)
	return MatchGroupInputUtil.parseMapPlayers(
		opponent.match2players,
		players,
		function(playerIndex)
			local player = map['t' .. opponentIndex .. 'p' .. playerIndex]
			return player and {name = player} or nil
		end,
		function(playerIndex, playerIdData)
			local brawler = map['t' .. opponentIndex .. 'c' .. playerIndex]
			return {
				player = playerIdData.name,
				brawler = getCharacterName(brawler),
			}
		end
	)
end

return CustomMatchGroupInput
