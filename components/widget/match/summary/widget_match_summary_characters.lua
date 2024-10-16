---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Characters
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Character = Lua.import('Module:Widget/Match/Summary/Character')

---@class MatchSummaryCharacters: Widget
---@operator call(table): MatchSummaryCharacters
local MatchSummaryCharacters = Class.new(Widget)

---@return Widget[]?
function MatchSummaryCharacters:render()
	local flipped = self.props.flipped

	local characters = Array.map(self.props.characters, function(character)
		return Character{
			character = character,
			date = self.props.date,
			bg = self.props.bg,
			showName = #self.props.characters == 1,
			flipped = flipped,
		}
	end)
	return Div{
		classes = {
			'brkts-popup-body-element-thumbs',
			'brkts-popup-body-element-thumbs-' .. (flipped and 'right' or 'left'),
			'brkts-champion-icon'
		},
		children = flipped and Array.reverse(characters) or characters
	}
end

return MatchSummaryCharacters
