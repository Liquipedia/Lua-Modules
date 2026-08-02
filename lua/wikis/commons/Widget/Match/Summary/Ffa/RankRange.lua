---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/RankRange
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Ordinal = Lua.import('Module:Ordinal')

local Component = Lua.import('Module:Widget/Component')

---@param props {rankStart: integer?, rankEnd: integer?}
---@return string[]
local function MatchSummaryFfaRankRange(props)
	local placementStart, placementEnd = props.rankStart, props.rankEnd
	local places = {}

	if placementStart then
		table.insert(places, Ordinal.toOrdinal(placementStart))
	end

	if placementStart and placementEnd and placementEnd > placementStart then
		table.insert(places, Ordinal.toOrdinal(placementEnd))
	end

	return Array.interleave(places, ' - ')
end

return Component.component(MatchSummaryFfaRankRange)
