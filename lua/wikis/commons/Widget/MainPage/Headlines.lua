---
-- @Liquipedia
-- page=Module:Widget/MainPage/Headlines
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local ExternalMediaList = Lua.import('Module:ExternalMediaList')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local ListWidgets = Lua.import('Module:Widget/List')
local WidgetUtil = Lua.import('Module:Widget/Util')

local defaultProps = {
	headlinesPortal = 'Portal:News',
	limit = 4,
}

---@param props { headlinesPortal: string?, limit: integer? }
---@return Renderable[]
local function Headlines(props)
	assert(props.limit > 0, 'Invalid limit')
	return WidgetUtil.collect(
		ExternalMediaList.get{ subject = '!', limit = props.limit },
		Html.Hr{},
		Div{
			classes = {'hlist'},
			css = {
				['text-align'] = 'center',
				['font-style'] = 'italic',
			},
			children = ListWidgets.Unordered{
				children = {
					Link{ children = 'See all Headlines', link = props.headlinesPortal },
					Link{ children = 'Add a Headline', link = 'Special:FormEdit/ExternalMediaLinks' }
				}
			}
		}
	)
end

return Component.component(Headlines, defaultProps)
