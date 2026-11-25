---
-- @Liquipedia
-- page=Module:Widget/Infobox/NoWrap
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {children: Renderable|Renderable[]?}
---@return VNode
local function NoWrap(props)
	return Html.Span{
		css = {['white-space'] = 'nowrap'},
		children = props.children,
	}
end

return Component.component(NoWrap)
