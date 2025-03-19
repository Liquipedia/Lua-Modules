---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/CharacterTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Entry = Lua.import('Module:Widget/CharacterTable/Entry')

---@class CharacterTable: Widget
---@operator call(table): CharacterTable
---@field props {alias: string?, extraConditions: string?}
local CharacterTable = Class.new(Widget)

---@return Widget
function CharacterTable:render()
	local conditions = '[[type::character]]'
	local extraConditions = self.props.extraConditions
	if String.isNotEmpty(extraConditions) then
		conditions = conditions .. ' AND (' .. extraConditions .. ')'
	end
	local characterNames = Array.map(mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = conditions,
		query = 'name',
		order = 'name asc',
		limit = 1000,
	}), Operator.property('name'))
	return Div{
		css = {
			['text-align'] = 'center'
		},
		children = Array.interleave(Array.map(characterNames, function (characterName)
			return Entry{name = characterName, alias = self.props.alias}
		end), '\n')
	}
end

return CharacterTable
