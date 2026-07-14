---
-- @Liquipedia
-- page=Module:MatchGroup/Util/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Table = Lua.import('Module:Table')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local Opponent = Lua.import('Module:Opponent/Custom')

local SmashMatchGroupUtil = Table.deepCopy(MatchGroupUtil)

---@class SmashMatchGroupUtilMatch: MatchGroupUtilMatch
---@field opponents SmashStandardOpponent[]

---@param record match2
---@return SmashMatchGroupUtilMatch
function SmashMatchGroupUtil.matchFromRecord(record)
	local match = MatchGroupUtil.matchFromRecord(record)
	---@cast match SmashMatchGroupUtilMatch

	-- Add additional fields to opponents
	SmashMatchGroupUtil.populateOpponents(match)

	return match
end

---Move additional fields from extradata to struct
---@param match SmashMatchGroupUtilMatch
function SmashMatchGroupUtil.populateOpponents(match)
	local opponents = match.opponents

	Array.forEach(opponents, function(opponent, opponentIndex)
		if opponent.type ~= Opponent.solo then
			return
		end

		---@param game MatchGroupUtilGame
		local function getCharacters(game)
			return (game.opponents[opponentIndex].players[1] or {}).characters or {}
		end

		local hasMoreThanOneHeadInAnyGame = Array.any(match.games, function(game)
			return #Array.unique(Array.map(getCharacters(game), function(character)
				return character.name
			end)) > 1
		end)
		if hasMoreThanOneHeadInAnyGame then
			return
		end

		opponent.players[1].game = match.game
		opponent.players[1].extradata.heads = Array.map(match.games, function(game)
			return getCharacters(game)[#getCharacters(game)]
		end)
	end)
end

return SmashMatchGroupUtil
