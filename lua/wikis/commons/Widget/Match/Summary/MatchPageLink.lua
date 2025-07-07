---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/MatchPageLink
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local MatchSummaryRow = Lua.import('Module:Widget/Match/Summary/Row')
local MatchPageButton = Lua.import('Module:Widget/Match/PageButton')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Center = HtmlWidgets.Center

---@class MatchSummaryMatchPageLink: Widget
---@operator call(table): MatchSummaryMatchPageLink
local MatchSummaryMatchPageLink = Class.new(Widget)

---@return Widget?
function MatchSummaryMatchPageLink:render()
	if not self.props.matchId then
		return
	end

	return MatchSummaryRow{children = Center{
		css = {display = 'block'},
		children = {
			MatchPageButton{
				matchId = self.props.matchId,
				hasMatchPage = self.props.hasMatchPage,
				short = false,
				buttonType = 'primary',
			},
		}
	}}
end

return MatchSummaryMatchPageLink
