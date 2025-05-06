---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/RoundsOverview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

---@class MatchPageRoundsOverview: Widget
---@operator call(table): MatchPageRoundsOverview
local MatchPageRoundsOverview = Class.new(Widget)

---@return Widget?
function MatchPageRoundsOverview:render()
	if not self.props.rounds then
		return
	end
	assert(self.props.iconRender, 'MatchPageRoundsOverview: iconRender prop is required')
	local function makeIcon(round, side)
		if round.winningSide == side then
			return self.props.iconRender(side, round.winBy)
		end
		return '&nbsp;'
	end

	return HtmlWidgets.Div{
		classes = {'match-bm-rounds-overview'},
		children = WidgetUtil.collect(
			Div{
				classes = {'match-bm-rounds-overview-teams'},
				children = {
					Div{children = '&nbsp;'},
					Div{children = OpponentDisplay.InlineOpponent{opponent = self.props.opponent1, teamStyle = 'standard'}},
					Div{children = OpponentDisplay.InlineOpponent{opponent = self.props.opponent2, teamStyle = 'standard'}},
				},
			},
			Array.map(self.props.rounds, function(round)
				return Div{
					classes = {'match-bm-rounds-overview-round'},
					children = WidgetUtil.collect(
						Div{classes = {'match-bm-rounds-overview-round-title'}, children = round.round},
						Div{classes = {'match-bm-rounds-overview-round-outcome'}, children = makeIcon(round, round.t1side)},
						Div{classes = {'match-bm-rounds-overview-round-outcome'}, children = makeIcon(round, round.t2side)}
					)
				}
			end)
		)
	}

end

return MatchPageRoundsOverview
