---
-- @Liquipedia
-- page=Module:Player/Display/SmashLike
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Characters = Lua.import('Module:Characters')
local Table = Lua.import('Module:Table')

local BlockPlayerWidget = Lua.import('Module:Widget/PlayerDisplay/Block/SmashLike')
local InlinePlayerWidget = Lua.import('Module:Widget/PlayerDisplay/Inline/SmashLike')
local PlayerDisplay = Lua.import('Module:Player/Display')

---@class SmashLikePlayerDisplay: PlayerDisplay
local CustomPlayerDisplay = Table.copy(PlayerDisplay)

---@param props SmashLikeBlockPlayerProps
---@return Widget
function CustomPlayerDisplay.BlockPlayer(props)
	return BlockPlayerWidget(props)
end

---@param props SmashLikeInlinePlayerProps
---@return Widget
function CustomPlayerDisplay.InlinePlayer(props)
	return InlinePlayerWidget(props)
end

function CustomPlayerDisplay.character(game, character)
	return Characters.GetIconAndName{character, game = game}
end

return CustomPlayerDisplay
