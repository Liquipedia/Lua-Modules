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

---@param props {classes: string[]?, children: Renderable|Renderable[]?, height: integer}
---@return VNode
local function PrizePoolRow(props)
	return Html.Div{
		classes = Array.extend(
			'prize-pool-table-row',
			props.classes
		),
		css = {
			['--prize-pool-row-height'] = props.height
		},
		children = props.children
	}
end

return Component.component(PrizePoolRow)
