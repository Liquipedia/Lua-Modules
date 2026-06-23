---
-- @Liquipedia
-- page=Module:Widget/PrizePool/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Currency = Lua.import('Module:Currency')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local SwitchPill = Lua.import('Module:Widget/ContentSwitch/Pill')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class PrizePoolTableProps
---@field header Renderable
---@field prizeTypes integer
---@field displayedRows Renderable[]
---@field toggle Renderable?
---@field collapsedRows Renderable[]?
---@field currencies string[]?

---@param props PrizePoolTableProps
---@return VNode
local function PrizePoolTable(props)
	local prizePoolTable = Html.Div{
		classes = {'prize-pool-table'},
		css = {
			['--prize-pool-columns'] = props.prizeTypes + 2
		},
		children = {
			props.header,
			Html.Div{
				classes = {
					'prize-pool-table-body',
					'content-switch-content-container',
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

	if Logic.isEmpty(props.currencies) then
		return prizePoolTable
	end

	return Html.Div{
		classes = {
			'prize-pool-table-container',
			'toggle-area',
			'toggle-area-1',
		},
		attributes = {['data-toggle-area'] = 1},
		children = {
			SwitchPill{
				switchGroup = 'prize-pool-currency',
				storeValue = true,
				defaultActive = 1,
				tabs = Array.map(props.currencies, function (currency)
					return {
						label = Currency.display(currency),
						value = currency:lower(),
					}
				end)
			},
			prizePoolTable
		}
	}
end

return Component.component(PrizePoolTable)
