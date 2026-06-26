---
-- @Liquipedia
-- page=Module:Widget/Match/InfoIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {css: table<string, string|number?>?}
---@return VNode
local function MatchInfoIcon(props)
	return Html.Div{
		classes = {'brkts-match-info-icon'},
		css = props.css,
	}
end

return Component.component(MatchInfoIcon)
