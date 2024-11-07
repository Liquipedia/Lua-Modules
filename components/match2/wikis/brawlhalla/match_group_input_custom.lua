---
-- @Liquipedia
-- wiki=brawlhalla
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterStandardization = mw.loadData('Module:CharacterStandardization')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local Opponent = Lua.import('Module:Opponent')

local CustomMatchGroupInput = {}
CustomMatchGroupInput.getBestOf = MatchGroupInputUtil.getBestOf
CustomMatchGroupInput.DEFAULT_NODE = 'singles'
CustomMatchGroupInput.DATE_FALLBACKS = {
	'tournament_enddate',
	'tournament_startdate',
}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, CustomMatchGroupInput)
end

---@param match table
---@param matchOpponents table[]
---@return table[]
function CustomMatchGroupInput.extractMaps(match, matchOpponents)
	local maps = {}
	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		if not map.map then
			break
		end
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		map.map = CustomMatchGroupInput.getMapName(map)
		map.extradata = {
			comment = map.comment,
		}
		map.finished = MatchGroupInputUtil.mapIsFinished(map)
		map.opponents = Array.map(matchOpponents, function(opponent, opponentIndex)
			return CustomMatchGroupInput.getParticipantsOfOpponent(map, opponent, opponentIndex)
		end)

		local opponentInfo = Array.map(matchOpponents, function(_, opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			}, CustomMatchGroupInput.calculateMapScore(map.winner, map.finished))
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

---@param maps table[]
---@return fun(opponentIndex: integer): integer
function CustomMatchGroupInput.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param map table
---@param opponent table
---@param opponentIndex integer
---@return table<string, table>?
function CustomMatchGroupInput.getParticipantsOfOpponent(map, opponent, opponentIndex)
	if opponent.type == Opponent.solo then
		return CustomMatchGroupInput._processSoloMapData(opponent.match2players[1], map, opponentIndex)
	end
	return nil
end

---@param player table
---@param map table
---@param opponentIndex integer
---@return table<string, table>
function CustomMatchGroupInput._processSoloMapData(player, map, opponentIndex)
	local char = map['char' .. opponentIndex] or ''

	return {
		players = {
			{
				char = MatchGroupInputUtil.getCharacterName(CharacterStandardization, char),
				player = player.name,
			}
		}
	}
end

---@param winnerInput string|integer|nil
---@param finished boolean
---@return fun(opponentIndex: integer): integer?
function CustomMatchGroupInput.calculateMapScore(winnerInput, finished)
	local winner = tonumber(winnerInput)
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner and not finished then
			return
		end
		return winner == opponentIndex and 1 or 0
	end
end

---@param map table
---@return string?
function CustomMatchGroupInput.getMapName(map)
	if String.isNotEmpty(map.map) and map.map ~= 'TBD' then
		return mw.ext.TeamLiquidIntegration.resolve_redirect(map.map)
	end
	return map.map
end

return CustomMatchGroupInput
