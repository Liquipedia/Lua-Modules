---
-- @Liquipedia
-- page=Module:GameTable/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')

local GameTableCharacter = Lua.import('Module:GameTable/Character')

---@class Dota2CharacterGameTable: CharacterGameTable
local CustomCharacterGameTable = Class.new(GameTableCharacter)

---@return integer
function CustomCharacterGameTable:getNumberOfBans()
	return 7
end

---@param opponentIndex number
---@param playerIndex number
---@return string
function CustomCharacterGameTable:getCharacterKey(opponentIndex, playerIndex)
	return 'team' .. opponentIndex .. 'hero' .. playerIndex
end

---@param frame Frame
---@return Html
function CustomCharacterGameTable.results(frame)
	local args = Arguments.getArgs(frame)

	return CustomCharacterGameTable(args):readConfig():query():build()
end

return CustomCharacterGameTable
