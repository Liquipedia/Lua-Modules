---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/PointsDistribution
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
local Trophy = Lua.import('Module:Widget/Match/Summary/Ffa/Trophy')
local RankRange = Lua.import('Module:Widget/Match/Summary/Ffa/RankRange')

---@class MatchSummaryFfaPointsDistribution: Widget
---@operator call(table): MatchSummaryFfaPointsDistribution
local MatchSummaryFfaPointsDistribution = Class.new(Widget)

---@return Widget
function MatchSummaryFfaPointsDistribution:render()
	assert(self.props.killScore, 'No killscore provided')
	assert(self.props.placementScore, 'No placement score table provided')
	local function createItem(icon, title, score)
		return {icon = icon, title = title, content = score .. ' ' .. 'point' .. (score ~= 1 and 's' or '')}
	end

	return ContentItemContainer{collapsed = true, collapsible = true, title = 'Points Distribution',
		contentClass = 'panel-content__points-distribution',
		items = {
			createItem(IconWidget{iconName = 'kills'}, '1 kill', self.props.killScore),
			unpack(Array.map(self.props.placementScore, function(slot)
				local title = RankRange{rankStart = slot.rangeStart, rankEnd = slot.rangeEnd}
				local icon = Trophy{place = slot.rangeStart}

				return createItem(icon, title, slot.score)
			end))
		}
	}
end

return MatchSummaryFfaPointsDistribution
