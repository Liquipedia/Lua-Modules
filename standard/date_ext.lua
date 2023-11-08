---
-- @Liquipedia
-- wiki=commons
-- page=Module:Date/Ext
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Variables = require('Module:Variables')

--[[
Functions for working with dates strings and timestamps.

An timestamp is a datetime represented as a number of seconds since UNIX epoch.
]]
local DateExt = {}

-- 0000-01-01 00:00:00
DateExt.minTimestamp = -62167219200

-- 9999-12-31 23:59:59
DateExt.maxTimestamp = 253402300799

-- 1970-01-01 00:00:00
DateExt.epochZero = 0

--- Parses a date string into a timestamp, returning the number of seconds since UNIX epoch.
--- The timezone offset is incorporated into the timestamp, and the timezone is discarded.
--- If the timezone is not specified, then the date is assumed to be in UTC.
--- Throws if the input string is non-empty and not a valid date.
---@param dateString string|number
---@return integer?
function DateExt.readTimestamp(dateString)
	if Logic.isEmpty(dateString) then
		return nil
	elseif type(dateString) == 'number' then
		return dateString
	end

	-- Extracts the '-4:00' out of <abbr data-tz="-4:00" title="Eastern Daylight Time (UTC-4)">EDT</abbr>
	local tzTemplateOffset = dateString:match('data%-tz%=[\"\']([%d%-%+%:]+)[\"\']')
	local datePart = (mw.text.split(dateString, '<', true)[1]):gsub('-', '')
	local timestampString = mw.getContentLanguage():formatDate('U', datePart .. (tzTemplateOffset or ''))
	return tonumber(timestampString)
end

--- Same as DateExt.readTimestamp, except that it returns nil upon failure.
---@param dateString string
---@return integer?
function DateExt.readTimestampOrNil(dateString)
	local success, timestamp = pcall(DateExt.readTimestamp, dateString)
	return success and timestamp or nil
end

--- Formats a timestamp according to the specified format.
--- The format string is the same used by mw.language.formatDate and {{#time}}.
---@param format string
---@param timestamp string|integer
---@return string|number
function DateExt.formatTimestamp(format, timestamp)
	return mw.getContentLanguage():formatDate(format, '@' .. timestamp)
end

--- Converts a date string or timestamp into a format that can be used in the date param to Module:Countdown.
---@param dateOrTimestamp string|integer
---@return string
function DateExt.toCountdownArg(dateOrTimestamp)
	local timestamp = DateExt.readTimestamp(dateOrTimestamp)
	return DateExt.formatTimestamp('F j, Y - H:i', timestamp or '') .. ' <abbr data-tz="+0:00"></abbr>'
end

--- Truncates the time of day in a date string or timestamp, and returns the date formatted as yyyy-mm-dd.
--- The time of day is truncated in the UTC timezone. The time of day and timezone are discarded.
---@param dateOrTimestamp string|integer
---@return string|number
function DateExt.toYmdInUtc(dateOrTimestamp)
	return DateExt.formatTimestamp('Y-m-d', DateExt.readTimestamp(dateOrTimestamp) or '')
end

--- Fetches contextualDate on a tournament page.
---@return string?
function DateExt.getContextualDate()
	return Variables.varDefault('tournament_enddate')
		or Variables.varDefault('tournament_startdate')
end

--- Fetches contextualDate on a tournament page with fallback to now.
---@return string
function DateExt.getContextualDateOrNow()
	return DateExt.getContextualDate()
		or os.date('%F') --[[@as string]]
end

--- Parses a YYYY-MM-DD string into a simplified osdate class
--- String must start with the YYYY. Text is allowed after after the DD.
--- YYYY is required, MM and DD are optional. They are assumed to be 1 if not supplied.
---@param str string
---@return osdate
---@overload fun():nil
function DateExt.parseIsoDate(str)
	if not str then
		return
	end
	local year, month, day = str:match('^(%d%d%d%d)%-?(%d?%d?)%-?(%d?%d?)')
	year, month, day = tonumber(year), tonumber(month), tonumber(day)

	if not year then
		return
	end
	-- Default month and day to 1 if not set
	if not month then
		month = 1
	end
	if not day then
		day = 1
	end
	-- create simplified osdate
	return {year = year, month = month, day = day}
end

return DateExt
