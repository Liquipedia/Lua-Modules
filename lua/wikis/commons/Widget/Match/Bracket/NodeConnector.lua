---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/NodeConnector
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@class BracketNodeConnectorProps
---@field jointLeft number?
---@field jointRight number?
---@field leftTop number
---@field lineWidth number
---@field rightTop number

---@param lineProps {height: string|number?, width: string|number?,
---top: string|number?, left: string|number?, right: string|number?}
---@return VNode
local function createLineNode(lineProps)
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

---A connector between a lower round match and the current match.
---@param props BracketNodeConnectorProps
---@return VNode
local function BracketNodeConnector(props)
	if props.leftTop == props.rightTop then
		-- Single line segment, no joint
		return Html.Div{
			classes = {'brkts-connector'},
			children = createLineNode{
				height = props.lineWidth .. 'px',
				right = 0,
				left = 0,
				top = (props.leftTop - props.lineWidth / 2) .. 'px',
			}
		}

	end
	-- Three line segments
	return Html.Div{
		classes = {'brkts-connector'},
		children = {
			createLineNode{
				height = props.lineWidth .. 'px',
				width = props.jointLeft and (props.jointLeft + props.lineWidth / 2) .. 'px',
				right = props.jointRight and (props.jointRight - props.lineWidth / 2) .. 'px',
				left = 0,
				top = (props.leftTop - props.lineWidth / 2) .. 'px',
			},
			createLineNode{
				height = math.abs(props.leftTop - props.rightTop) .. 'px',
				width = props.lineWidth .. 'px',
				top = math.min(props.leftTop, props.rightTop) .. 'px',
				left = props.jointLeft and (props.jointLeft - props.lineWidth / 2) .. 'px',
				right = props.jointRight and (props.jointRight - props.lineWidth / 2) .. 'px',
			},
			createLineNode{
				height = props.lineWidth .. 'px',
				left = props.jointLeft and (props.jointLeft - props.lineWidth / 2) .. 'px',
				width = props.jointRight and (props.jointRight + props.lineWidth / 2) .. 'px',
				right = 0,
				top = (props.rightTop - props.lineWidth / 2) .. 'px',
			},
		}
	}
end

return Component.component(BracketNodeConnector)
