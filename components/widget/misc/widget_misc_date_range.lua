---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Misc/DateRange
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local I18n = require('Module:I18n')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class DateRangeWidget: Widget
---@operator call(table): DateRangeWidget

local DateRange = Class.new(Widget)

---@param startDate {day?: integer, month?: integer}?
---@param endDate {day?: integer, month?: integer}?
---@return string
local function determineTranslateString(startDate, endDate)
	if not startDate or not startDate.month then
		return 'date-unknown'
	end

	if not endDate or not endDate.month then
		if not startDate.day then
			return 'date-range-different-months-unknown-days-and-end-month'
		end
		return 'date-range-different-months-unknown-end'
	end

	if not startDate.day and not endDate.day then
		if startDate.month == endDate.month then
			return 'date-range-same-month-unknown-days'
		end
		return 'date-range-different-months-unknown-days'
	end

	if not endDate.day then
		return 'date-range-different-months-unknown-end-day'
	end

	if startDate.month == endDate.month then
		if startDate.day == endDate.day then
			return 'date-range-same-day'
		end
		return 'date-range-same-month'
	end

	return 'date-range-different-months'
end

---@return string
function DateRange:render()
	local startDate, endDate = self.props.startDate, self.props.endDate
	if type(startDate) ~= 'table' then
		startDate = DateExt.parseIsoDate(startDate)
	end
	if type(endDate) ~= 'table' then
		endDate = DateExt.parseIsoDate(endDate)
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
		startMonth = calculatingStartDate and os.date('%b', os.time(calculatingStartDate)) or nil,
		startDate = calculatingStartDate and os.date('%d', os.time(calculatingStartDate)) or nil,
		endMonth = calculatingEndDate and os.date('%b', os.time(calculatingEndDate)) or nil,
		endDate = calculatingEndDate and os.date('%d', os.time(calculatingEndDate)) or nil,
	}

	return I18n.translate(determineTranslateString(startDate, endDate), dateData)
end

return DateRange
