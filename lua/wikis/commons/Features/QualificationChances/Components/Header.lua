---
-- @Liquipedia
-- page=Module:Features/QualificationChances/Components/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Array = Lua.import('Module:Array')
local Component = Lua.import('Module:Widget/Component')

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@param props {stages?: string[]}
---@return Renderable
local function QualificationChanceHeader(props)
	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.CellHeader{children = {'Team'}},
			TableWidgets.CellHeader{children = {'Region'}},
			TableWidgets.CellHeader{children = {'Overall chance to qualify'}},
			Array.map(props.stages or {}, function(stage)
				return TableWidgets.CellHeader{children = {stage}}
			end)
		)
	}
end

return Component.component(QualificationChanceHeader)
