---
-- @Liquipedia
-- page=Module:Features/QualificationChances/Components/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Array = Lua.import('Module:Array')
local Component = Lua.import('Module:Widget/Component')

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Label = Lua.import('Module:Widget/Basic/Label')
local WidgetUtil = Lua.import('Module:Widget/Util')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

---@param props {opponent: standardOpponent, region: string?, chance: number?, stages:number[]}
---@return Renderable
local function QualificationChanceRow(props)
	local function formatPercentage(number)
		if number == 0 then
			return ''
		elseif number == 1 then
			return '99.99%'
		end
		return tostring(number * 100) .. '%'
	end

	local function shouldBoldOverall(chance)
		return chance == 1
	end

	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.Cell{children = OpponentDisplay.BlockOpponent{opponent = props.opponent}},
			TableWidgets.Cell{children = Label{children = props.region}},
			TableWidgets.Cell{children =
				shouldBoldOverall(props.chance)
					and HtmlWidgets.B{children = formatPercentage(props.chance)}
					or formatPercentage(props.chance)},
			Array.map(props.stages or {}, function(chance)
				return TableWidgets.Cell{children = formatPercentage(chance)}
			end)
		)
	}
end

return Component.component(
	QualificationChanceRow
)
