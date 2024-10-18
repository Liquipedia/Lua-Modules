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
MatchSummaryCharacters.defaultProps = {
	flipped = false,
}

---@return Widget[]?
function MatchSummaryCharacters:render()
	if not self.props.characters then
		return nil
	end
	local flipped = self.props.flipped

	return Div{
		classes = {
			'brkts-popup-body-element-thumbs',
			'brkts-champion-icon',
			flipped and 'brkts-popup-body-element-thumbs-right' or nil,
		},
		children = Array.map(self.props.characters, function(character)
			return Character{
				character = character,
				date = self.props.date,
				bg = self.props.bg,
				showName = #self.props.characters == 1,
				flipped = flipped,
			}
		end)
	}
end

return MatchSummaryCharacters
