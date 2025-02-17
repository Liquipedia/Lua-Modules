---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/RankRange
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Ordinal = require('Module:Ordinal')

local Widget = Lua.import('Module:Widget')

---@class MatchSummaryFfaRankRange: Widget
---@operator call(table): MatchSummaryFfaRankRange
local MatchSummaryFfaRankRange = Class.new(Widget)

---@return string
function MatchSummaryFfaRankRange:render()
	local placementStart, placementEnd = self.props.rankStart, self.props.rankEnd
	local places = {}

	if placementStart then
		table.insert(places, Ordinal.toOrdinal(placementStart))
	end

	if placementStart and placementEnd and placementEnd > placementStart then
		table.insert(places, Ordinal.toOrdinal(placementEnd))
	end

	return table.concat(places, ' - ')
end

return MatchSummaryFfaRankRange
