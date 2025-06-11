---
-- @Liquipedia
-- page=Module:GameTable/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local GameTableCharacter = Lua.import('Module:GameTable/Character')

local CustomGameTableCharacter = Class.new(GameTableCharacter)

---@return integer
function CustomGameTableCharacter:getNumberOfBans()
	return 1
end

---@param opponentIndex number
---@param playerIndex number
---@return string
function CustomGameTableCharacter:getCharacterKey(opponentIndex, playerIndex)
	return 'team' .. opponentIndex .. 'hero' .. playerIndex
end

---@param frame Frame
---@return Html
function CustomGameTableCharacter.results(frame)
	local args = Arguments.getArgs(frame)

	return CustomGameTableCharacter(args):readConfig():query():build()
end

return CustomGameTableCharacter
