---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/GameCountdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Date = Lua.import('Module:Date/Ext')
local Table = Lua.import('Module:Table')
local Timezone = Lua.import('Module:Timezone')
local VodLink = Lua.import('Module:VodLink')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class MatchSummaryFfaGameCountdown: Widget
---@operator call(table): MatchSummaryFfaGameCountdown
local MatchSummaryFfaGameCountdown = Class.new(Widget)

---@return Widget?
function MatchSummaryFfaGameCountdown:render()
	local game = self.props.game
	if not game then
		return nil
	end

	local timestamp = Date.readTimestamp(game.date)
	if not timestamp or timestamp == Date.defaultTimestamp then
		return
	end

	local dateString
	if game.dateIsExact then
		-- TODO: Use game-TZ
		dateString = Date.formatTimestamp('F j, Y - H:i', timestamp) .. ' '
				.. Timezone.getTimezoneString{timezone = 'UTC'}
	else
		dateString = mw.getContentLanguage():formatDate('F j, Y', game.date)
	end

	local streamParameters = Table.merge(game.stream, {
		date = dateString,
		finished = game.winner ~= nil and 'true' or nil,
	})

	return HtmlWidgets.Div{
		classes = {'match-countdown-block'},
		children = {
			Lua.import('Module:Countdown')._create(streamParameters),
			game.vod and VodLink.display{vod = game.vod} or nil,
		},
	}
end

return MatchSummaryFfaGameCountdown
