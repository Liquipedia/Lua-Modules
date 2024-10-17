---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Game
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local HeaderOpponent = Lua.import('Module:Widget/Match/Page/Header/Opponent')

---@class MatchPageGame: Widget
---@operator call(table): MatchPageGame
local MatchPageGame = Class.new(Widget)

---@return Widget
function MatchPageGame:render()
	return Div{
		classes = {'match-bm-lol-match-header'},
		children = {
			Div{
				classes = {'match-bm-match-header-powered-by'},
				children = {'[[File:DataProvidedSAP.svg|link=]]'},
			},
			Div{
				classes = {'match-bm-lol-match-header-overview'},
				children = {
					HeaderOpponent{self.props.opponents[1]},
					Div{
						classes = {'match-bm-match-header-result'},
						children = {
							self.props.opponents[1].score,
							'&ndash;',
							self.props.opponents[2].score,
							Div{
								classes = {'match-bm-match-header-result-text'},
								children = {self.props.matchPhase},
							},
						},
					},
					HeaderOpponent{self.props.opponents[2]},
				},
			},
			Div{
				classes = {'match-bm-lol-match-header-tournament'},
				children = {Link{link = self.props.parent, children = self.props.tournament}},
			},
			Div{
				classes = {'match-bm-lol-match-header-date'},
				children = {self.props.dateCountdown},
			},
			Div{
				classes = {'match-bm-lol-match-mvp'},
				children = {'<b>MVP</b>', Array.map(self.props.mvp.players, function(player)
					return Link{link = player.name, children = player.displayname}
				end)},
			},
		},
	}
end

return MatchPageGame
