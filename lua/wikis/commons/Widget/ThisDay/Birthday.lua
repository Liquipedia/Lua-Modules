---
-- @Liquipedia
-- page=Module:Widget/ThisDay/Birthday
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')

local AgeCalculation = Lua.import('Module:AgeCalculation')
local ThisDayQuery = Lua.import('Module:ThisDay/Query')

local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local Html = Lua.import('Module:Widget/Html')
local ListWidgets = Lua.import('Module:Widget/List')
local Widget = Lua.import('Module:Widget')

local HEADER = Html.H3{children = 'Birthdays'}
local TODAY = os.date("*t")

---@class ThisDayBirthdayParameters: ThisDayParameters
---@field hideIfEmpty boolean?
---@field noTwitter boolean?

---@class ThisDayBirthday: Widget
---@operator call(table): ThisDayBirthday
---@field props ThisDayBirthdayParameters
local ThisDayBirthday = Class.new(Widget)
ThisDayBirthday.defaultProps = {
	month = TODAY.month,
	day = TODAY.day
}

---@return Renderable[]?
function ThisDayBirthday:render()
	local month = self.props.month
	local day = self.props.day
	assert(month, 'Month not specified')
	assert(day, 'Day not specified')

	local birthdayData = ThisDayQuery.birthday(month, day)

	if Logic.isEmpty(birthdayData) then
		if Logic.readBool(self.props.hideIfEmpty) then return end
		return {
			HEADER,
			'There are no birthdays today'
		}
	end

	return {
		HEADER,
		ListWidgets.Unordered{
			children = Array.map(birthdayData, FnUtil.curry(ThisDayBirthday._toLine, self))
		}
	}
end

---@private
---@param record ThisDayBirthdayRecord
---@return Renderable[]
function ThisDayBirthday:_toLine(record)
	local playerAge = AgeCalculation.raw{birthdate = record.birthDate}
	local line = {
		PlayerDisplay.InlinePlayer{player = record.player},
		' - ',
		playerAge.birthDate.year .. ' (age ' .. playerAge:calculate() .. ')'
	}

	if Logic.isNotEmpty((record.links or {}).twitter) and not Logic.readBool(self.props.noTwitter) then
		Array.appendWith(
			line,
			' ',
			Html.I{
				classes = {'lp-icon', 'lp-icon-25', 'lp-twitter', 'share-birthday'},
				attributes = {
					['data-url'] = record.links.twitter,
					['data-page'] = record.player.pageName,
					title = 'Send a message to ' .. record.player.displayName .. ' about their birthday!'
				},
				css = {cursor = 'pointer'}
			}
		)
	end

	return line
end

return ThisDayBirthday
