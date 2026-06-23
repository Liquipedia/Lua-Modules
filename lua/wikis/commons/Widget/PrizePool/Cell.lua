---
-- @Liquipedia
-- page=Module:Widget/PrizePool/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@class PrizePoolCellProps:HtmlNodeProps
---@field fullHeight boolean?
---@field height integer?

---@param props PrizePoolCellProps
---@return VNode
local function PrizePoolCell(props)
	return Html.Div{
		attributes = props.attributes,
		classes = Array.extend(
			'prize-pool-table-cell',
			props.classes,
			props.fullHeight and 'full-height' or nil
		),
		css = {
			['--prize-pool-cell-height'] = props.height
		},
		children = props.children,
	}
end

return Component.component(PrizePoolCell)
