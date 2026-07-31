---
-- @Liquipedia
-- page=Module:Widget/Match/Page/Comment
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {children: Renderable|Renderable[]?}
---@return VNode
local function MatchPageComment(props)
	return Html.Div{
		classes = { 'match-bm-match-additional-comment' },
		children = props.children
	}
end

return Component.component(MatchPageComment)
