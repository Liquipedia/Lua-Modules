---
-- @Liquipedia
-- page=Module:Widget/Standings/PlacementChange
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local HtmlWidgets = Lua.import('Module:Widget/Html')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

local PLACEMENT_MOVE_DOUBLE_UP = IconFa{iconName = 'rankup_double'}
local PLACEMENT_MOVE_UP = IconFa{iconName = 'rankup'}
local PLACEMENT_MOVE_NEUTRAL = IconFa{iconName = 'rankneutral'}
local PLACEMENT_MOVE_DOWN = IconFa{iconName = 'rankdown'}
local PLACEMENT_MOVE_DOUBLE_DOWN = IconFa{iconName = 'rankdown_double'}

local defaultProps = {
	change = 0,
	emphasisThreshold = 5,
}

---@private
---@param change integer
---@return string
local function getMovementType(change)
	if change == 0 then
		return 'neutral'
	elseif change > 0 then
		return 'up'
	else
		return 'down'
	end
end

---@private
---@return Renderable
local function getIndicator(change, threshold)
	if change == 0 then
		return PLACEMENT_MOVE_NEUTRAL
	end

	local changeEmphasized = math.abs(change) >= threshold
	if change > 0 then
		return changeEmphasized and PLACEMENT_MOVE_DOUBLE_UP or PLACEMENT_MOVE_UP
	end
	return changeEmphasized and PLACEMENT_MOVE_DOUBLE_DOWN or PLACEMENT_MOVE_DOWN
end

---@param props {change: integer?, emphasisThreshold: integer?}
---@return Renderable?
local function PlacementChangeWidget(props)
	---@cast props {change: integer, emphasisThreshold: integer}
	local change = props.change

	return HtmlWidgets.Span{
		classes = {
			'standings-position-indicator',
			'movement-' .. getMovementType(change)
		},
		children = {
			getIndicator(change, props.emphasisThreshold),
			change ~= 0 and HtmlWidgets.Span{children = math.abs(change)} or nil
		},
	}
end

return Component.component(PlacementChangeWidget, defaultProps)
