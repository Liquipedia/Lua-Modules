---
-- @Liquipedia
-- page=Module:Widget/MainPage/Headlines
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local ExternalMediaList = Lua.import('Module:ExternalMediaList')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local CenterDot = Lua.import('Module:Widget/MainPage/CenterDot')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class Headlines: Widget
---@field props { headlinesPortal: string?, limit: integer? }
---@operator call(table): Headlines
local Headlines = Class.new(Widget)
Headlines.defaultProps = {
	headlinesPortal = 'Portal:News',
	limit = 4,
}

---@return (Html|Widget)[]
function Headlines:render()
	assert(self.props.limit > 0, 'Invalid limit')
	return WidgetUtil.collect(
		ExternalMediaList.get{ subject = '!', limit = self.props.limit },
		Div{
			css = { display = 'block', ['text-align'] = 'center', padding = '0.5em', },
			children = {
				Div{
					css = {
						['white-space'] = 'nowrap',
						display = 'inline',
						margin = '0 10px',
						['font-size'] = '15px',
						['font-style'] = 'italic',
					},
					children = {
						Link{ children = 'See all Headlines', link = self.props.headlinesPortal },
						CenterDot(),
						Link{ children = 'Add a Headline', link = 'Special:FormEdit/ExternalMediaLinks' }
					}
				}
			}
		}
	)
end

return Headlines
