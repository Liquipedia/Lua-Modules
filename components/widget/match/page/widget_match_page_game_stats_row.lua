---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Game/Stats/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div, Fragment, Header = HtmlWidgets.Div, HtmlWidgets.Fragment, HtmlWidgets.Header
local MatchPageHeaderGameDraftCharacters = Lua.import('Module:Widget/Match/Page/Game/Draft/Characters')

---@class MatchPageHeaderGameStatsRow: Widget
---@operator call(table): MatchPageHeaderGameStatsRow
local MatchPageHeaderGameStatsRow = Class.new(Widget)

---@return Widget
function MatchPageHeaderGameStatsRow:render()
	return Div{
		classes = {'match-bm-team-stats-list-row'},
		children = {
			Div{classes = {'match-bm-team-stats-list-cell'}, children = {self.props.leftValue}},
			Div{classes = {'match-bm-team-stats-list-cell cell--middle', children = {self.props.icon, self.props.text}}},
			Div{classes = {'match-bm-team-stats-list-cell'}, children = {self.props.rightValue}},
		},
	}
end

return MatchPageHeaderGameStatsRow
