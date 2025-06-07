---
-- @Liquipedia
-- wiki=commons
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

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local UnorderedList = Lua.import('Module:Widget/List/Unordered')
local Widget = Lua.import('Module:Widget')

local HEADER = HtmlWidgets.H3{children = 'Birthdays'}

---@class ThisDayBirthdayParameters: ThisDayParameters
---@field hideIfEmpty boolean?
---@field noTwitter boolean?

---@class ThisDayBirthday: Widget
---@operator call(table): ThisDayBirthday
---@field props ThisDayBirthdayParameters
local ThisDayBirthday = Class.new(Widget)

---@return (string|Widget)[]?
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
		UnorderedList{
			children = Array.map(birthdayData, FnUtil.curry(ThisDayBirthday._toLine, self))
		}
	}
end

---@private
---@param player player
---@return (string|Html|Widget)[]
function ThisDayBirthday:_toLine(player)
	local playerAge = AgeCalculation.raw{birthdate = player.birthdate}
	local playerData = {
		displayName = player.id,
		flag = player.nationality,
		pageName = player.pagename,
		faction = (player.extradata or {}).faction,
	}
	local line = {
		OpponentDisplay.InlineOpponent{
			opponent = {players = {playerData}, type = Opponent.solo}
		},
		' - ',
		playerAge.birthDate.year .. ' (age ' .. playerAge:calculate() .. ')'
	}

	if Logic.isNotEmpty((player.links or {}).twitter) and not Logic.readBool(self.props.noTwitter) then
		Array.appendWith(
			line,
			' ',
			HtmlWidgets.I{
				classes = {'lp-icon', 'lp-icon-25', 'lp-twitter', 'share-birthday'},
				attributes = {
					['data-url'] = player.links.twitter,
					['data-page'] = player.pagename,
					title = 'Send a message to ' .. player.id .. ' about their birthday!'
				},
				css = {cursor = 'pointer'}
			}
		)
	end

	return line
end

return ThisDayBirthday
