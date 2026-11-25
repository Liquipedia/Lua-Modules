---
-- @Liquipedia
-- page=Module:Widget/Basic/Carousel/Content
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@class CarouselContentWidgetParameters
---@field children Renderable[]
---@field itemWidth string|false? `false` leaves the item width to stylesheets
---@field gap string?
---@field classes string[]?
---@field css table?

local defaultProps = {
	itemWidth = '200px',
	gap = '0.5rem',
}

---Scrollable item list of a carousel. It has to be placed inside a `.carousel` element.
---@param props CarouselContentWidgetParameters
---@return VNode
local function CarouselContent(props)
	assert(props.children, 'CarouselContent: children is required')
	assert(Array.isArray(props.children), 'CarouselContent: children must be an array')

	return Div{
		classes = Array.extend({'carousel-content'}, props.classes),
		css = Table.mergeInto({gap = props.gap}, props.css),
		children = Array.map(props.children, function(child)
			return Div{
				classes = {'carousel-item'},
				css = props.itemWidth and {width = props.itemWidth} or nil,
				children = {child},
			}
		end),
	}
end

return Component.component(CarouselContent, defaultProps)
