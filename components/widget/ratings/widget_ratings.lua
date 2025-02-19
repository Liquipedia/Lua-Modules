---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Ratings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Date = require('Module:Date/Ext')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Info = Lua.import('Module:Info')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local RatingsList = Lua.import('Module:Widget/Ratings/List')
local RatingsDropdown = Lua.import('Module:Widget/Ratings/Dropdown')

---@class Ratings: Widget
---@operator call(table): Ratings
local Ratings = Class.new(Widget)
Ratings.defaultProps = {
	teamLimit = 20,
	progressionLimit = 10,
	dropdownLimit = 12,
	storageType = 'lpdb',
	date = os.date('%F') --[[@as string]],
	showGraph = true,
	isSmallerVersion = false,
}

--- Finds the latest valid start date for the ratings
--- For example, if the interval is weekly and the date is a Wednesday
--- the latest valid start date is the Monday, 2 days earlier
---@param date string #iso formated date string (YYYY-MM-DD)
---@param interval 'weekly'
---@return osdate
local function calculateStartDate(date, interval)
	local simplifiedParsedDate = Date.parseIsoDate(date)
	if not simplifiedParsedDate then
		error('Invalid date provided')
	end
	local parsedDate = os.date('*t', os.time(simplifiedParsedDate)) --[[@as osdate]]
	if interval == 'weekly' then
		-- 1 is Sunday, 2 is Monday, ..., 7 is Saturday
		-- american week counting
		if parsedDate.wday == 1 then
			parsedDate.day = parsedDate.day - 6
		else
			parsedDate.day = parsedDate.day - parsedDate.wday + 2
		end
		return parsedDate
	end
	error('Invalid interval specific for ratings')
end

---@param date osdate
---@param interval 'weekly'
---@param amount integer
---@return string
local function getPreviousDate(date, interval, amount)
	if interval == 'weekly' then
		local dateCopy = Table.deepCopy(date)
		dateCopy.day = dateCopy.day - amount * 7
		return os.date('%F', os.time(dateCopy)) --[[@as string]]
	end
	error('Invalid interval specific for ratings')
end

---@return Widget
function Ratings:render()
	assert(Info.config.ratings, 'Ratings config not found')
	local startDate = calculateStartDate(self.props.date, Info.config.ratings.interval)

	local dropdownDates = Array.map(Array.range(1, self.props.dropdownLimit), function(i)
		return getPreviousDate(startDate, Info.config.ratings.interval, i - 1)
	end)

	return HtmlWidgets.Div {
		attributes = {
			class = 'ranking-table__wrapper',
		},
		children = WidgetUtil.collect(
			not self.props.isSmallerVersion and RatingsDropdown {
				dates = dropdownDates,
			} or nil,
			RatingsList {
				teamLimit = self.props.teamLimit,
				progressionLimit = self.props.progressionLimit,
				storageType = self.props.storageType,
				date = startDate,
				showGraph = self.props.showGraph,
				isSmallerVersion = self.props.isSmallerVersion,
			}
		),
	}
end

return Ratings
