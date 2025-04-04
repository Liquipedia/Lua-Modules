---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:Widget/CharacterTable/Entry
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local CharacterIcon = Lua.import('Module:CharacterIcon')

local BaseEntry = Lua.import('Module:Widget/CharacterTable/Entry/Base')

local TYPE_BACKGROUND_CLASS = {
	assassin = 'vivid-violet-bg',
	fighter = 'cinnabar-bg',
	mage = 'sapphire-bg',
	marksman = 'bright-sun-bg',
	support = 'elm-bg',
	tank = 'forest-green-bg',
}

---@class LoLCharacterTableEntry: BaseCharacterTableEntry
---@operator call(table): LoLCharacterTableEntry
---@field lpdbProperties datapoint
---@field name string
---@field props { name: string, fontSize: string?, size: string? }
local LoLCharacterTableEntry = Class.new(BaseEntry)

---@return string?
function LoLCharacterTableEntry:getCharacterIcon()
	return CharacterIcon.Icon{
		character = self.name,
		size = self.props.size
	}
end

---@return string
function LoLCharacterTableEntry:getBackgroundClass()
	return TYPE_BACKGROUND_CLASS[self.lpdbProperties.information:lower()] or BaseEntry.DEFAULT_BACKGROUND_CLASS
end

return LoLCharacterTableEntry
