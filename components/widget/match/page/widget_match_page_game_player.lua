---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Game/Player
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local MatchPageHeaderGamePlayerStat = Lua.import('Module:Widget/Match/Page/Game/Player/Stat')
local MatchPageHeaderGamePlayerItem = Lua.import('Module:Widget/Match/Page/Game/Player/Item')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class MatchPageHeaderGamePlayer: Widget
---@operator call(table): MatchPageHeaderGamePlayer
local MatchPageHeaderGamePlayer = Class.new(Widget)

---@return Widget
function MatchPageHeaderGamePlayer:render()
	return Div{
		classes = {'match-bm-players-player'},
		children = {
			Div{
				classes = {'match-bm-players-player-character'},
				children = {
					Div{
						classes = {'match-bm-players-player-avatar'},
						children = {
							Div{classes = {'match-bm-players-player-icon'}, children = self.props.heroIcon},
							Div{classes = {'match-bm-players-player-role', 'role--' .. self.props.teams[1].side}, children = {'[[File:Dota2 {{facet}} facet icon darkmode.png|link=|{{facet}}]]'}},
						},
					},
					Div{classes = {'match-bm-players-player-name'}, children = {
						Link{link = self.props.link, children = self.props.displayName},
						'<i>' .. self.props.character .. '</i>',
					}},
				},
			},
			Div{
				classes = {'match-bm-players-player-loadout'},
				children = {
					Div{
						classes = {'match-bm-players-player-loadout-items'},
						children = {
							Div{classes = {'match-bm-players-player-loadout-item'}, children = Array.map(self.props.items, MatchPageHeaderGamePlayerItem)},
							Div{classes = {'match-bm-players-player-loadout-item item--backpack'}, children = Array.map(self.props.backpackitems, MatchPageHeaderGamePlayerItem)},
						},
					},
					Div{
						classes = {'match-bm-players-player-loadout-rs-wrap'},
						children = {
							Div{classes = {'match-bm-players-player-loadout-rs'}, children = MatchPageHeaderGamePlayerItem(self.props.neutralitem)},
							Div{classes = {'match-bm-players-player-loadout-rs'}, children = self.props.shard and MatchPageHeaderGamePlayerItem{name = 'Aghanim\'s Shard', image = 'Dota2_Aghanim\'s_Shard_symbol_allmode.png'}},
							Div{classes = {'match-bm-players-player-loadout-rs'}, children = self.props.scepter and MatchPageHeaderGamePlayerItem{name = 'Aghanim\'s Scepter', image = 'Dota2_Aghanim\'s_Scepter_symbol_allmode.png'}},
						},
					},
				},
			},
			Div{
				classes = {'match-bm-players-player-stats'},
				children = {
					MatchPageHeaderGamePlayerStat{
						icon = '<i class="fas fa-skull-crossbones"></i>',
						title = 'KDA',
						children = self.props.kills .. '<span class="slash">/</span>' .. self.props.deaths .. '<span class="slash">/</span>' .. self.props.assists
					},
					MatchPageHeaderGamePlayerStat{
						icon = '<i class="fas fa-sword"></i>',
						title = 'DMG',
						children = self.props.displayDamageDone
					},
					MatchPageHeaderGamePlayerStat{
						icon = '<i class="fas fa-swords"></i>',
						title = 'LH/DN',
						children = self.props.lasthits .. '<span class="slash">/</span>' .. self.props.denies
					},
					MatchPageHeaderGamePlayerStat{
						icon = '<i class="fas fa-coin"></i>',
						title = 'NET',
						children = self.props.displayGold
					},
					MatchPageHeaderGamePlayerStat{
						icon = '<i class="fas fa-coins"></i>',
						title = 'GPM',
						children = self.props.gpm
					},
				}
			}
		}
	}
end

return MatchPageHeaderGamePlayer
