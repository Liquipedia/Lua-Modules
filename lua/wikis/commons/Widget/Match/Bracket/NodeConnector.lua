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

---A connector between a lower round match and the current match.
---@param props BracketNodeConnectorProps
---@return Html
local function BracketNodeConnector(props)
	local connectorNode = mw.html.create('div'):addClass('brkts-connector')

	if props.leftTop == props.rightTop then
		-- Single line segment, no joint
		local lineNode = mw.html.create('div'):addClass('brkts-line')
			:css('height', props.lineWidth .. 'px')
			:css('right', '0')
			:css('left', '0')
			:css('top', (props.leftTop - props.lineWidth / 2) .. 'px')
		return connectorNode:node(lineNode)

	else
		-- Three line segments
		local leftNode = mw.html.create('div'):addClass('brkts-line')
			:css('height', props.lineWidth .. 'px')
			:css('width', props.jointLeft and (props.jointLeft + props.lineWidth / 2) .. 'px')
			:css('right', props.jointRight and (props.jointRight - props.lineWidth / 2) .. 'px')
			:css('left', '0')
			:css('top', (props.leftTop - props.lineWidth / 2) .. 'px')

		local middleNode = mw.html.create('div'):addClass('brkts-line')
			:css('height', math.abs(props.leftTop - props.rightTop) .. 'px')
			:css('width', props.lineWidth .. 'px')
			:css('top', math.min(props.leftTop, props.rightTop) .. 'px')
			:css('left', props.jointLeft and (props.jointLeft - props.lineWidth / 2) .. 'px')
			:css('right', props.jointRight and (props.jointRight - props.lineWidth / 2) .. 'px')

		local rightNode = mw.html.create('div'):addClass('brkts-line')
			:css('height', props.lineWidth .. 'px')
			:css('left', props.jointLeft and (props.jointLeft - props.lineWidth / 2) .. 'px')
			:css('width', props.jointRight and (props.jointRight + props.lineWidth / 2) .. 'px')
			:css('right', '0')
			:css('top', (props.rightTop - props.lineWidth / 2) .. 'px')

		return connectorNode:node(leftNode):node(middleNode):node(rightNode)
	end
end

return Component.component(BracketNodeConnector)
