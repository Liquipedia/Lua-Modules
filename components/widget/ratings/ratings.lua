---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Ratings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Date = require('Module:Date/Ext')
local Lua = require('Module:Lua')

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

---@param date string #iso formated date string (YYYY-MM-DD)
---@param interval 'weekly' | 'monthly'
---@return unknown
local function earlierValidDate(date, interval)
	local simplifiedParsedDate = Date.parseIsoDate(date)
	if not simplifiedParsedDate then
		error('Invalid date provided')
	end
	local parsedDate = os.date('*t', os.time(simplifiedParsedDate))
	if interval == 'weekly' then
		-- 1 is Sunday, 2 is Monday, ..., 7 is Saturday
		-- american week counting
		if parsedDate.wday == 1 then
			parsedDate.day = parsedDate.day - 6
		else
			parsedDate.day = parsedDate.day - parsedDate.wday + 2
		end
		return parsedDate
	elseif interval == 'monthly' then
		parsedDate.day = 1
		return parsedDate
	end
	error('Invalid interval specific for ratings')
end

---@return Widget
function Ratings:render()
	local actualDate = earlierValidDate(self.props.date, Info.config.ratings.interval)
	return HtmlWidgets.Div {
		attributes = {
			class = 'ranking-table__wrapper',
		},
		children = WidgetUtil.collect(
			not self.props.isSmallerVersion and RatingsDropdown {
				date = actualDate,
				limit = self.props.dropdownLimit,
			} or nil,
			RatingsList {
				teamLimit = self.props.teamLimit,
				progressionLimit = self.props.progressionLimit,
				storageType = self.props.storageType,
				date = actualDate,
				showGraph = self.props.showGraph,
				isSmallerVersion = self.props.isSmallerVersion,
			}
		),
	}
end

return Ratings
