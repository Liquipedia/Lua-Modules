---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/GameTeamWrapper
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class MatchSummaryMatchGameTeamWrapper: Widget
---@operator call(table): MatchSummaryMatchGameTeamWrapper
local MatchSummaryMatchGameTeamWrapper = Class.new(Widget)
MatchSummaryMatchGameTeamWrapper.defaultProps = {
	flipped = false,
}

---@return Widget?
function MatchSummaryMatchGameTeamWrapper:render()
	return HtmlWidgets.Div{
		classes = {'brkts-popup-spaced'},
		children = self.props.flipped and Array.reverse(self.props.children) or self.props.children
	}
end

return MatchSummaryMatchGameTeamWrapper
