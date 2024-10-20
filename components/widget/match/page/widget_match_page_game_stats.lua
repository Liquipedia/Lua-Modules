---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Game/Stats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div, Fragment, Header = HtmlWidgets.Div, HtmlWidgets.Fragment, HtmlWidgets.Header
local MatchPageHeaderGameStatsRow = Lua.import('Module:Widget/Match/Page/Game/Stats/Row')

---@class MatchPageHeaderGameStats: Widget
---@operator call(table): MatchPageHeaderGameStats
local MatchPageHeaderGameStats = Class.new(Widget)

---@return Widget
function MatchPageHeaderGameStats:render()
	local team1, team2 = self.props.opponents[1], self.props.opponents[2]
	return Fragment{children = {
		Header{level = 3, children = 'Team Stats'},
		Div{
			classes = {'match-bm-team-stats'},
			children = {
				Div{
					classes = {'match-bm-team-stats-header'},
					children = {
						Header{
							level = 4,
							classes = {'match-bm-team-stats-header-title'},
							children = self.props.winner and self.props.winner or 'No winner determined yet'
						},
						self.props.length and Div{children = self.props.length} or nil,
					},
				},
				Div{
					classes = {'match-bm-team-stats-container'},
					children = {
						Div{
							classes = {'match-bm-team-stats-team'},
							children = {
								Div{classes = {'match-bm-team-stats-team-logo'}, children = team1.icon},
								Div{classes = {'match-bm-team-stats-team-side'}, children = team1.side},
								Div{classes = {'match-bm-team-stats-team-state', 'state--'.. team1.score}, children = team1.score},
							},
						},
						Div{
							classes = {'match-bm-team-stats-list'},
							children = Array.map(self.props.children, function(stat)
								MatchPageHeaderGameStatsRow{
									leftValue = stat.render(team1),
									icon = stat.icon,
									text = stat.text,
									rightValue = stat.render(team2),
								}
							end),
						},
						Div{
							classes = {'match-bm-team-stats-team'},
							children = {
								Div{classes = {'match-bm-team-stats-team-logo'}, children = team2.icon},
								Div{classes = {'match-bm-team-stats-team-side'}, children = team2.side},
								Div{classes = {'match-bm-team-stats-team-state', 'state--'.. team2.score}, children = team2.score},
							},
						},
					}
				}
			}
		}
	}}
end

return MatchPageHeaderGameStats
