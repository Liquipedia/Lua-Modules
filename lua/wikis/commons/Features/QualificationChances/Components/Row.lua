---
-- @Liquipedia
-- page=Module:Features/QualificationChances/Components/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Array = Lua.import('Module:Array')
local Component = Lua.import('Module:Widget/Component')
local MathUtil = Lua.import('Module:MathUtil')

local ChanceBar = Lua.import('Module:Features/QualificationChances/Components/ChanceBar')
local Label = Lua.import('Module:Widget/Basic/Label')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@param ratio number
---@return string
local function formatPercentage(ratio)
	if ratio == 0 then
		return ''
	elseif ratio == 1 then
		return '99.99%'
	end
	return MathUtil.formatPercentage(ratio, 2)
end

---@param props {opponent: standardOpponent, region: string?, chance: number, stages: number[]}
---@return Renderable
local function QualificationChanceRow(props)
	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.Cell{children = OpponentDisplay.BlockOpponent{opponent = props.opponent}},
			TableWidgets.Cell{children = Label{
				labelScheme = 'region',
				attributes = {['data-region'] = props.region and props.region:lower() or nil},
				children = props.region,
			}},
			TableWidgets.Cell{
				css = props.chance == 1 and {['font-weight'] = 'bold'} or nil,
				children = formatPercentage(props.chance),
			},
			TableWidgets.Cell{children = ChanceBar{chance = props.chance, stages = props.stages}},
			Array.map(props.stages, function(chance)
				return TableWidgets.Cell{children = formatPercentage(chance)}
			end)
		)
	}
end

return Component.component(QualificationChanceRow)
