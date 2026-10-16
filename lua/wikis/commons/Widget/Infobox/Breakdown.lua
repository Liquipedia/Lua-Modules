---
-- @Liquipedia
-- page=Module:Widget/Infobox/Breakdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')

---@class BreakdownProps
---@field classes string[]?
---@field contentClasses table<integer, string[]>? --can have gaps in the outer table
---@field children Renderable[]?

---@param props BreakdownProps
---@return VNode?
local function Breakdown(props)
	if Logic.isEmpty(props.children) then
		return nil
	end

	local number = #props.children
	local mappedChildren = Array.map(props.children, function(child, childIndex)
		return Html.Div{
			children = {child},
			classes = WidgetUtil.collect(
				props.classes,
				props.contentClasses['content' .. childIndex]
			),
		}
	end)
	return Html.Div{
		css = {
			['grid-template-columns'] = 'repeat(' .. number .. ', 1fr)'
		},
		children = mappedChildren,
	}
end

return Component.component(Breakdown, {contentClasses = {}})
