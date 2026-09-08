---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/ConnectorStub
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local BracketLineNode = Lua.import('Module:Widget/Match/Bracket/LineNode')

---@param props {lineWidth: number, rightTop: number}
---@return VNode
local function BracketConnectorStub(props)
	return Html.Div{
		classes = {'brkts-connector-stub'},
		children = BracketLineNode{
			height = props.lineWidth .. 'px',
			left = '10px',
			right = 0,
			top = (props.rightTop - props.lineWidth / 2) .. 'px',
		}
	}
end

return Component.component(BracketConnectorStub)
