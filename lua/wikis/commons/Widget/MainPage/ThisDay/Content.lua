---
-- @Liquipedia
-- page=Module:Widget/MainPage/ThisDay/Content
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local Small = HtmlWidgets.Small
local ThisDayBirthday = Lua.import('Module:Widget/ThisDay/Birthday')
local ThisDayPatch = Lua.import('Module:Widget/ThisDay/Patch')
local ThisDayTournament = Lua.import('Module:Widget/ThisDay/Tournament')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@type ThisDayConfig
local Config = Info.config.thisDay or {}

---@class ThisDayContent: Widget
---@field props { month: integer?, day: integer?, birthdayListPage: string?, noTwitter: boolean?}
---@operator call(table): ThisDayContent
local ThisDayContent = Class.new(Widget)
ThisDayContent.defaultProps = {
	month = DateExt.getMonthOf(),
	day = tonumber(os.date('%d'))
}

function ThisDayContent:render()
	local month = self.props.month
	local day = self.props.day
	local birthdayListPage = self.props.birthdayListPage
	local showBirthdayList = String.isNotEmpty(birthdayListPage) and Page.exists(birthdayListPage --[[@as string]])
	return WidgetUtil.collect(
		Div{
			attributes = { id = 'this-day-facts' },
			children = {
				ThisDayTournament{
					month = month,
					day = day
				},
				ThisDayBirthday{
					month = month,
					day = day,
					hideIfEmpty = Logic.readBool(Config.hideEmptyBirthdayList),
					noTwitter = self.props.noTwitter
				},
				ThisDayPatch{
					month = month,
					day = day,
					hideIfEmpty = not Logic.readBool(Config.showEmptyPatchList)
				}
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
