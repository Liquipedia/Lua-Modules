---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Game/Players
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

---@class MatchPageHeaderGamePlayers: Widget
---@operator call(table): MatchPageHeaderGamePlayers
local MatchPageHeaderGamePlayers = Class.new(Widget)

---@return Widget
function MatchPageHeaderGamePlayers:render()
	local team1, team2 = self.props.teams[1], self.props.teams[2]
	return Fragment{children = {
		Header{level = 3, children = 'Player Performance'},
		Div{
			classes = {'match-bm-players-wrapper'},
			children = {
				Div{
					classes = {'match-bm-players-team'},
					children = {
						Div{
							classes = {'match-bm-lol-players-team-header'},
							children = {team1.icon, Array.map(team1.players, function(player)
								return Div{
									classes = {'match-bm-lol-players-team-player'},
									children = {
										player.icon,
										Div{classes = {'match-bm-lol-players-team-player-name'}, children = player.name},
									}
								}
							end)}
						},
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
								Div{classes = {'match-bm-team-stats-team-state', 'state--'.. team1.scoreDisplay}, children = team1.scoreDisplay},
							},
						},
						Div{
							classes = {'match-bm-team-stats-list'},
							children = {
								MatchPageHeaderGameStatsRow{
									leftValue = team1.kills .. '<span class="slash">/</span>' .. team1.deaths .. '<span class="slash">/</span>' .. team1.assists,
									icon = '<i class="fas fa-skull-crossbones cell--icon"></i>',
									text = 'KDA',
									rightValue = team2.kills .. '<span class="slash">/</span>' .. team2.deaths .. '<span class="slash">/</span>' .. team2.assists
								},
								MatchPageHeaderGameStatsRow{
									leftValue = team1.gold,
									icon = '<i class="fas fa-coins cell--icon"></i>',
									text = 'Gold',
									rightValue = team2.gold
								},
								MatchPageHeaderGameStatsRow{
									leftValue = team1.objectives.towers,
									icon = '<i class="fas fa-chess-rook cell--icon"></i>',
									text = 'Towers',
									rightValue = team2.objectives.towers
								},
								MatchPageHeaderGameStatsRow{
									leftValue = team1.objectives.barracks,
									icon = '<i class="fas fa-warehouse cell--icon"></i>',
									text = 'Barracks',
									rightValue = team2.objectives.barracks
								},
								MatchPageHeaderGameStatsRow{
									leftValue = team1.objectives.roshans,
									icon = '<span class="liquipedia-custom-icon liquipedia-custom-icon-roshan"></span>',
									text = 'Roshan',
									rightValue = team2.objectives.roshans
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

return MatchPageHeaderGamePlayers
