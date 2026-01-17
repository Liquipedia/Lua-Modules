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
	if not startDate or not startDate.year then
		return 'date-unknown'
	end

	if not startDate.month then
		if not showYear then
			return 'date-unknown'
		end
		if not endDate or not endDate.year then
			return 'date-range-year--unknown'
		elseif startDate.year == endDate.year then
				return 'date-range-year'
		else
			return 'date-range-year--year'
		end
	end

	if not startDate.day then
		if not endDate or not endDate.year then
			return 'date-range-year-month--unknown'
		elseif not endDate.month then
			if startDate.year == endDate.year then
				return 'date-range-year-month--unknown_month'
			else
				return 'date-range-year-month--year-unknown_month'
			end
		else
			if startDate.year == endDate.year then
				if startDate.month == endDate.month then
					return 'date-range-year-month'
				else
					return 'date-range-year-month--month'
				end
			else
				return 'date-range-year-month--year-month'
			end
		end
	end

	if not endDate or not endDate.year then
		return 'date-range-year-month-day--unknown'
	elseif not endDate.month then
		-- No check on same year:
		-- Dec 12, 2025 - TBA would be ambiguous, so display
		-- Dec 12, 2025 - TBA, 2025
		return 'date-range-year-month-day--year-unknown_month'
	elseif not endDate.day then
		if startDate.year == endDate.year then
			-- No check on same month:
			-- Dec 12 - TBA, 2025 would be ambiguous, so display
			-- Dec 12 - Dec TBA, 2025
			return 'date-range-year-month-day--month-unknown_day'
		else
			return 'date-range-year-month-day--year-month-unknown_day'
		end
	else
		if startDate.year == endDate.year then
			if startDate.month == endDate.month then
				if startDate.day == endDate.day then
					return 'date-range-year-month-day'
				else
					return 'date-range-year-month-day--day'
				end
			else
				return 'date-range-year-month-day--month-day'
			end
		else
			return 'date-range-year-month-day--year-month-day'
		end
	end
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

	local translateString = determineTranslateString(startDate, endDate, self.props.showYear)
	if self.props.showYear then
		translateString = translateString:gsub('year-', '')
	end

	return I18n.translate(translateString, dateData)
end

return DateRange
