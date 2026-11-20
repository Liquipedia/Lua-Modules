---
-- @Liquipedia
-- page=Module:Widget/Basic/Carousel/Button
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Button = Lua.import('Module:Widget/Basic/Button')
local Html = Lua.import('Module:Widget/Html')

local DIRECTIONS = {
	left = {title = 'Previous', iconName = 'previous'},
	right = {title = 'Next', iconName = 'next'},
}

---@class CarouselButtonWidgetParameters
---@field direction 'left'|'right'
---@field classes string[]?

---Scroll control of a carousel. It has to be placed inside the `.carousel` element it controls.
---@param props CarouselButtonWidgetParameters
---@return VNode
local function CarouselButton(props)
	local config = assert(DIRECTIONS[props.direction], 'CarouselButton: invalid direction "' .. tostring(props.direction) .. '"')

	return Button{
		classes = Array.extend({'carousel-button', 'carousel-button--' .. props.direction}, props.classes),
		title = config.title,
		size = 'xs',
		children = Html.Span{
			css = {display = 'inline-flex'},
			children = IconWidget{iconName = config.iconName, size = 'xs'},
		},
	}
end

return Component.component(CarouselButton)
