---
-- @Liquipedia
-- page=Module:Widget/Match/Ticker/HorizontalContainer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local I18n = Lua.import('Module:I18n')

local CarouselButton = Lua.import('Module:Widget/Basic/Carousel/Button')
local CarouselContent = Lua.import('Module:Widget/Basic/Carousel/Content')
local Html = Lua.import('Module:Widget/Html')
local Switch = Lua.import('Module:Widget/Switch')

local TABLE_OF_CONTENTS = '__TOC__'

---@param props {children: Renderable[]}
---@return Renderable
local function HorizontalContainer(props)
	return Html.Div{
		classes = {'match-ticker-horizontal-container'},
		attributes = {
			['data-switch-group-container'] = 'countdown',
			-- Groups started matches as live
			['data-match-ticker-type'] = 'upcoming',
		},
		children = {
			Html.Div{
				classes = {'mw-heading', 'mw-heading2', 'match-ticker-horizontal-container__heading'},
				children = {
					Html.H2{children = I18n.translate('matchticker-upcoming-matches')},
					Switch{
						label = 'Show countdown',
						switchGroup = 'countdown',
						storeValue = true,
						defaultActive = true,
					},
				},
			},
			Html.Div{
				classes = {'carousel'},
				children = {
					CarouselButton{direction = 'left'},
					CarouselButton{direction = 'right'},
					Html.Div{classes = {'carousel-fade', 'carousel-fade--left'}},
					Html.Div{classes = {'carousel-fade', 'carousel-fade--right'}},
					CarouselContent{
						classes = {'match-ticker-carousel'},
						children = props.children,
						itemWidth = false,
						gap = '0',
					},
				},
			},
			Html.Div{
				css = {['margin-top'] = '1rem'},
				children = {
					TABLE_OF_CONTENTS,
				},
			},
		},
	}
end

return Component.component(HorizontalContainer)
