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

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Entry = Lua.import('Module:Widget/CharacterTable/Entry')

---@class CharacterTable:Widget
---@operator call(table): GridContainer
---@field props {alias: string?}
local CharacterTable = Class.new(Widget)

---@return Widget
function CharacterTable:render()
	local query = Array.map(mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::character]]',
		query = 'name',
		order = 'name asc',
		limit = 1000,
	}), Operator.property('name'))
	mw.logObject(query)
	return Div{
		css = {
			['text-align'] = 'center'
		},
		children = Array.map(query, function (characterName)
			return Entry{name = characterName, alias = self.props.alias}
		end)
	}
end

return CharacterTable
