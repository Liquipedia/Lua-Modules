---
-- @Liquipedia
-- page=Module:Widget/MainPage/NavigationCard
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Image = Lua.import('Module:Image')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class NavigationCardParameters
---@field file string?
---@field iconClasses string?
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
				classes = {self.props.iconClasses and 'navigation-card__icon' or 'navigation-card__image'},
				children = self.props.iconClasses and
					HtmlWidgets.I{
						classes = self:processIconClasses(self.props.iconClasses),
					} or
					Image.display(self.props.file, nil, {size = 240, link = ''}),
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

---@param classesString string
---@return string[]
function NavigationCard:processIconClasses(classesString)
	local classes = {}
	for class in string.gmatch(classesString, "%S+") do
		table.insert(classes, class)
	end
	return classes
end

return NavigationCard
