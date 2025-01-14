---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/GameCountdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Date = require('Module:Date/Ext')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Timezone = require('Module:Timezone')
local VodLink = require('Module:VodLink')

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
				.. Timezone.getTimezoneString('UTC')
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
			require('Module:Countdown')._create(streamParameters),
			game.vod and VodLink.display{vod = game.vod} or nil,
		},
	}
end

return MatchSummaryFfaGameCountdown
