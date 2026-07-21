---
-- @Liquipedia
-- page=Module:Widget/Infobox/Title
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local ChevronToggle = Lua.import('Module:Widget/GeneralCollapsible/ChevronToggle')
local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class InfoboxTitleProps
---@field isCollapsibleToggle boolean?
---@field children Renderable|Renderable[]?

---@param props InfoboxTitleProps
---@return VNode
local function Title(props)
	if props.isCollapsibleToggle then
		return Html.Div{
			attributes = {
				['data-collapsible-click-region'] = 'true'
			},
			children = WidgetUtil.collect(
				props.children,
				ChevronToggle{}
			),
			classes = {'infobox-header', 'wiki-backgroundcolor-light', 'infobox-header-2'}
		}
	end

	return Html.Div{
		children = Html.Div{
			children = props.children,
			classes = {'infobox-header', 'wiki-backgroundcolor-light', 'infobox-header-2'}
		}
	}
end

return Component.component(Title)
