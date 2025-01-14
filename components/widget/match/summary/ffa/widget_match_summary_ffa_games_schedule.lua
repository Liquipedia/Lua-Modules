---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/GamesSchedule
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')

local Widget = Lua.import('Module:Widget')
local ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
local CountdownIcon = Lua.import('Module:Widget/Match/Summary/Ffa/CountdownIcon')
local GameCountdown = Lua.import('Module:Widget/Match/Summary/Ffa/GameCountdown')

---@class MatchSummaryFfaGamesSchedule: Widget
---@operator call(table): MatchSummaryFfaGamesSchedule
local MatchSummaryFfaGamesSchedule = Class.new(Widget)

---@return Widget?
function MatchSummaryFfaGamesSchedule:render()
	local scheduleItems = self.props.match.games or {}
	local showMatchDate = self:gamesHaveDifferentDates()
	if showMatchDate and DateExt.isDefaultTimestamp(self.props.match.date) then
		return nil
	elseif showMatchDate then
		scheduleItems = {self.props.match}
	end

	if #scheduleItems == 0 then
		return nil
	end

	return ContentItemContainer{collapsed = true, collapsible = true, title = 'Schedule',
		contentClass = 'panel-content__game-schedule',
		items = Array.map(scheduleItems, function (game, idx)
			return {
				icon =  CountdownIcon{game = game},
				title = showMatchDate and 'Match:' or ('Game ' .. idx .. ':'),
				content = GameCountdown{game = game},
			}
		end)
	}
end

---@return boolean
function MatchSummaryFfaGamesSchedule:gamesHaveDifferentDates()
	local dates = Array.map(self.props.match.games or {}, Operator.property('date'))
	return Array.all(dates, function(date) return date == self.props.match.date end)
end

return MatchSummaryFfaGamesSchedule
