---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Game/Player/Stat
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchPageHeaderGamePlayerStat: Widget
---@operator call(table): MatchPageHeaderGamePlayerStat
local MatchPageHeaderGamePlayerStat = Class.new(Widget)

---@return Widget
function MatchPageHeaderGamePlayerStat:render()
	return Div{
		classes = {'match-bm-players-player-stat'},
		children = {
			Div{
				classes = {'match-bm-players-player-stat-title'},
				children = {self.props.icon, self.props.title},
			},
			Div{
				classes = {'match-bm-players-player-stat-data'},
				children = self.props.children,
			}
		}
	}
end

return MatchPageHeaderGamePlayerStat