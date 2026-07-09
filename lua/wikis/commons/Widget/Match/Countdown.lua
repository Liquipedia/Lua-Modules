---
-- @Liquipedia
-- page=Module:Widget/Match/Countdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Countdown = Lua.import('Module:Countdown')
local DateExt = Lua.import('Module:Date/Ext')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@class MatchCountdownProps
---@field match MatchGroupUtilMatch
---@field format ('full'|'compact')?

---@param props MatchCountdownProps
---@return VNode?
local function MatchCountdown(props)
	local match = props.match
	if not match then
		return nil
	end

	if not match.timestamp or DateExt.isDefaultTimestamp(match.timestamp) then
		return nil
	end

	local format = props.format

	return Html.Span{
		classes = {'match-info-countdown'},
		children = Countdown.create{
			rawdatetime = (not match.dateIsExact) or match.finished,
			date = DateExt.toCountdownArg(match.timestamp, match.timezoneId, match.dateIsExact, format),
			finished = match.finished,
			format = format,
		},
	}
end

return Component.component(MatchCountdown, {format = 'full'})
