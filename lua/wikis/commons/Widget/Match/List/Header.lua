---
-- @Liquipedia
-- page=Module:Widget/Match/List/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DisplayUtil = Lua.import('Module:DisplayUtil')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {children: Renderable|Renderable[]?}
---@return VNode
local function MatchListHeader(props)
	return Html.Div{
		classes = {'brkts-matchlist-header'},
		css = DisplayUtil.getOverflowStyles('wrap'),
		children = props.children
	}
end

return Component.component(MatchListHeader)
