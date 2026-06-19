---
-- @Liquipedia
-- page=Module:Widget/PrizePool/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {children: Renderable[], columns: integer}
---@return VNode
local function PrizePoolTable(props)
	return Html.Div{
		classes = {
			'collapsed',
			'general-collapsible',
			'prize-pool-table',
		},
		css = {
			['--prize-pool-columns'] = #props.children
		},
		children = props.children
	}
end

return Component.component(PrizePoolTable)
