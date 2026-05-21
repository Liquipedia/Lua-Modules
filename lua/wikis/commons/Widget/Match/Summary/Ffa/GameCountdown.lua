---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/GameCountdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Countdown = Lua.import('Module:Countdown')
local Date = Lua.import('Module:Date/Ext')
local Table = Lua.import('Module:Table')
local VodLink = Lua.import('Module:VodLink')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {game: FFAMatchGroupUtilMatch|FFAMatchGroupUtilGame?}
---@return HtmlNode?
local function MatchSummaryFfaGameCountdown(props)
	local game = props.game
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
		rawdatetime = (not game.dateIsExact) or game.winner ~= nil
	})

	return Html.Div{
		classes = {'match-countdown-block'},
		children = {
			Countdown.create(streamParameters),
			game.vod and VodLink.display{vod = game.vod} or nil,
		},
	}
end

return Component.component(MatchSummaryFfaGameCountdown)
