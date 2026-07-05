---
-- @Liquipedia
-- page=Module:Widget/FilterButtons/Button
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@alias FilterButton VNode<FilterButtonParameters>

---@class FilterButtonParameters
---@field buttonClasses string[]?
---@field css table<string,string>?
---@field active boolean?
---@field value string?
---@field display Renderable|Renderable[]?

---@param props FilterButtonParameters
---@return VNode
local function FilterButton(props)
	return Html.Span{
		classes = Array.extend({
			'filter-button',
			Logic.readBool(props.active) and 'filter-button--active' or nil
		}, props.buttonClasses),
		attributes = { ['data-filter-on'] = props.value },
		css = props.css,
		children = props.display
	}
end

return Component.component(FilterButton)
