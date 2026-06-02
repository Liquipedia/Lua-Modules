---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@param props {classes: string[]?, css: table<string, string|number?>?, children: Renderable|Renderable[]}
---@return VNode
function MatchSummaryRow(props)
	return Div{
		classes = Array.extend('brkts-popup-body-element', props.classes),
		css = props.css,
		children = props.children,
	}
end

return Component.component(MatchSummaryRow)
