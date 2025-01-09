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
	if not startDate then
		return I18n.translate('date-unknown')
	end
	local startdateParsed = DateExt.parseIsoDate(startDate)
	local enddateParsed = DateExt.parseIsoDate(endDate)
	if not startdateParsed then
		return I18n.translate('date-unknown')
	end
	local startString = os.date('%b %d', os.time(startdateParsed))
	local endString = enddateParsed and os.date('%b %d', os.time(enddateParsed)) or nil

	local dateData = {
		startMonth = os.date('%b', os.time(startdateParsed)),
		startDate = os.date('%d', os.time(startdateParsed)),
		endMonth = os.date('%b', os.time(enddateParsed)),
		endDate = os.date('%d', os.time(enddateParsed)),
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
