---
-- @Liquipedia
-- page=Module:CharacterStats/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local BaseCharacterStats = Lua.import('Module:CharacterStats')
local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')

---@class LoLCharacterStats: CharacterStats
local LoLCharacterStats = Class.new(BaseCharacterStats)

---@param game CharacterStatsGame
---@param opponentIndex integer
---@return string[]
function LoLCharacterStats:getTeamCharacters(game, opponentIndex)
	return Array.map(Array.range(1, 5), function (characterIndex)
		return String.nilIfEmpty(game.extradata['team' .. opponentIndex .. 'champion' .. characterIndex])
	end)
end

---@param game CharacterStatsGame
---@param opponentIndex integer
---@return string[]
function LoLCharacterStats:getTeamBans(game, opponentIndex)
	return Array.map(Array.range(1, 5), function (characterIndex)
		return String.nilIfEmpty(game.extradata['team' .. opponentIndex .. 'ban' .. characterIndex])
	end)
end

---@param game CharacterStatsGame
---@param opponentIndex integer
---@return string?
function LoLCharacterStats:getTeamSide(game, opponentIndex)
	return String.nilIfEmpty(game.extradata['team' .. opponentIndex .. 'side'])
end

---@return string[]
function LoLCharacterStats:getSides()
	return {'blue', 'red'}
end

return LoLCharacterStats
