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

---@return string
function DateRange:render()
	local startDate, endDate = self.props.startDate, self.props.endDate
	if type(startDate) ~= 'table' then
		startDate = DateExt.parseIsoDate(startDate)
	end
	if type(endDate) ~= 'table' then
		endDate = DateExt.parseIsoDate(endDate)
	end

	if not startDate then
		return I18n.translate('date-unknown')
	end

	local startString = os.date('%b %d', os.time(startDate))
	local endString = endDate and os.date('%b %d', os.time(endDate)) or nil

	local dateData = {
		startMonth = os.date('%b', os.time(startDate)),
		startDate = os.date('%d', os.time(startDate)),
		endMonth = os.date('%b', os.time(endDate)),
		endDate = os.date('%d', os.time(endDate)),
	}

	if startString == endString then
		return I18n.translate('date-range-same-day', dateData)
	end

	if not endString then
		return I18n.translate('date-range-unknown-end', dateData)
	end

	if dateData.startMonth == dateData.endMonth then
		return I18n.translate('date-range-same-month', dateData)
	end

	return I18n.translate('date-range-different-months', dateData)
end

return DateRange
