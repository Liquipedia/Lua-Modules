---
-- @Liquipedia
-- page=Module:Widget/Match/Page/RoundsOverview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

---@class MatchPageRoundsOverviewProps
---@field rounds ValorantRoundData[]
---@field roundsPerHalf integer
---@field iconRender fun(side: string, winBy: string): Widget?
---@field opponent1 standardOpponent
---@field opponent2 standardOpponent

---@class MatchPageRoundsOverview: Widget
---@operator call(MatchPageRoundsOverviewProps): MatchPageRoundsOverview
---@field props MatchPageRoundsOverviewProps
local MatchPageRoundsOverview = Class.new(Widget)

---@return Widget?
function MatchPageRoundsOverview:render()
	if not self.props.rounds then
		return
	end
	assert(self.props.iconRender, 'MatchPageRoundsOverview: iconRender prop is required')
	assert(self.props.roundsPerHalf, 'MatchPageRoundsOverview: roundsPerHalf prop is required')
	local roundsPerHalf = self.props.roundsPerHalf
	local function makeIcon(round, side)
		if round.winningSide == side then
			return self.props.iconRender(side, round.winBy)
		end
		return '&nbsp;'
	end

	local numTeamContainers = math.ceil(#self.props.rounds / roundsPerHalf)

	local scoreForContainer = function(container, team)
		local start = (container - 1) * roundsPerHalf + 1
		local endIdx = math.min(container * roundsPerHalf, #self.props.rounds)

		return Array.reduce(
			Array.sub(self.props.rounds, start, endIdx),
			function(acc, round)
				if round.winningSide == round['t' .. team .. 'side'] then
					return acc + 1
				end
				return acc
			end,
			0
		)
	end

	local sideInContainer = function(container, team)
		local start = (container - 1) * roundsPerHalf + 1

		local round = self.props.rounds[start]
		if not round then return '' end
		return round['t' .. team .. 'side']
	end

	local teamContainers = Array.map(Array.range(1, numTeamContainers), function(container)
		return Div{
			classes = {'match-bm-rounds-overview-teams'},
			children = {
				Div{children = '&nbsp;'},
				Div{
					classes = {'match-bm-rounds-overview-teams-team'},
					children = {
						OpponentDisplay.InlineOpponent{opponent = self.props.opponent1, teamStyle = 'icon'},
						Div{
							classes = {
								'match-bm-rounds-overview-teams-score',
								'match-bm-rounds-overview-teams-score--'.. sideInContainer(container, 1)
							},
							children = scoreForContainer(container, 1)
						},
					}
				},
				Div{
					classes = {'match-bm-rounds-overview-teams-team'},
					children = {
						OpponentDisplay.InlineOpponent{opponent = self.props.opponent2, teamStyle = 'icon'},
						Div{
							classes = {
								'match-bm-rounds-overview-teams-score',
								'match-bm-rounds-overview-teams-score--'.. sideInContainer(container, 2)
							},
							children = scoreForContainer(container, 2)
						},
					}
				},
			},
		}
	end)

	return HtmlWidgets.Div{
		classes = {'match-bm-rounds-overview'},
		children = WidgetUtil.collect(
			Div{
				classes = {'match-bm-rounds-overview-teams-container'},
				children = teamContainers,
			},
			Div{
				classes = {'match-bm-rounds-overview-round-container'},
				children = Array.map(self.props.rounds, function(round)
					return Div{
						classes = {'match-bm-rounds-overview-round'},
						children = WidgetUtil.collect(
							Div{classes = {'match-bm-rounds-overview-round-title'}, children = round.round},
							Div{classes = {'match-bm-rounds-overview-round-outcome'}, children = makeIcon(round, round.t1side)},
							Div{classes = {'match-bm-rounds-overview-round-outcome'}, children = makeIcon(round, round.t2side)}
						)
					}
				end)
			}
		)
	}
end

return MatchPageRoundsOverview
