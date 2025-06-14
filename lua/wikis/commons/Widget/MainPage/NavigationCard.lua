---
-- @Liquipedia
-- page=Module:Widget/MainPage/NavigationCard
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Image = require('Module:Image')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class NavigationCardParameters
---@field file string?
---@field link string?
---@field title string?
---@field count integer?

---@class NavigationCard: Widget
---@field props NavigationCardParameters
---@operator call(NavigationCardParameters): NavigationCard
local NavigationCard = Class.new(Widget)

---@return Widget
function NavigationCard:render()
	local count = self.props.count
	return HtmlWidgets.Div{
		classes = {'navigation-card'},
		children = WidgetUtil.collect(
			HtmlWidgets.Div{
				classes = {'navigation-card__image'},
				children = Image.display(self.props.file, nil, {size = 240, link = ''}),
			},
			HtmlWidgets.Span{
				classes = {'navigation-card__title'},
				children = Link{link = self.props.link, children = self.props.title}
			},
			count and HtmlWidgets.Span{
				classes = {'navigation-card__subtitle'},
				children = mw.getContentLanguage():formatNum(tonumber(count) --[[@as integer]]),
			} or nil
		)
	}
end

return NavigationCard
