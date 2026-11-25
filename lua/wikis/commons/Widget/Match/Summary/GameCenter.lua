---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/GameCenter
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {css: HtmlStyleProps?, children: Renderable|Renderable[]?}
---@return VNode
local function MatchSummaryGameCenter(props)
	return Html.Div{
		classes = {'brkts-popup-spaced'},
		css = props.css,
		children = props.children,
	}
end

return Component.component(MatchSummaryGameCenter)
