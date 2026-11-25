---
-- @Liquipedia
-- page=Module:Widget/Basic/Slider
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@class SliderWidgetParameters
---@field id string
---@field min integer?
---@field max integer?
---@field step integer?
---@field defaultValue integer?
---@field class string?
---@field title fun(value: integer): string
---@field childrenAtValue fun(value: integer): Widget|Widget[]|nil

---@param props SliderWidgetParameters
---@return HtmlNode
local function Slider(props)
	assert(props.id, 'Slider requires a unique id property')
	-- We make the real slider in js
	local min, max, step = props.min or 0, props.max or 100, props.step or 1

	local children = {}
	for value = min, max, step do
		table.insert(children, {
			content = props.childrenAtValue(value) or '',
			title = props.title and props.title(value) or value,
			value = value,
		})
	end

	return Div{
		classes = { 'slider' },
		attributes = {
			['data-id'] = props.id,
			['data-min'] = min,
			['data-max'] = max,
			['data-step'] = step,
			['data-value'] = props.defaultValue or props.min or 0,
		},
		children = Array.map(children, function(child)
			return Div{
				classes = { 'slider-value', 'slider-value--' .. child.value, props.class },
				attributes = {
					['data-title'] = child.title,
				},
				children = child.content,
			}
		end),
	}
end

return Component.component(Slider)
