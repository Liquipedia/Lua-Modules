---
-- @Liquipedia
-- page=Module:Widget/MainPage/ThisDay/Content
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DateExt = Lua.import('Module:Date/Ext')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Template = Lua.import('Module:Template')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local Small = Html.Small
local WidgetUtil = Lua.import('Module:Widget/Util')

local defaultProps = {
	month = DateExt.getMonthOf(),
	day = DateExt.getDayOf()
}

---@param props { month: integer?, day: integer?, birthdayListPage: string? }
---@return Renderable[]
local function ThisDayContent(props)
	local month = props.month
	local day = props.day
	local frame = mw.getCurrentFrame()
	local birthdayListPage = props.birthdayListPage
	local showBirthdayList = String.isNotEmpty(birthdayListPage) and Page.exists(birthdayListPage --[[@as string]])
	return WidgetUtil.collect(
		Div{
			attributes = { id = 'this-day-facts' },
			children = {
				Template.safeExpand(frame, 'Liquipedia:This day/' .. month .. '/' .. day)
			}
		},
		showBirthdayList and {
			Html.Hr(),
			Small{
				css = { ['font-style'] = 'italic' },
				children = {
					Link{ children = 'Click to see all birthdays', link = birthdayListPage }
				}
			}
		} or nil,
		Html.Br(),
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

return Component.component(ThisDayContent, defaultProps)
