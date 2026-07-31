---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/VetoLabel
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Label = Lua.import('Module:Widget/Basic/Label')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@alias VetoTypes 'ban'|'pick'|'decider'|'defaultban'|'protect'

---@type table<VetoTypes, string>
local VetoTypes = {
	ban = 'BAN',
	pick = 'PICK',
	decider = 'DECIDER',
	defaultban = 'DEFAULT BAN',
	protect = 'PROTECT',
}

---@param props {vetoType: VetoTypes?}
---@return Renderable?
local function MatchSummaryVetoLabel(props)
	local vetoType = props.vetoType
	if not VetoTypes[vetoType] then
		return
	end

	return Label{
		labelType = 'veto-' .. vetoType,
		children = WidgetUtil.collect(
			IconFa{iconName = 'veto_' .. vetoType},
			VetoTypes[vetoType]
		)
	}
end

return Component.component(MatchSummaryVetoLabel)
