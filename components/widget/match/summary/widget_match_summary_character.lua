---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Character
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchSummaryCharacter: Widget
---@operator call(table): MatchSummaryCharacter
local MatchSummaryCharacter = Class.new(Widget)

MatchSummaryCharacter.defaultProps = {
	showName = false,
	flipped = false,
}

---@return Widget[]?
function MatchSummaryCharacter:render()
	local characterIcon = CharacterIcon.Icon{
		character = self.props.character,
		date = self.props.date,
		size = self.props.size
	}
	local children = { characterIcon }
	if self.props.showName then
		children = {characterIcon, ' ', self.props.character}
	end

	return Div{
		classes = {self.props.bg},
		children = self.props.flipped and Array.reverse(children) or children
	}
end

return MatchSummaryCharacter
