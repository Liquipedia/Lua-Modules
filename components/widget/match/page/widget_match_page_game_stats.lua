---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Game/Stats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

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
							children = {
								MatchPageHeaderGameStatsRow{
									leftValue = team1.kills .. '<span class="slash">/</span>' .. team1.deaths .. '<span class="slash">/</span>' .. team1.assists,
									icon = '<i class="fas fa-skull-crossbones"></i>',
									text = 'KDA',
									rightValue = team2.kills .. '<span class="slash">/</span>' .. team2.deaths .. '<span class="slash">/</span>' .. team2.assists
								},
								MatchPageHeaderGameStatsRow{
									leftValue = team1.gold,
									icon = '<i class="fas fa-coins"></i>',
									text = 'Gold',
									rightValue = team2.gold
								},
								MatchPageHeaderGameStatsRow{
									leftValue = team1.towers,
									icon = '<i class="fas fa-chess-rook"></i>',
									text = 'Towers',
									rightValue = team2.towers
								},
								MatchPageHeaderGameStatsRow{
									leftValue = team1.barracks,
									icon = '<i class="fas fa-warehouse"></i>',
									text = 'Barracks',
									rightValue = team2.barracks
								},
								MatchPageHeaderGameStatsRow{
									leftValue = team1.roshans,
									icon = '<i class="liquipedia-custom-icon liquipedia-custom-icon-roshan"></i>',
									text = 'Roshan',
									rightValue = team2.roshans
								},
							}
						},
						Div{
							classes = {'match-bm-team-stats-team'},
							children = {
								Div{classes = {'match-bm-team-stats-team-logo'}, children = team2.icon},
								Div{classes = {'match-bm-team-stats-team-side'}, children = team2.side},
								Div{classes = {'match-bm-team-stats-team-state', 'state--'.. team2.scoreDisplay}, children = team2.scoreDisplay},
							},
						},
					}
				}
			}
		}
	}}
end

return MatchPageHeaderGameStats
