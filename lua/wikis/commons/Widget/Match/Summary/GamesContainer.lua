---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/GamesContainer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class MatchSummaryGamesContainer: Widget
---@operator call(table): MatchSummaryGamesContainer
local MatchSummaryGamesContainer = Class.new(Widget)

---@return Widget?
function MatchSummaryGamesContainer:render()
	if Logic.isEmpty(self.props.children) then
		return
	end
	return HtmlWidgets.Div{
		classes = {'brkts-popup-body-grid'},
		css = self.props.css,
		children = self.props.children,
	}
end

return MatchSummaryGamesContainer
