---
-- @Liquipedia
-- page=Module:Widget/Basic/Carousel
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local CarouselButton = Lua.import('Module:Widget/Basic/Carousel/Button')
local CarouselContent = Lua.import('Module:Widget/Basic/Carousel/Content')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@class CarouselWidgetParameters
---@field children Renderable[]
---@field itemWidth string?
---@field gap string?
---@field classes string[]?
---@field css table?

local defaultProps = {
	itemWidth = '200px',
	gap = '0.5rem',
}

---@param props CarouselWidgetParameters
---@return HtmlNode
local function Carousel(props)
	assert(props.children, 'Carousel: children is required')
	assert(Array.isArray(props.children), 'Carousel: children must be an array')

	return Div{
		classes = Array.extendWith({'carousel'}, props.classes),
		children = {
			CarouselButton{direction = 'left'},
			CarouselButton{direction = 'right'},
			Div{classes = {'carousel-fade', 'carousel-fade--left'}},
			Div{classes = {'carousel-fade', 'carousel-fade--right'}},
			CarouselContent{
				children = props.children,
				itemWidth = props.itemWidth,
				gap = props.gap,
				css = props.css,
			},
		},
	}
end

return Component.component(Carousel, defaultProps)
