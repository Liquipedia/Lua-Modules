---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/MainPage/ThisDay/Content
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local Small = HtmlWidgets.Small

---@class ThisDayContent: Widget
---@operator call(table): ThisDayContent
local ThisDayContent = Class.new(Widget)

function ThisDayContent:render()
	local today = os.date('*t')
	local frame = mw.getCurrentFrame()
	return {
		Div{
			attributes = { id = 'this-day-facts' },
			children = {
				frame:expandTemplate{ title = 'Liquipedia:This day/' .. today.month .. '/' .. today.day }
			}
		},
		Small{
			attributes = { id = 'this-day-trivialink' },
			children = {
				'Add trivia about this day ',
				Link{
					children = 'here',
					link = 'Liquipedia:This_day/' .. today.month .. '/' .. today.day
				}
			}
		}
	}
end

return ThisDayContent
