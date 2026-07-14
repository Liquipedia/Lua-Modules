---
-- @Liquipedia
-- page=Module:Widget/Infobox/Center
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')

---@param props {classes: string[]?, children: Renderable|Renderable[]?}
---@return VNode?
local function Center(props)
	if Logic.isEmpty(props.children) then
		return nil
	end
	return Html.Div{children = {Html.Div{
		classes = WidgetUtil.collect('infobox-center', props.classes),
		children = props.children
	}}}
end

return Component.component(Center)
