---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/LineNode
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@class BracketLineNodeProps
---@field height string|number?
---@field width string|number?
---@field top string|number?
---@field left string|number?
---@field right string|number?

---@param lineProps BracketLineNodeProps
---@return VNode
local function BracketLineNode(lineProps)
	return Html.Div{
		classes = {'brkts-line'},
		css = {
			height = lineProps.height,
			width = lineProps.width,
			top = lineProps.top,
			left = lineProps.left,
			right = lineProps.right,
		}
	}
end

return Component.component(BracketLineNode)
