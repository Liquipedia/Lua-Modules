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
		css = {
			display = 'flex',
			gap = '0.25rem',
			['line-height'] = '2rem',
		},
		children = WidgetUtil.collect(
			Div{
				classes = {'match-bm-rounds-overview-teams'},
				children = {Div{children = '&nbsp;'}, Div{children = 'T1'}, Div{children = 'T2'}}
			},
			Array.map(self.props.rounds, function(round)
				return Div{
					classes = {'match-bm-rounds-overview-round'},
					children = WidgetUtil.collect(
						Div{classes = {'match-bm-rounds-overview-round-title'}, css = {['text-align'] = 'center'}, children = round.round},
						Div{classes = {'match-bm-rounds-overview-round-outcome'}, children = makeIcon(round, round.t1side)},
						Div{classes = {'match-bm-rounds-overview-round-outcome'}, children = makeIcon(round, round.t2side)}
					)
				}
			end)
		)
	}

end

return MatchPageRoundsOverview
