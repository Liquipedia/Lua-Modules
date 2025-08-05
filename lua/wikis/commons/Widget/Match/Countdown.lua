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

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

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

	if not match.timestamp or DateExt.isDefaultTimestamp(match.timestamp) then
		return nil
	end

	return HtmlWidgets.Span{
		classes = {'match-info-countdown'},
		children = Countdown._create{
			rawdatetime = match.finished,
			date = DateExt.toCountdownArg(match.timestamp, match.timezoneId, match.dateIsExact),
			finished = match.finished,
		},
	}
end

return MatchCountdown
