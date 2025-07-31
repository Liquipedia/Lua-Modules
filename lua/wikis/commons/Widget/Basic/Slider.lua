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
---@field childrenAtValue table<integer, Widget|Widget[]>

---@class SliderWidget: Widget
---@operator call(SliderWidgetParameters): SliderWidget
---@field props SliderWidgetParameters

local Slider = Class.new(Widget)
Slider.defaultProps = {
	linktype = 'internal',
	variant = 'primary',
	size = 'md',
	grow = false, -- Whether the button should grow to fill the available space
}

---@return Widget
function Slider:render()
	assert(self.props.id, 'Slider requires a unique id property')
	-- We make the real slider in js
	return Div{
		classes = { 'slider' },
		attributes = {
			id = self.props.id,
			['data-min'] = self.props.min or 0,
			['data-max'] = self.props.max or 100,
			['data-step'] = self.props.step or 1,
			['data-value'] = self.props.defaultValue or 0,
		},
		children = Table.map(self.props.childrenAtValue, function(children, value)
			return HtmlWidgets.Div{
				classes = { 'slider-value', 'slider-value--' .. value },
				attributes = {
					['data-title'] = self.props.title and self.props.title(value) or value,
				},
				children = children,
			}
		end),
	}
end

return Slider
