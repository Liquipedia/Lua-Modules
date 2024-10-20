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
local MatchPageHeaderGamePlayer = Lua.import('Module:Widget/Match/Page/Game/Player')

---@class MatchPageHeaderGamePlayers: Widget
---@operator call(table): MatchPageHeaderGamePlayers
local MatchPageHeaderGamePlayers = Class.new(Widget)

---@return Widget
function MatchPageHeaderGamePlayers:render()
	local function getIconFromTeamTemplate(template)
		return template and mw.ext.TeamTemplate.teamicon(template) or nil
	end

	local team1, team2 = self.props.opponents[1], self.props.opponents[2]
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
							children = {getIconFromTeamTemplate(team1.template), unpack(Array.map(team1.players, MatchPageHeaderGamePlayer))}
						},
					},
				},
				Div{
					classes = {'match-bm-players-team'},
					children = {
						Div{
							classes = {'match-bm-lol-players-team-header'},
							children = {getIconFromTeamTemplate(team2.template), unpack(Array.map(team2.players, MatchPageHeaderGamePlayer))}
						},
					},
				},
			}
		}
	}}
end

return MatchPageHeaderGamePlayers
