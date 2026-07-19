---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Body
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@param props {classes: string[]?, children: Renderable|Renderable[]?}
---@return VNode
local function MatchSummaryBody(props)
	return Div{
		classes = Array.extend('brkts-popup-body', props.classes),
		children = props.children,
	}
end

return Component.component(MatchSummaryBody)
