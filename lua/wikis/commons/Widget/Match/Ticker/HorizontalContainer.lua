---
-- @Liquipedia
-- page=Module:Widget/Match/Ticker/HorizontalContainer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local I18n = Lua.import('Module:I18n')

local Carousel = Lua.import('Module:Widget/Basic/Carousel')
local Switch = Lua.import('Module:Widget/Switch')
local Html = Lua.import('Module:Widget/Html')

local TABLE_OF_CONTENTS = '__TOC__'

---@param props {children: Renderable[]}
---@return Renderable
local function HorizontalContainer(props)
	local carousel = Carousel{
		children = props.children,
		itemWidth = '12.5rem',
		gap = '0.5rem',
	}

	return Html.Div{
		css = {['margin-bottom'] = '1rem'},
		children = {
			Html.Div{
				classes = {'mw-heading', 'mw-heading2'},
				children = {
					Html.H2{
						css = {border = 'unset'},
						children = I18n.translate('matchticker-upcoming-matches'),
					},
				},
			},
			Switch{
				label = 'Show countdown',
				switchGroup = 'countdown',
				storeValue = true,
				defaultActive = true,
				css = {margin = '0.75rem 0 1rem'},
				content = carousel,
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
