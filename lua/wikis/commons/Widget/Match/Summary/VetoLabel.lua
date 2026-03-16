---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/VetoLabel
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
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

	return HtmlWidgets.Span{
		classes = {'brkts-veto-label', 'veto--' .. vetoType},
		children = WidgetUtil.collect(
			IconFa{iconName = 'veto_' .. vetoType},
			VetoTypes[vetoType]
		)
	}
end

return MatchSummaryVetoLabel
