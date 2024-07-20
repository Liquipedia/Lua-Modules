---
-- @Liquipedia
-- wiki=dota2
-- page=Module:GameTable/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local GameTableCharacter = Lua.import('Module:GameTable/Character')

local NONBREAKING_SPACE = '&nbsp;'

local CustomGameTableCharacter = Class.new(GameTableCharacter)

---@return integer
function CustomGameTableCharacter:getNumberOfBans()
	return 7
end

---@param opponentIndex number
---@param playerIndex number
---@return string
function CustomGameTableCharacter:getCharacterKey(opponentIndex, playerIndex)
	return 'team' .. opponentIndex .. 'hero' .. playerIndex
end

---@param game CharacterGameTableGame
---@param opponentIndex number
---@param key string
---@return Html
function CustomGameTableCharacter:_displayCharacters(game, opponentIndex, key)
	local makeIcon = function(character)
		return CharacterIcon.Icon{character = character, size = self.iconSize, date = game.date}
	end

	local icons = Array.map(game[key][opponentIndex] or {}, makeIcon)

	return mw.html.create('td')
		:node(#icons > 0 and table.concat(icons, NONBREAKING_SPACE) or nil)
end

---@param frame Frame
---@return Html
function CustomGameTableCharacter.results(frame)
	local args = Arguments.getArgs(frame)

	return CustomGameTableCharacter(args):readConfig():query():build()
end

return CustomGameTableCharacter
