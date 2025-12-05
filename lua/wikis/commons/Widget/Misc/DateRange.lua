---
-- @Liquipedia
-- page=Module:Widget/Misc/DateRange
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local I18n = Lua.import('Module:I18n')

local Widget = Lua.import('Module:Widget')

---@class DateRangeWidget: Widget
---@operator call(table): DateRangeWidget
---@field props {startDate: string|osdateparam?, endDate: string|osdateparam?, showYear: boolean?}
local DateRange = Class.new(Widget)

---@param startDate {day?: integer, month?: integer, year?: integer}?
---@param endDate {day?: integer, month?: integer, year?: integer}?
---@param showYear boolean
---@return string
local function determineTranslateString(startDate, endDate, showYear)
	if not startDate
		or (showYear and not startDate.year)
		or (not showYear and not startDate.month) then
		return 'date-unknown'
	end

	---@param date {day?: integer, month?: integer, year?: integer}?
	local determineSingleDateString = function(date)
		if not date then
			return 'unknown'
		end
		if showYear then
			if not date.year then
				return 'unknown'
			end
			if not date.month then
				return 'year'
			end
			if not date.day then
				return 'year-month'
			end
			return 'year-month-day'
		else
			if not date.month then
				return 'unknown'
			end
			if not date.day then
				return 'month'
			end
			return 'month-day'
		end
	end

	if not endDate or (showYear and not endDate.year) or (not showYear and not endDate.month) then
		return 'date-range-' .. determineSingleDateString(startDate) .. '--unknown'
	end

	if  startDate.year == endDate.year then
		if startDate.month == endDate.month then
			if startDate.day == endDate.day then
				return 'date-range-' .. determineSingleDateString(startDate)
			end
			return showYear and 'date-range-year-month-day--day'
				or 'date-range-month-day--day'
		end
		if showYear then
			if not endDate.month then
				return 'date-range-' .. determineSingleDateString(startDate) .. '--year'
			end
			if not endDate.day then
				return 'date-range-' .. determineSingleDateString(startDate) .. '--month'
			end
			return 'date-range-' .. determineSingleDateString(startDate) .. '--month-day'
		end
	end

	return 'date-range-' .. determineSingleDateString(startDate) .. '--' .. determineSingleDateString(endDate)
end

---@return string
function DateRange:render()
	local startDate, endDate = self.props.startDate, self.props.endDate
	if type(startDate) ~= 'table' then
		startDate = DateExt.parseIsoDate(startDate --[[ @as string? ]])
	end
	if type(endDate) ~= 'table' then
		endDate = DateExt.parseIsoDate(endDate --[[ @as string? ]])
	end

	---@type osdateparam?
	local calculatingStartDate = startDate and {
		year = startDate.year or 0,
		month = startDate.month or 1,
		day = startDate.day or 1,
	} or nil
	---@type osdateparam?
	local calculatingEndDate = endDate and {
		year = endDate.year or 0,
		month = endDate.month or 1,
		day = endDate.day or 1,
	} or nil

	local dateData = {
		startYear = calculatingStartDate and os.date('%Y', os.time(calculatingStartDate)) or nil,
		startMonth = calculatingStartDate and os.date('%b', os.time(calculatingStartDate)) or nil,
		startDate = calculatingStartDate and os.date('%d', os.time(calculatingStartDate)) or nil,
		endYear = calculatingEndDate and os.date('%Y', os.time(calculatingEndDate)) or nil,
		endMonth = calculatingEndDate and os.date('%b', os.time(calculatingEndDate)) or nil,
		endDate = calculatingEndDate and os.date('%d', os.time(calculatingEndDate)) or nil,
	}

	return I18n.translate(determineTranslateString(startDate, endDate, self.props.showYear), dateData)
end

return DateRange
