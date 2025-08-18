---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/GameCountdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Countdown = Lua.import('Module:Countdown')
local Date = Lua.import('Module:Date/Ext')
local Table = Lua.import('Module:Table')
local VodLink = Lua.import('Module:VodLink')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class MatchSummaryFfaGameCountdown: Widget
---@operator call(table): MatchSummaryFfaGameCountdown
---@field props {game: FFAMatchGroupUtilGame?}
local MatchSummaryFfaGameCountdown = Class.new(Widget)

---@return Widget?
function MatchSummaryFfaGameCountdown:render()
	local game = self.props.game
	if not game then
		return nil
	end

	local timestamp = Date.readTimestamp(game.date)
	if not timestamp or Date.isDefaultTimestamp(timestamp) then
		return
	end

	local streamParameters = Table.merge(game.stream, {
		-- TODO: Use game-TZ
		date = Date.toCountdownArg(timestamp, nil, game.dateIsExact),
		finished = game.winner ~= nil and 'true' or nil,
	})

	return HtmlWidgets.Div{
		classes = {'match-countdown-block'},
		children = {
			Countdown._create(streamParameters),
			game.vod and VodLink.display{vod = game.vod} or nil,
		},
	}
end

return MatchSummaryFfaGameCountdown
