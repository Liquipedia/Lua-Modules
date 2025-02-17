---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Body
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchSummaryBody: Widget
---@operator call(table): MatchSummaryBody
local MatchSummaryBody = Class.new(Widget)
MatchSummaryBody.defaultProps = {
	classes = {},
}

---@return Widget
function MatchSummaryBody:render()
	return Div{
		classes = {'brkts-popup-body', unpack(self.props.classes)},
		children = self.props.children,
	}
end

return MatchSummaryBody
