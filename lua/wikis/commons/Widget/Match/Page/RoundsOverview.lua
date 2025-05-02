---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/RoundsOverview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchPageRoundsOverview: Widget
---@operator call(table): MatchPageRoundsOverview
local MatchPageRoundsOverview = Class.new(Widget)

---@return Widget?
function MatchPageRoundsOverview:render()
	if not self.props.rounds then
		return
	end
	assert(self.props.iconRender, 'MatchPageRoundsOverview: iconRender prop is required')
	return HtmlWidgets.Fragment{
		classes = {'match-bm-rounds-overview'},
		children = {
			Div{
				classes = {'match-bm-rounds-overview-teams'},
				children = {'', 'team1', 'team2'}
			},
			Div{
				children = Array.map(self.props.rounds, function(round)
					return Div{
						classes = {'match-bm-rounds-overview-round'},
						children = WidgetUtil.collect(
							round.round,
							round.winningSide == round.team1side and self.props.iconRender(round.winningSide, round.winBy) or '',
							round.winningSide == round.team2side and self.props.iconRender(round.winningSide, round.winBy) or ''
						)
					}
				end)
			}
		}
	}

end

return MatchPageRoundsOverview
