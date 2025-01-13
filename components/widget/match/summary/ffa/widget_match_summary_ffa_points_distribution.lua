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
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
local Trophy = Lua.import('Module:Widget/Match/Summary/Ffa/Trophy')
local RankRange = Lua.import('Module:Widget/Match/Summary/Ffa/RankRange')

---@class MatchSummaryFfaPointsDistribution: Widget
---@operator call(table): MatchSummaryFfaPointsDistribution
local MatchSummaryFfaPointsDistribution = Class.new(Widget)

---@return Widget
function MatchSummaryFfaPointsDistribution:render()
	assert(self.props.scores, 'No scores provided')

	local hasKillPoints = Array.any(self.props.scores, function(slot)
		return slot.killScore ~= nil
	end)

	local function createItem(icon, title, placementPoints, killPoints)
		local function suffixPoints(score)
			return score .. ' ' .. 'point' .. (score ~= 1 and 's' or '')
		end
		local contentDisplay = {
			HtmlWidgets.Span{children = suffixPoints(placementPoints)},
			hasKillPoints and HtmlWidgets.Span{children = suffixPoints(killPoints)} or nil,
		}
		return {icon = icon, title = title, content =  contentDisplay}
	end

	local header = {title = 'Placement', content = {
		HtmlWidgets.Span{children = HtmlWidgets.B{children = 'Placement Points'}},
		hasKillPoints and HtmlWidgets.Span{children = HtmlWidgets.B{children = 'Points per Kill'}} or nil,
	}}

	local placementItems = Array.map(self.props.scores, function(slot)
		local title = RankRange{rankStart = slot.rangeStart, rankEnd = slot.rangeEnd}
		local icon = Trophy{place = slot.rangeStart}

		return createItem(icon, title, slot.placementScore, slot.killScore)
	end)

	table.insert(placementItems, 1, header)

	return ContentItemContainer{collapsed = true, collapsible = true, title = 'Points Distribution',
		contentClass = 'panel-content__points-distribution',
		items = placementItems
	}
end

return MatchSummaryFfaPointsDistribution
