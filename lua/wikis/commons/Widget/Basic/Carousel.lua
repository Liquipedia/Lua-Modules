---
-- @Liquipedia
-- page=Module:Widget/Basic/Carousel
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Button = Lua.import('Module:Widget/Basic/Button')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local Span = Html.Span

---@class CarouselWidgetParameters
---@field children Renderable[]
---@field itemWidth string?
---@field gap string?
---@field classes string[]?
---@field css table?

---@class CarouselWidget
local Carousel = {}
Carousel.defaultProps = {
	itemWidth = '200px',
	gap = '0.5rem',
}

---@param props CarouselWidgetParameters
---@return HtmlNode
function Carousel.render(props)
	assert(props.children, 'Carousel: children is required')
	assert(Array.isArray(props.children), 'Carousel: children must be an array')

	local carouselCss = Table.mergeInto({
		gap = props.gap,
	}, props.css)

	local carouselContent = Div{
		classes = {'carousel-content'},
		css = carouselCss,
		children = Array.map(props.children, function(child)
			return Div{
				classes = {'carousel-item'},
				css = {
					width = props.itemWidth,
				},
				children = {child},
			}
		end),
	}

	local leftButton = Button{
		classes = {'carousel-button', 'carousel-button--left'},
		title = 'Previous',
		size = 'xs',
		children = {
			Span{
				css = {display = 'inline-flex'},
				children = {IconWidget{iconName = 'previous', size = 'xs'}}
			},
		},
	}

	local rightButton = Button{
		classes = {'carousel-button', 'carousel-button--right'},
		title = 'Next',
		size = 'xs',
		children = {
			Span{
				css = {display = 'inline-flex'},
				children = {IconWidget{iconName = 'next', size = 'xs'}}
			},
		},
	}

	local leftFade = Div{classes = {'carousel-fade', 'carousel-fade--left'}}
	local rightFade = Div{classes = {'carousel-fade', 'carousel-fade--right'}}

	return Div{
		classes = Array.extend({'carousel'}, props.classes),
		children = {
			leftButton,
			rightButton,
			leftFade,
			rightFade,
			carouselContent,
		},
	}
end

return Component.component(Carousel.render, Carousel.defaultProps)
