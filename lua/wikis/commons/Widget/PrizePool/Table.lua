---
-- @Liquipedia
-- page=Module:Widget/PrizePool/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class PrizePoolTableProps
---@field header Renderable
---@field prizeTypes integer
---@field displayedRows Renderable[]
---@field toggle Renderable?
---@field collapsedRows Renderable[]?

---@param props PrizePoolTableProps
---@return VNode
local function PrizePoolTable(props)
	return Html.Div{
		classes = {'prize-pool-table'},
		css = {
			['--prize-pool-columns'] = props.prizeTypes + 2
		},
		children = {
			props.header,
			Html.Div{
				classes = {
					'prize-pool-table-body',
					'collapsed',
					'general-collapsible',
				},
				children = WidgetUtil.collect(
					props.displayedRows,
					Table.isNotEmpty(props.collapsedRows) and {
						props.toggle,
						Html.Div{
							classes = {'should-collapse'},
							children = props.collapsedRows
						}
					} or nil
				)
			}
		}
	}
end

return Component.component(PrizePoolTable)
