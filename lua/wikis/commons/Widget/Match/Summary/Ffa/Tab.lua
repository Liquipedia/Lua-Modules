---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/Tab
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class MatchSummaryFfaTab: Widget
---@operator call(table): MatchSummaryFfaTab
local MatchSummaryFfaTab = Class.new(Widget)

---@return Widget
function MatchSummaryFfaTab:render()
	return HtmlWidgets.Div{
		classes = {'panel-content'},
		attributes = {
			['data-js-battle-royale'] = 'panel-content',
			id = self.props.matchId .. 'panel' .. self.props.idx,
		},
		children = self.props.children,
	}
end

return MatchSummaryFfaTab
