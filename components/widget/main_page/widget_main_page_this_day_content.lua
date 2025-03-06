---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/MainPage/ThisDay/Content
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Template = require('Module:Template')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local Small = HtmlWidgets.Small
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ThisDayContent: Widget
---@field props { month: integer?, day: integer?, birthdayListPage: string? }
---@operator call(table): ThisDayContent
local ThisDayContent = Class.new(Widget)
ThisDayContent.defaultProps = {
	month = tonumber(os.date('%m')),
	day = tonumber(os.date('%d'))
}

function ThisDayContent:render()
	local month = self.props.month
	local day = self.props.day
	local frame = mw.getCurrentFrame()
	local birthdayListPage = self.props.birthdayListPage
	local showBirthdayList = String.isNotEmpty(birthdayListPage) and Page.exists(birthdayListPage)
	return WidgetUtil.collect(
		Div{
			attributes = { id = 'this-day-facts' },
			children = {
				Template.safeExpand(frame, 'Liquipedia:This day/' .. month .. '/' .. day)
			}
		},
		showBirthdayList and HtmlWidgets.Fragment{
			children = {
				HtmlWidgets.Hr(),
				Small{
					css = { ['font-style'] = 'italic' },
					children = {
						Link{ children = 'Click to see all birthdays', link = birthdayListPage }
					}
				}
			}
		} or nil,
		HtmlWidgets.Br(),
		Small{
			attributes = { id = 'this-day-trivialink' },
			children = {
				'Add trivia about this day ',
				Link{
					children = 'here',
					link = 'Liquipedia:This_day/' .. month .. '/' .. day
				}
			}
		}
	)
end

return ThisDayContent
