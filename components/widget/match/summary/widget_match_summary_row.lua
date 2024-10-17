---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchSummaryRow: Widget
---@operator call(table): MatchSummaryRow
local MatchSummaryRow = Class.new(Widget)
MatchSummaryRow.defaultProps = {
	classes = {},
}

---@return Widget
function MatchSummaryRow:render()
	return Div{
		classes = {'brkts-popup-body-element', unpack(self.props.classes)},
		css = self.props.css,
		children = self.props.children,
	}
end

return MatchSummaryRow
