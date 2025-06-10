---
-- @Liquipedia
-- page=Module:Widget/Patch/Calendar
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Patch = Lua.import('Module:Patch')

local Widget = Lua.import('Module:Widget')
local DataTable = Lua.import('Module:Widget/Basic/DataTable')
local Link = Lua.import('Module:Widget/Basic/Link')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local S = HtmlWidgets.S
local Td = HtmlWidgets.Td
local Th = HtmlWidgets.Th
local Tr = HtmlWidgets.Tr

---@class PatchCalendar: Widget
---@operator call(table):PatchCalendar
local PatchCalendar = Class.new(Widget)

---@return Widget
function PatchCalendar:render()
	local patches = self:_fetch()
	local monthsPresent = PatchCalendar._getMonthsPresent(patches)

	---@param month integer
	---@return Widget
	local buildMonthCell = function(month)
		local timeStamp = DateExt.readTimestamp{
			year = self.displayYear,
			month = month,
			day = 1,
		}
		---@cast timeStamp -nil
		local monthShort = DateExt.formatTimestamp('M', timeStamp)

		if monthsPresent[month] then
			return Td{children = {Link{
				link = '#' .. monthShort .. '_' .. self.displayYear,
				children = {monthShort},
			}}}
		end
		return Td{children = {S{children = {monthShort}}}}
	end

	return DataTable{
		tableCss = {['text-align'] = 'center', ['font-size'] = '110%'},
		children = {
			Tr{children = {Th{attributes = {colspan = 6}, children = {self.displayYear}}}},
			Tr{children = Array.map(Array.range(1, 6), buildMonthCell)},
			Tr{children = Array.map(Array.range(7, 12), buildMonthCell)},
		}
	}
end

---@return StandardPatch[]
function PatchCalendar:_fetch()
	local props = self.props
	local startDate = DateExt.readTimestamp(props.sdate)
	local year = startDate and tonumber(DateExt.formatTimestamp('Y', startDate))
		or tonumber(props.year) or tonumber(os.date('%Y'))
	---@cast year -nil

	self.displayYear = year

	return Patch.getByGameYearStartDateEndDate{
		game = props.game,
		startDate = startDate,
		endDate = DateExt.readTimestamp(props.edate),
		year = (not startDate) and year or nil,
		limit = tonumber(props.limit),
	}
end

---@param patches StandardPatch[]
---@return table<integer, true>
function PatchCalendar._getMonthsPresent(patches)
	local monthsPresent = {}
	Array.forEach(patches, function(patch)
		local patchTimeStamp = patch.releaseDate.timestamp
		local month = tonumber(DateExt.formatTimestamp('n', patchTimeStamp))
		---@cast month -nil
		monthsPresent[month] = true
	end)

	return monthsPresent
end

return PatchCalendar
