---
-- @Liquipedia
-- page=Module:Widget/MainPage/NavigationCard
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Image = Lua.import('Module:Image')
local Logic = Lua.import('Module:Logic')
local IconData = Lua.import('Module:Icon/Data')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class NavigationCardParameters
---@field file string?
---@field iconName string[]?
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

	local contentDiv

	if self.props.iconName then
		-- Icon rendering
		contentDiv = HtmlWidgets.Div{
			classes = {'navigation-card__icon'},
			children = IconFa{iconName = self.props.iconName}
		}
	else
		-- Image rendering
		contentDiv = HtmlWidgets.Div{
			classes = {'navigation-card__image'},
			children = Image.display(self.props.file, nil, {size = 240, link = ''})
		}
	end

	return HtmlWidgets.Div{
		classes = {'navigation-card'},
		children = WidgetUtil.collect(
				contentDiv,
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
