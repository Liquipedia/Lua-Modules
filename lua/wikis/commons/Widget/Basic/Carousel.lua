---
-- @Liquipedia
-- page=Module:Widget/Basic/Carousel
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Button = Lua.import('Module:Widget/Basic/Button')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span

---@class CarouselWidgetParameters
---@field children Renderable[]
---@field itemWidth string?
---@field gap string?
---@field classes string[]?
---@field css table?

---@class CarouselWidget: Widget
---@operator call(CarouselWidgetParameters): CarouselWidget
---@field props CarouselWidgetParameters
local Carousel = Class.new(Widget)
Carousel.defaultProps = {
	itemWidth = '200px',
	gap = '0.5rem',
	classes = {},
	css = {},
}

---@return Widget
function Carousel:render()
	assert(self.props.children, 'Carousel: children is required')
	assert(Array.isArray(self.props.children), 'Carousel: children must be an array')

	local carouselCss = Table.mergeInto({
		gap = self.props.gap,
	}, self.props.css)

	local carouselContent = Div{
		classes = {'carousel-content'},
		css = carouselCss,
		children = Array.map(self.props.children, function(child)
			return Div{
				classes = {'carousel-item'},
				css = {
					width = self.props.itemWidth,
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
		classes = Array.extend({'carousel'}, self.props.classes),
		children = {
			leftButton,
			rightButton,
			leftFade,
			rightFade,
			carouselContent,
		},
	}
end

return Carousel
