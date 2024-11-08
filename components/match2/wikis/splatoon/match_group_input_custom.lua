---
-- @Liquipedia
-- wiki=splatoon
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')
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
	local maps = {}
	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		map.participants = MapFunctions.getParticipants(map, opponents)
		map.extradata = MapFunctions.getExtraData(map)
		map.finished = MatchGroupInputUtil.mapIsFinished(map)

		local opponentInfo = Array.map(opponents, function(_, opponentIndex)
			local scoreInput = map['score' .. opponentIndex]
			if map.maptype == 'Turf War' and scoreInput then
				scoreInput = scoreInput:gsub('%%', '')
			end
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = scoreInput,
			}, MapFunctions.calculateMapScore(map.winner, map.finished))
			return {score = score, status = status}
		end)

		map.scores = Array.map(opponentInfo, Operator.property('score'))
		if map.finished then
			map.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponentInfo)
			map.walkover = MatchGroupInputUtil.getWalkover(map.resulttype, opponentInfo)
			map.winner = MatchGroupInputUtil.getWinner(map.resulttype, winnerInput, opponentInfo)
		end

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
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

-- Parse extradata information
---@param map table
---@return table
function MapFunctions.getExtraData(map)
	return {
		comment = map.comment,
		maptype = map.maptype,
	}
end

-- Parse participant information

---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getParticipants(map, opponents)
	local allParticipants = {}
	Array.forEach(opponents, function(opponent, opponentIndex)
		local players = Array.mapIndexes(function(playerIndex)
			return opponent.match2players[playerIndex] or Logic.nilIfEmpty(map['t' .. opponentIndex .. 'w' .. playerIndex])
		end)
		local participants, unattachedParticipants = MatchGroupInputUtil.parseParticipants(
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
		Array.forEach(unattachedParticipants, function(participant)
			table.insert(participants, participant)
		end)
		Table.mergeInto(allParticipants, Table.map(participants, MatchGroupInputUtil.prefixPartcipants(opponentIndex)))
	end)

	return allParticipants
end

---@param weaponRaw string
---@return string?
function MapFunctions._cleanWeaponName(weaponRaw)
	if not weaponRaw then
		return nil
	end
	return assert(WeaponNames[string.lower(weaponRaw)], 'Unsupported weapon input: ' .. weaponRaw)
end

---@param winnerInput string|integer|nil
---@param finished boolean
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(winnerInput, finished)
	local winner = tonumber(winnerInput)
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner and not finished then
			return
		end
		return winner == opponentIndex and 1 or 0
	end
end

return CustomMatchGroupInput
