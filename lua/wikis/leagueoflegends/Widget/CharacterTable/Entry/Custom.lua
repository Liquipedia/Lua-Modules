---
-- @Liquipedia
-- page=Module:Widget/CharacterTable/Entry/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local BaseEntry = Lua.import('Module:Widget/CharacterTable/Entry')

local TYPE_BACKGROUND_CLASS = {
	assassin = 'vivid-violet-bg',
	fighter = 'cinnabar-bg',
	mage = 'sapphire-bg',
	marksman = 'bright-sun-bg',
	support = 'elm-bg',
	tank = 'forest-green-bg',
}

---@class LoLCharacterTableEntry: CharacterTableEntry
---@operator call(table): LoLCharacterTableEntry
local LoLCharacterTableEntry = Class.new(BaseEntry)

---@return string
function LoLCharacterTableEntry:getBackgroundClass()
	return TYPE_BACKGROUND_CLASS[(self.character.roles[1] or ''):lower()] or BaseEntry.DEFAULT_BACKGROUND_CLASS
end

return LoLCharacterTableEntry
