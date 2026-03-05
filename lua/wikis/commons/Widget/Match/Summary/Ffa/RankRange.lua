---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/RankRange
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Ordinal = Lua.import('Module:Ordinal')

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
