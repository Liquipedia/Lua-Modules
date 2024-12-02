---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/GamesSchedule
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
local CountdownIcon = Lua.import('Module:Widget/Match/Summary/Ffa/CountdownIcon')
local GameCountdown = Lua.import('Module:Widget/Match/Summary/Ffa/GameCountdown')

---@class MatchSummaryFfaGamesSchedule: Widget
---@operator call(table): MatchSummaryFfaGamesSchedule
local MatchSummaryFfaGamesSchedule = Class.new(Widget)

---@return Widget?
function MatchSummaryFfaGamesSchedule:render()
	if not self.props.games or #self.props.games == 0 then
		return nil
	end

	return ContentItemContainer{collapsed = true, collapsible = true, title = 'Schedule',
		contentClass = 'panel-content__game-schedule',
		items = Array.map(self.props.games, function (game, idx)
			return {
				icon =  CountdownIcon{game = game},
				title = 'Game ' .. idx .. ':',
				content = GameCountdown{game = game},
			}
		end)
	}
end

return MatchSummaryFfaGamesSchedule
