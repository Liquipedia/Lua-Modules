---
-- @Liquipedia
-- page=Module:MatchGroup/Util/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local SmashMatchGroupUtil = Table.deepCopy(MatchGroupUtil)

function SmashMatchGroupUtil.matchFromRecord(record)
	local match = MatchGroupUtil.matchFromRecord(record)

	-- Add additional fields to opponents
	SmashMatchGroupUtil.populateOpponents(match)

	return match
end

---Move additional fields from extradata to struct
---@param match MatchGroupUtilMatch
function SmashMatchGroupUtil.populateOpponents(match)
	local opponents = match.opponents

	Array.forEach(opponents, function(opponent, opponentIndex)
		if opponent.type ~= Opponent.solo then
			return
		end
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
		opponent.players[1].heads = Array.map(match.games, function(game)
			return getCharacters(game)[#getCharacters(game)]
		end)
	end)
end

return SmashMatchGroupUtil
