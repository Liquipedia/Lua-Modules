---
-- @Liquipedia
-- page=Module:Widget/Match/Countdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Countdown = Lua.import('Module:Countdown')
local DateExt = Lua.import('Module:Date/Ext')
local Timezone = Lua.import('Module:Timezone')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local UTC = Timezone.getTimezoneString{timezone = 'UTC'}

---@class MatchCountdown: Widget
---@operator call(table): MatchCountdown
local MatchCountdown = Class.new(Widget)

---@return Widget?
function MatchCountdown:render()
	---@type MatchGroupUtilMatch
	local match = self.props.match
	if not match then
		return nil
	end

	if match.timestamp == DateExt.defaultTimestamp then
		return nil
	end

	local dateString
	if match.dateIsExact then
		local timestamp = DateExt.readTimestamp(match.date) + (Timezone.getOffset{timezone = match.extradata.timezoneid} or 0)
		dateString = DateExt.formatTimestamp('F j, Y - H:i', timestamp) .. ' '
				.. (Timezone.getTimezoneString{timezone = match.extradata.timezoneid} or UTC)
	else
		dateString = mw.getContentLanguage():formatDate('F j, Y', match.date) .. UTC
	end

	return HtmlWidgets.Span{
		classes = {'match-info-countdown'},
		children = Countdown._create{
			rawdatetime = match.finished or nil,
			date = dateString,
			finished = match.finished,
		},
	}
end

return MatchCountdown
