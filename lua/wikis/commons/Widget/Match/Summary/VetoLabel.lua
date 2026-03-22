---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/VetoLabel
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Label = Lua.import('Module:Widget/Basic/Label')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@enum VetoTypes
local VetoTypes = {
	ban = 'BAN',
	pick = 'PICK',
	decider = 'DECIDER',
	defaultban = 'DEFAULT BAN',
	protect = 'PROTECT',
}

---@class MatchSummaryVetoLabel: Widget
---@operator call(table): MatchSummaryVetoLabel
---@field props {vetoType: VetoTypes?}
local MatchSummaryVetoLabel = Class.new(Widget)

---@return Widget?
function MatchSummaryVetoLabel:render()
	local vetoType = self.props.vetoType
	if not VetoTypes[vetoType] then
		return
	end

	return Label{
		labelType = {'veto-' .. vetoType},
		children = WidgetUtil.collect(
			IconFa{iconName = 'veto_' .. vetoType},
			VetoTypes[vetoType]
		)
	}
end

return MatchSummaryVetoLabel
