---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/GameCenter
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchSummaryBreak = Lua.import('Module:Widget/Match/Summary/Break')

---@class MatchSummaryGameCenter: Widget
---@operator call(table): MatchSummaryGameCenter
local MatchSummaryGameCenter = Class.new(Widget)

---@return Widget?
function MatchSummaryGameCenter:render()
	return HtmlWidgets.Div{
		classes = {'brkts-popup-body-element-vertical-centered'},
		children = self.props.children,
	}
end

return MatchSummaryGameCenter
