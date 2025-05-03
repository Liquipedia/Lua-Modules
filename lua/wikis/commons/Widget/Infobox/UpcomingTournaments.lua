---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Infobox/UpcomingTournaments
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Header = Lua.import('Module:Widget/Infobox/UpcomingTournaments/Header')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class UpcomingTournaments: Widget
---@operator call(table): UpcomingTournaments
local UpcomingTournaments = Class.new(Widget)

---@return Widget
function UpcomingTournaments:render()
	return Div{
		classes = {'fo-nttax-infobox', 'wiki-bordercolor-light', 'noincludereddit'},
		css = {['border-top'] = 'none'},
		children = WidgetUtil.collect(
			Header{}
		)
	}
end

return UpcomingTournaments
