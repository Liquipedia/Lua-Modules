---
-- @Liquipedia
-- page=Module:Widget/Infobox/Title
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {children: Renderable|Renderable[]?}
---@return VNode
local function Title(props)
	return Html.Div{children = {Html.Div{
		children = props.children,
		classes = {'infobox-header', 'wiki-backgroundcolor-light', 'infobox-header-2'}
	}}}
end

return Component.component(Title)
