---
-- @Liquipedia
-- page=Module:Widget/MainPage/NavigationCard
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class NavigationCardParameters
---@field file string?
---@field iconName string?
---@field link string?
---@field title string?
---@field count integer?

---@param props NavigationCardParameters
---@return VNode
local function NavigationCard(props)
	local count = props.count

	local contentDiv

	if props.iconName then
		-- Icon rendering
		contentDiv = Html.Div{
			classes = {'navigation-card__icon'},
			children = IconFa{iconName = props.iconName}
		}
	else
		-- Image rendering
		contentDiv = Html.Div{
			classes = {'navigation-card__image'},
			children = IconImage{imageLight = props.file, size = '240px'}
		}
	end

	return Html.Div{
		classes = {'navigation-card'},
		children = WidgetUtil.collect(
			contentDiv,
			Html.Span{
				classes = {'navigation-card__title'},
				children = Link{link = props.link, children = props.title}
			},
			count and Html.Span{
				classes = {'navigation-card__subtitle'},
				children = mw.getContentLanguage():formatNum(tonumber(count) --[[@as integer]]),
			} or nil
		)
	}
end

return Component.component(NavigationCard)
