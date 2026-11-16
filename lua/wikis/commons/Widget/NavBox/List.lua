---
-- @Liquipedia
-- page=Module:Widget/NavBox/List
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local Ul = Html.Ul
local Li = Html.Li

---@param props {children: Renderable[], css: HtmlStyleProps?, supressHtmlList: boolean?}
---@return VNode
local function NavBoxList(props)
	local elements = props.children

	if not props.supressHtmlList then
		elements = Array.map(props.children, function(child)
			return Li{
				children = child
			}
		end)
	end

	-- interleaving with new lines is needed for better break points on certain widths
	elements = Array.interleave(elements, '\n')

	if not props.supressHtmlList then
		elements = {Ul{children = elements}}
	end

	return Div{
		classes = {'hlist'},
		css = Table.merge({padding = '0 0.25em'}, props.css),
		children = elements
	}
end

return Component.component(NavBoxList)
