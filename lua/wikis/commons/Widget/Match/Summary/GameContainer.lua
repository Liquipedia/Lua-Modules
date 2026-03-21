---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/GameContainer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class MatchSummaryGameContainer: Widget
---@operator call(table): MatchSummaryGameContainer
local MatchSummaryGameContainer = Class.new(Widget)

---@return Widget?
function MatchSummaryGameContainer:render()
	if Logic.isEmpty(self.props.children) then
		return
	end
	return HtmlWidgets.Div{
		attributes = Logic.isNotEmpty(self.props.gridLayout) and {['data-grid-layout'] = self.props.gridLayout} or nil,
		classes = {'brkts-popup-body-grid'},
		css = self.props.css,
		children = self.props.children,
	}
end

return MatchSummaryGameContainer
