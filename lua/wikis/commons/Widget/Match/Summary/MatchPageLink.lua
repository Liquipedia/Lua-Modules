---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/MatchPageLink
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local MatchSummaryRow = Lua.import('Module:Widget/Match/Summary/Row')
local MatchPageButton = Lua.import('Module:Widget/Match/PageButton')

---@class MatchSummaryMatchPageLink: Widget
---@operator call(table): MatchSummaryMatchPageLink
local MatchSummaryMatchPageLink = Class.new(Widget)

---@return Widget?
function MatchSummaryMatchPageLink:render()
	if not self.props.matchId then
		return
	end

	return MatchSummaryRow{
		children = {
			MatchPageButton{
				matchId = self.props.matchId,
				hasMatchPage = self.props.hasMatchPage,
			},
		}
	}
end

return MatchSummaryMatchPageLink
