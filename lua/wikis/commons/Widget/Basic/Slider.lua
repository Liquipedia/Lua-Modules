---
-- @Liquipedia
-- page=Module:Widget/Basic/Slider
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class SliderWidgetParameters
---@field id string
---@field min integer?
---@field max integer?
---@field step integer?
---@field defaultValue integer?
---@field title fun(value: integer): string
---@field childrenAtValue fun(value: integer): Widget|Widget[]|nil

---@class SliderWidget: Widget
---@operator call(SliderWidgetParameters): SliderWidget
---@field props SliderWidgetParameters

local Slider = Class.new(Widget)
---@return Widget
function Slider:render()
	assert(self.props.id, 'Slider requires a unique id property')
	-- We make the real slider in js
	local min, max, step = self.props.min or 0, self.props.max or 100, self.props.step or 1

	local children = {}
	for value = min, max, step do
		table.insert(children, {
			content = self.props.childrenAtValue(value) or '',
			title = self.props.title and self.props.title(value) or value,
			value = value,
		})
	end

	return Div{
		classes = { 'slider' },
		attributes = {
			id = self.props.id,
			['data-min'] = min,
			['data-max'] = max,
			['data-step'] = step,
			['data-value'] = self.props.defaultValue or self.props.min or 0,
		},
		children = Array.map(children, function(child)
			return HtmlWidgets.Div{
				classes = { 'slider-value', 'slider-value--' .. child.value },
				attributes = {
					['data-title'] = child.title,
				},
				children = child.content,
			}
		end),
	}
end

return Slider
