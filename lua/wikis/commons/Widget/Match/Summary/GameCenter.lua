---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/GameCenter
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class MatchSummaryGameCenter: Widget
---@operator call(table): MatchSummaryGameCenter
local MatchSummaryGameCenter = Class.new(Widget)

---@return Widget?
function MatchSummaryGameCenter:render()
	return HtmlWidgets.Div{
		classes = {'brkts-popup-spaced'},
		css = self.props.css,
		children = self.props.children,
	}
end

return MatchSummaryGameCenter
