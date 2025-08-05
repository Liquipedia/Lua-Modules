---
-- @Liquipedia
-- page=Module:Widget/Basic/Slider
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class SliderWidgetParameters
---@field id string
---@field min integer?
---@field max integer?
---@field step integer?
---@field defaultValue integer?
---@field class string?
---@field title fun(value: integer): string
---@field childrenAtValue fun(value: integer): Widget|Widget[]|nil

---@class SliderWidget: Widget
---@operator call(SliderWidgetParameters): SliderWidget
---@field props SliderWidgetParameters

local Slider = Class.new(Widget)
Slider.propSpec = {
	id = {type = 'integer', required = true},
	min = {type = 'integer', default = 1},
	max = {type = 'integer', default = 100},
	step = {type = 'integer', default = 1},
	defaultValue = {type = 'integer', default = 1},
	class = {type = 'string'},
	title = {type = 'function', default = function(v) return tostring(v) end},
	childrenAtValue = {type = 'function', required = true},
}

---@return Widget
function Slider:render()
	local min, max, step = self.props.min, self.props.max, self.props.step

	local children = {}
	for value = min, max, step do
		table.insert(children, {
			content = self.props.childrenAtValue(value) or '',
			title = self.props.title(value),
			value = value,
		})
	end

	-- We make the real slider in js
	return Div{
		classes = { 'slider' },
		attributes = {
			['data-id'] = self.props.id,
			['data-min'] = min,
			['data-max'] = max,
			['data-step'] = step,
			['data-value'] = self.props.defaultValue,
		},
		children = Array.map(children, function(child)
			return HtmlWidgets.Div{
				classes = { 'slider-value', 'slider-value--' .. child.value, self.props.class },
				attributes = {
					['data-title'] = child.title,
				},
				children = child.content,
			}
		end),
	}
end

return Slider
