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
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
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
	local function createItem(icon, iconColor, title, score)
		return HtmlWidgets.Li{
			classes = 'panel-content__points-distribution__list-item',
			children = {
				HtmlWidgets.Span{
					classes = {'panel-content__points-distribution__icon', iconColor},
					children = IconWidget{
						iconName = icon,
					},
				},
				HtmlWidgets.Span{
					classes = 'panel-content__points-distribution__title',
					children = title,
				},
				HtmlWidgets.Span{
					children = score .. ' ' .. 'point' .. (score ~= 1 and 's' or ''),
				},
			}
		}
	end

	return ContentItemContainer{collapsed = true, collapsible = true, title = 'Points Distribution', children = {
		HtmlWidgets.Ul{
			classes = 'panel-content__points-distribution',
			children = WidgetUtil.collect(
				createItem('fas fa-skull', nil, '1 kill', self.props.killScore),
				Array.map(self.props.placementScore, function(slot)
					local title = RankRange{start = slot.rankStart, rankEnd = slot.rangeEnd}
					local icon, iconColor = Trophy{place = slot.rangeStart}

					return createItem(icon, iconColor, title, slot.score)
				end)
			)
		},
	}}
end

return MatchSummaryFfaPointsDistribution
