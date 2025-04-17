---
-- @Liquipedia
-- wiki=commons
-- page=Module:Patch/Calendar
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Patch = Lua.import('Module:Patch')

local DataTable = Lua.import('Module:Widget/Basic/DataTable')
local Link = Lua.import('Module:Widget/Basic/Link')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local S = HtmlWidgets.S
local Td = HtmlWidgets.Td
local Th = HtmlWidgets.Th
local Tr = HtmlWidgets.Tr

---@class PatchCalendar
---@operator call(table): PatchCalendar
---@field config {game: string?, startDate: integer?, endDate: integer?, year: integer?, limit: integer?}
---@field displayYear integer
---@field patches datapoint[]
local PatchCalendar = Class.new(function(self, args)
	local startDate = DateExt.readTimestamp(args.sdate)
	local year = startDate and tonumber(DateExt.formatTimestamp('Y', startDate))
		or tonumber(args.year) or os.date('%Y')

	self.displayYear = year
	self.config = {
		game = args.game,
		startDate = startDate,
		endDate = DateExt.readTimestamp(args.edate),
		year = (not startDate) and year or nil,
		limit = tonumber(args.limit),
	}
end)

---@param frame unknown
---@return Widget
function PatchCalendar.create(frame)
	local args = Arguments.getArgs(frame)
	return PatchCalendar(args):fetch():build()
end

---@return self
function PatchCalendar:fetch()
	self.patches = Patch.getByGameYearStartDateEndDate(self.config)
	self.monthsPresent = {}
	Array.forEach(self.patches, function(patch)
		local patchTimeStamp = patch.releaseDate.timestamp
		-- can never be nil due to lpdb data having a valid date string
		---@cast patchTimeStamp -nil
		local month = tonumber(DateExt.formatTimestamp('n', patchTimeStamp))
		---@cast month -nil
		self.monthsPresent[month] = true
	end)

	return self
end

---@return Widget
function PatchCalendar:build()
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

		if self.monthsPresent[month] then
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

return PatchCalendar
