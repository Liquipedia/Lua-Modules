---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/GamesSchedule
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Operator = Lua.import('Module:Operator')

local Component = Lua.import('Module:Widget/Component')
local ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
local CountdownIcon = Lua.import('Module:Widget/Match/Summary/Ffa/CountdownIcon')
local GameCountdown = Lua.import('Module:Widget/Match/Summary/Ffa/GameCountdown')

local MatchSummaryFfaGamesSchedule = {}

---@param props {match: FFAMatchGroupUtilMatch}
---@return VNode?
function MatchSummaryFfaGamesSchedule.render(props)
	local scheduleItems = props.match.games or {}
	local showMatchDate = MatchSummaryFfaGamesSchedule._gamesHaveDifferentDates(props.match)
	if showMatchDate and DateExt.isDefaultTimestamp(props.match.date) then
		return nil
	elseif showMatchDate then
		scheduleItems = {props.match}
	end

	if #scheduleItems == 0 then
		return nil
	end

	return ContentItemContainer{collapsed = true, collapsible = true, title = 'Schedule',
		contentClass = 'panel-content__game-schedule',
		items = Array.map(scheduleItems, function (game, idx)
			return {
				icon = CountdownIcon{game = game},
				title = showMatchDate and 'Match:' or ('Game ' .. idx .. ':'),
				content = GameCountdown{game = game},
			}
		end)
	}
end

---@private
---@param match FFAMatchGroupUtilMatch
---@return boolean
function MatchSummaryFfaGamesSchedule._gamesHaveDifferentDates(match)
	local dates = Array.map(match.games or {}, Operator.property('date'))
	return Array.all(dates, function(date) return date == match.date end)
end

return Component.component(MatchSummaryFfaGamesSchedule.render)
