---
-- @Liquipedia
-- page=Module:Widget/PrizePool/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@class PrizePoolRowProps: HtmlNodeProps
---@field placement string|number?
---@field height integer?

---@param props PrizePoolRowProps
---@return VNode
local function PrizePoolRow(props)
	local css = props.css or {}
	css['--prize-pool-row-height'] = props.height

	local attributes = props.attributes or {}
	attributes['data-placement'] = (props.placement or 0) <= 3 and props.placement or nil

	return Html.Div{
		classes = Array.extend(
			'prize-pool-table-row',
			props.classes
		),
		attributes = attributes,
		css = css,
		children = props.children
	}
end

return Component.component(PrizePoolRow)
