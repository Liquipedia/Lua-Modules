---
-- @Liquipedia
-- page=Module:Date/Ext
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Ordinal = Lua.import('Module:Ordinal')
local Variables = Lua.import('Module:Variables')

--[[
Functions for working with dates strings and timestamps.

An timestamp is a datetime represented as a number of seconds since UNIX epoch.
]]
local DateExt = {}

-- 0000-01-01 00:00:00
DateExt.minTimestamp = -62167219200

-- 9999-12-31 23:59:59
DateExt.maxTimestamp = 253402300799

-- default dateTime used in LPDB
DateExt.defaultTimestamp = -62167219200
DateExt.defaultDateTime = '0000-01-01 00:00:00'
DateExt.defaultDateTimeExtended = '0000-01-01T00:00:00+00:00'
DateExt.defaultDate = '0000-01-01'
DateExt.defaultYear = '0000'

--- Parses a date string into a timestamp, returning the number of seconds since UNIX epoch.
--- The timezone offset is incorporated into the timestamp, and the timezone is discarded.
--- If the timezone is not specified, then the date is assumed to be in UTC.
--- Throws if the input string is non-empty and not a valid date.
---@param dateInput string|number|osdate|osdateparam?
---@return integer?
function DateExt.readTimestamp(dateInput)
	if type(dateInput) == 'table' then
		-- in this case we have osdate really being osdateparam
		return tonumber(os.time(dateInput --[[@as osdateparam]]))
	end

	if Logic.isEmpty(dateInput) then
		return nil
	elseif type(dateInput) == 'number' then
		return dateInput
	end

	-- everything but strings was processed above
	---@cast dateInput string

	-- Extracts the '-4:00' out of <abbr data-tz="-4:00" title="Eastern Daylight Time (UTC-4)">EDT</abbr>
	local tzTemplateOffset = dateInput:match('data%-tz%=[\"\']([%d%-%+%:]+)[\"\']')
	local datePart = (mw.text.split(dateInput, '<', true)[1])
		:gsub('-', '')
		:gsub('T', '')
	local timestampString = mw.getContentLanguage():formatDate('U', datePart .. (tzTemplateOffset or ''))
	return tonumber(timestampString)
end

--- Same as DateExt.readTimestamp, except that it returns nil upon failure.
---@param dateString string|number|osdate?
---@return integer?
function DateExt.readTimestampOrNil(dateString)
	local success, timestamp = pcall(DateExt.readTimestamp, dateString)
	return success and timestamp or nil
end

--- Our runtime measures at most in seconds, and we don't care about that level of precision anyway.
--- Hence we can memoize it for performane, as it's relatively expensive if called a lot.
---@return number
DateExt.getCurrentTimestamp = FnUtil.memoize(function()
	local ts = tonumber(mw.getContentLanguage():formatDate('U'))
	---@cast ts -nil
	return ts
end)

--- Formats a timestamp according to the specified format.
--- The format string is the same used by mw.language.formatDate and {{#time}}.
---@param format string
---@param timestamp string|integer
---@return string
function DateExt.formatTimestamp(format, timestamp)
	return mw.getContentLanguage():formatDate(format, '@' .. timestamp)
end

--- Converts a date string or timestamp into a format that can be used in the date param to Module:Countdown.
---@param dateOrTimestamp string|integer|osdate|osdateparam
---@return string
function DateExt.toCountdownArg(dateOrTimestamp)
	local timestamp = DateExt.readTimestamp(dateOrTimestamp)
	return DateExt.formatTimestamp('F j, Y - H:i', timestamp or '') .. ' <abbr data-tz="+0:00"></abbr>'
end

--- Truncates the time of day in a date string or timestamp, and returns the date formatted as yyyy-mm-dd.
--- The time of day is truncated in the UTC timezone. The time of day and timezone are discarded.
---@param dateOrTimestamp string|integer|osdate|osdateparam
---@return string
function DateExt.toYmdInUtc(dateOrTimestamp)
	return DateExt.formatTimestamp('Y-m-d', DateExt.readTimestamp(dateOrTimestamp) or '')
end

---@param dateString string|integer|osdate|osdateparam
---@return boolean
function DateExt.isDefaultTimestamp(dateString)
	return DateExt.readTimestamp(dateString) == DateExt.defaultTimestamp
end

---@param dateString string|integer|osdate|osdateparam
---@return string|integer|osdate|osdateparam?
function DateExt.nilIfDefaultTimestamp(dateString)
	return not DateExt.isDefaultTimestamp(dateString) and dateString or nil
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
---@return osdateparam
---@overload fun(str: nil?):nil
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

--- Converts a timezone offset (e.g. `+2:00`) to a UTC offset in seconds.
---@param offsetString string?
---@return integer # default `0`
function DateExt.getOffsetSeconds(offsetString)
	return 0 - tonumber(mw.getContentLanguage():formatDate('U', '1970-01-01T00:00:00' .. (offsetString or '')))
end

--[[
Determines which quarter the specified date is in.
If date is not specified, it falls back to now.
]]
---@param props {date: string?, ordinalSuffix: boolean?}
---@return string|integer
function DateExt.quarterOf(props)
	local date = DateExt.parseIsoDate(props.date) or os.date('!*t')
	local month = date.month
	local quarter = math.ceil(month / 3)

	if not Logic.readBool(props.ordinalSuffix) then
		return quarter
	end

	return quarter .. Ordinal.suffix(quarter)
end

---@param date string|integer|osdateparam?
---@return integer
function DateExt.getYearOf(date)
	local timestamp = DateExt.readTimestamp(date) or DateExt.getCurrentTimestamp()
	return tonumber(DateExt.formatTimestamp('Y', timestamp)) --[[@as integer]]
end

---@param date string|integer|osdateparam?
---@return integer
function DateExt.getMonthOf(date)
	local timestamp = DateExt.readTimestamp(date) or DateExt.getCurrentTimestamp()
	return tonumber(DateExt.formatTimestamp('n', timestamp)) --[[@as integer]]
end

return DateExt
