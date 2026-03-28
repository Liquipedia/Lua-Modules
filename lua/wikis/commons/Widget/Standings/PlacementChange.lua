---
-- @Liquipedia
-- page=Module:Widget/Standings/PlacementChange
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

local PLACEMENT_MOVE_DOUBLE_UP = IconFa{iconName = 'rankup_double'}
local PLACEMENT_MOVE_UP = IconFa{iconName = 'rankup'}
local PLACEMENT_MOVE_NEUTRAL = IconFa{iconName = 'rankneutral'}
local PLACEMENT_MOVE_DOWN = IconFa{iconName = 'rankdown'}
local PLACEMENT_MOVE_DOUBLE_DOWN = IconFa{iconName = 'rankdown_double'}

---@class PlacementChangeWidgetProps
---@field change integer
---@field emphasisThreshold integer

---@class PlacementChangeWidget: Widget
---@operator call(PlacementChangeWidgetProps): PlacementChangeWidget
---@field props PlacementChangeWidgetProps
local PlacementChangeWidget = Class.new(Widget)
PlacementChangeWidget.defaultProps = {
	change = 0,
	emphasisThreshold = 5,
}

---@return Widget?
function PlacementChangeWidget:render()
	local change = self.props.change

	return HtmlWidgets.Span{
		classes = {
			'standings-position-indicator',
			'movement-' .. PlacementChangeWidget._getMovementType(change)
		},
		children = {
			self:_getIndicator(),
			change ~= 0 and HtmlWidgets.Span{children = change} or nil
		},
	}
end

---@private
---@param change integer
---@return string
function PlacementChangeWidget._getMovementType(change)
	if change == 0 then
		return 'neutral'
	elseif change > 0 then
		return 'up'
	else
		return 'down'
	end
end

---@private
---@return Widget
function PlacementChangeWidget:_getIndicator()
	local change = self.props.change

	if change == 0 then
		return PLACEMENT_MOVE_NEUTRAL
	end

	local changeEmphasized = math.abs(change) >= self.props.emphasisThreshold
	if change > 0 then
		return changeEmphasized and PLACEMENT_MOVE_DOUBLE_UP or PLACEMENT_MOVE_UP
	end
	return changeEmphasized and PLACEMENT_MOVE_DOUBLE_DOWN or PLACEMENT_MOVE_DOWN
end

return PlacementChangeWidget
