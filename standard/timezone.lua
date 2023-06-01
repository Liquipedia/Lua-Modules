---
-- @Liquipedia
-- wiki=commons
-- page=Module:Timezone
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TimezoneData = mw.loadData('Module:Timezone/Data')

local OUTPUT_FORMAT = '<abbr data-tz="${tzDataLong}" title="${tzTitle} (UTC${tzDataShort})">${tzNameShort}</abbr>'

local Timezone = {}

---@alias TimezoneData {name: string, offset: {[1]: integer, [2]: integer}, abbr: string}

---@param timezone string?
---@return TimezoneData?
function Timezone.getTimezoneData(timezone)
	if String.isEmpty(timezone) then
		return
	end
	---@cast timezone -nil

	local timezoneData = TimezoneData[timezone:upper()]
	if not timezoneData then
		return
	end

	timezoneData = Table.copy(timezoneData) --[[@as TimezoneData]]
	if not timezoneData.abbr then
		timezoneData.abbr = timezone:upper()
	end

	return timezoneData
end

---@param timezone string?
---@return string?
function Timezone.getTimezoneString(timezone)
	local timezoneData = Timezone.getTimezoneData(timezone)
	if not timezoneData then
		return
	end

	local dataLong = string.format('%+03d', timezoneData.offset[1]) .. string.format(':%02d', timezoneData.offset[2])
	local dataShort = string.format('%+d', timezoneData.offset[1])
	if timezoneData.offset[2] > 0 then
		dataShort = dataShort .. string.format(':%02d', timezoneData.offset[2])
	end

	return String.interpolate(OUTPUT_FORMAT, {
		tzTitle = timezoneData.name,
		tzNameShort = timezoneData.abbr,
		tzDataLong = dataLong,
		tzDataShort = dataShort
	})
end

---@param timezone string?
---@return integer?
function Timezone.getOffset(timezone)
	local timezoneData = Timezone.getTimezoneData(timezone)
	if not timezoneData then
		return
	end

	return timezoneData.offset[1] * 60 * 60 + timezoneData.offset[2] * 60
end

return Class.export(Timezone)
