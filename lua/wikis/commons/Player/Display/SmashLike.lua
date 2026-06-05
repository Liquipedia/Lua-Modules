---
-- @Liquipedia
-- page=Module:Player/Display/Character
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Characters = Lua.import('Module:Characters')
local Table = Lua.import('Module:Table')

local BlockPlayerWidget = Lua.import('Module:Widget/PlayerDisplay/Block/Character')
local InlinePlayerWidget = Lua.import('Module:Widget/PlayerDisplay/Inline/Character')
local PlayerDisplay = Lua.import('Module:Player/Display')

---@class CharacterPlayerDisplay: PlayerDisplay
local CustomPlayerDisplay = Table.copy(PlayerDisplay)

---@param props BlockCharacterPlayerDisplayProps
---@return Widget
function CustomPlayerDisplay.BlockPlayer(props)
	return BlockPlayerWidget(props)
end

---@param props InlineCharacterPlayerDisplayProps
---@return VNode
function CustomPlayerDisplay.InlinePlayer(props)
	return InlinePlayerWidget(props)
end

function CustomPlayerDisplay.character(game, character)
	return Characters.GetIconAndName{character, game = game}
end

return CustomPlayerDisplay
