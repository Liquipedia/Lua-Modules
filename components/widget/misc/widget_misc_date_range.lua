---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Misc/InlineIconAndText
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local I18n = require('Module:I18n')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class DateRangeWidget: Widget
---@operator call(table): DateRangeWidget

local DateRange = Class.new(Widget)

---@return string
function DateRange:render()
	if not tournament.startdate and not tournament.enddate then
		return I18n.translate('date-unknown')
	end
	local startdateParsed = DateExt.parseIsoDate(tournament.startdate)
	local enddateParsed = DateExt.parseIsoDate(tournament.sortdate)
	if not startdateParsed then
		return I18n.translate('date-unknown')
	end
	local startString = os.date('%b %d', startdateParsed)
	local endString = enddateParsed and os.date('%b %d', enddateParsed) or nil

	local dateData = {
		startMonth = os.date('%b', startdateParsed),
		startDate = os.date('%d', startdateParsed),
		endMonth = os.date('%b', enddateParsed),
		endDate = os.date('%d', enddateParsed),
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
