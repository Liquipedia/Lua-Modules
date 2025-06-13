---
-- @Liquipedia
-- page=Module:Widget/CharacterTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')

local Character = Lua.import('Module:Character')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Entry = Lua.import('Module:Widget/CharacterTable/Entry/Custom')

---@class CharacterTable: Widget
---@operator call(table): CharacterTable
---@field props {alias: string?, extraConditions: string?}
local CharacterTable = Class.new(Widget)

---@return Widget
function CharacterTable:render()
	local extraConditions = self.props.extraConditions
	local characters = Character.getAllCharacters{extraConditions}
	Array.sortInPlaceBy(characters, Operator.property('name'))
	return Div{
		css = {
			['text-align'] = 'center'
		},
		children = Array.interleave(Array.map(characters, function (character)
			return Entry(character)
		end), '\n')
	}
end

return CharacterTable
