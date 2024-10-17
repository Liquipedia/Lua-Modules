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
local Fragment = HtmlWidgets.Fragment
local MatchPageGameDraft = Lua.import('Module:Widget/Match/Page/Game/Draft')
local MatchPageGameStats = Lua.import('Module:Widget/Match/Page/Game/Stats')
local MatchPageGamePlayers = Lua.import('Module:Widget/Match/Page/Game/Players')

---@class MatchPageGame: Widget
---@operator call(table): MatchPageGame
local MatchPageGame = Class.new(Widget)

---@return Widget
function MatchPageGame:render()
	return Fragment{
		children = {
			MatchPageGameDraft{
				opponents = Array.map(self.props.teams, function(opponent)
					return {
						icon = opponent.icon,
						picks = opponent.picks,
						bans = opponent.bans,
						side = opponent.side,
					}
				end),
			},
			MatchPageGameStats{
				opponents = Array.map(self.props.teams, function(opponent)
					return {
						icon = opponent.icon,
						side = opponent.side,
						score = opponent.scoreDisplay,
						kills = opponent.kills,
						deaths = opponent.deaths,
						assists = opponent.assists,
						gold = opponent.gold,
						towers = opponent.objectives.towers,
						barracks = opponent.objectives.barracks,
						roshans = opponent.objectives.roshans,
					}
				end),
				length = self.props.length,
				winner = self.props.winnerName,
			},
			MatchPageGamePlayers{
				opponents = Array.map(self.props.teams, function (opponent)
					return {
						icon = opponent.icon,
						players = opponent.players,
					}
				end)
			},
		}
	}
end

return MatchPageGame
