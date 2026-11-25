---
-- @Liquipedia
-- page=Module:Widget/MainPage/LiquipediaApp
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Flags = Lua.import('Module:Flags')

local Info = Lua.import('Module:Info', {loadData = true})

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local WidgetUtil = Lua.import('Module:Widget/Util')

local GREEN_CHECK_CIRCLE = IconFa{
	iconName = 'checkcircle',
	color = 'forest-green-non-text',
	size = 'lg',
}

---@param icon Renderable
---@param entries (Renderable|Renderable[])[]
---@param listCss table<string, string?>?
---@return VNode
local function buildFontAwesomeList(icon, entries, listCss)
	return Html.Ul{
		classes = {'fa-ul'},
		css = listCss,
		children = Array.map(entries, function (entry)
			return Html.Li{
				children = WidgetUtil.collect(
					Html.Span{
						classes = {'fa-li'},
						children = icon
					},
					entry
				)
			}
		end)
	}
end

---@return VNode[]
local function LiquipediaApp()
	return {
		Div{
			css = {
				display = 'Flex',
				['justify-content'] = 'left',
				padding = '0px',
			},
			children = {
				Div{
					classes = { 'mobile-hide' },
					children = {IconImage{
						imageLight = 'Qr-code-app.svg',
						size = '132px',
						link = ''
					}}
				},
				buildFontAwesomeList(
					GREEN_CHECK_CIRCLE,
					{
						{
							'Follow your favorite ',
							Info.name,
							' players and teams!'
						},
						{'Get notifications and never miss a match again.'},
						WidgetUtil.collect(
							'Available in ',
							Array.interleave(Array.map({'ru', 'br', 'fr', 'es', 'cn', 'de', 'jp'}, function (country)
								return Flags.Icon{shouldLink = false, flag = country}
							end), ' '),
							' and 12 more languages!'
						),
						{'Spoiler-free version.'},
					},
					{
						margin = '0 0 0 2.5rem',
						['line-height'] = '2.2em'
					}
				)
			}
		},
		Div{
			css = {
				display = 'flex',
				['flex-wrap'] = 'wrap',
				gap = '12px',
				['justify-content'] = 'center',
				clear = 'both'
			},
			children = {
				IconImage{
					imageLight = 'App-store.svg',
					link = 'https://apps.apple.com/us/app/liquipedia-esports-tracker/id1640722331',
					size = '160px'
				},
				' ',
				IconImage{
					imageLight = 'Google-play.svg',
					link = 'https://play.google.com/store/apps/details?id=com.teamliquid.liquipedia.liquipedia_app',
					size = '160px'
				}
			}
		}
	}
end

return Component.component(LiquipediaApp)
