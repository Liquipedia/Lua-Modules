---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MatchGroup/Input/Custom/MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Operator = require('Module:Operator')

local CustomMatchGroupInputMatchPage = {}

---@class valorantMatchDataExtended: valorantMatchData
---@field matchid integer
---@field vod string?

---@param mapInput {matchid: string?, reversed: string?, vod: string?}
---@return dota2MatchDataExtended|table
function CustomMatchGroupInputMatchPage.getMap(mapInput)
	-- If no matchid is provided, assume this as a normal map
	if not mapInput or not mapInput.matchid then
		return mapInput
	end
	local matchId = tonumber(mapInput.matchid)
	assert(matchId, 'Numeric matchid expected, got ' .. mapInput.matchid)

	local map = mw.ext.ValorantDB.getBigMatch(matchId, Logic.readBool(mapInput.reversed))

	assert(map and type(map) == 'table', mapInput.matchid .. ' could not be retrieved.')
	---@cast map valorantMatchDataExtended
	map.matchid = matchId
	map.vod = mapInput.vod

	return map
end

---@param map table
---@param opponentIndex integer
---@return table[]?
function CustomMatchGroupInputMatchPage.getParticipants(map, opponentIndex)
	return nil
end

---@param map table
---@param opponentIndex integer
---@return string?
function CustomMatchGroupInputMatchPage.getFirstSide(map, opponentIndex)
	return nil
end

---@param map table
---@param side 'atk'|'def'|'otatk'|'otdef'
---@param opponentIndex integer
---@return integer?
function CustomMatchGroupInputMatchPage.getScoreFromRounds(map, side, opponentIndex)
	return nil
end

return CustomMatchGroupInputMatchPage
