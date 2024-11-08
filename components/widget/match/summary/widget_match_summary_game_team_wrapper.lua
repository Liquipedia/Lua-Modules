---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/GameTeamWrapper
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

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
		css = {flex = 1, ['justify-content'] = 'unset', ['flex-direction'] = self.props.flipped and 'row-reverse' or 'row'},
		children = self.props.children
	}
end

return MatchSummaryMatchGameTeamWrapper
