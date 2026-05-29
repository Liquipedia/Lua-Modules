---
-- @Liquipedia
-- page=Module:Widget/Match/Page/RoundsOverview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

---@class MatchPageRoundsOverviewProps
---@field rounds ValorantRoundData[]
---@field roundsPerHalf integer
---@field iconRender fun(side: string, winBy: string): Widget?
---@field opponent1 standardOpponent
---@field opponent2 standardOpponent


---@param props MatchPageRoundsOverviewProps
---@return VNode?
local function MatchPageRoundsOverview(props)
	if not props.rounds then
		return
	end
	assert(props.iconRender, 'MatchPageRoundsOverview: iconRender prop is required')
	local roundsPerHalf = props.roundsPerHalf
	assert(roundsPerHalf, 'MatchPageRoundsOverview: roundsPerHalf prop is required')
	local function makeIcon(round, side)
		if round.winningSide == side then
			return props.iconRender(side, round.winBy)
		end
		return '&nbsp;'
	end

	local numTeamContainers = math.ceil(#props.rounds / roundsPerHalf)

	local scoreForContainer = function(container, team)
		local start = (container - 1) * roundsPerHalf + 1
		local endIdx = math.min(container * roundsPerHalf, #props.rounds)

		return Array.reduce(
			Array.sub(props.rounds, start, endIdx),
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

		local round = props.rounds[start]
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
						OpponentDisplay.InlineOpponent{opponent = props.opponent1, teamStyle = 'icon'},
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
						OpponentDisplay.InlineOpponent{opponent = props.opponent2, teamStyle = 'icon'},
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

	return Div{
		classes = {'match-bm-rounds-overview'},
		children = WidgetUtil.collect(
			Div{
				classes = {'match-bm-rounds-overview-teams-container'},
				children = teamContainers,
			},
			Div{
				classes = {'match-bm-rounds-overview-round-container'},
				children = Array.map(props.rounds, function(round)
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

return Component.component(MatchPageRoundsOverview)
