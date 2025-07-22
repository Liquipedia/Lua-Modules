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

---@class MatchCountdownProps
---@field match MatchGroupUtilMatch

---@class MatchCountdown: Widget
---@operator call(MatchCountdownProps): MatchCountdown
---@field props MatchCountdownProps
local MatchCountdown = Class.new(Widget)

---@return Widget?
function MatchCountdown:render()
	local match = self.props.match
	if not match then
		return nil
	end

	if match.timestamp == DateExt.defaultTimestamp then
		return nil
	end

	local function dateTimeDisplay()
		local baseTimestamp = match.timestamp or DateExt.readTimestamp(match.date)
		if match.dateIsExact then
			local timestamp = baseTimestamp + (Timezone.getOffset{timezone = match.extradata.timezoneid} or 0)
			local timezoneString = Timezone.getTimezoneString{timezone = match.extradata.timezoneid} or UTC
			return DateExt.formatTimestamp('F j, Y - H:i', timestamp) .. ' ' .. timezoneString
		else
			return DateExt.formatTimestamp('F j, Y', baseTimestamp) .. ' ' .. UTC
		end
	end

	return HtmlWidgets.Span{
		classes = {'match-info-countdown'},
		children = Countdown._create{
			rawdatetime = match.finished,
			date = dateTimeDisplay(),
			finished = match.finished,
		},
	}
end

return MatchCountdown
