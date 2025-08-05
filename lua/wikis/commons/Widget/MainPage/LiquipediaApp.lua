---
-- @Liquipedia
-- page=Module:Widget/MainPage/LiquipediaApp
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')

local Info = Lua.import('Module:Info', {loadData = true})

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local WidgetUtil = Lua.import('Module:Widget/Util')

local GREEN_CHECK_CIRCLE = IconFa{
	iconName = 'checkcircle',
	color = 'forest-green-non-text',
	size = 'lg',
}

---@class LiquipediaApp: Widget
---@operator call(table): LiquipediaApp
local LiquipediaApp = Class.new(Widget)

---@param icon string|Html|Widget
---@param entries (string|Html|Widget|nil|(string|Html|Widget|nil)[])[][]
---@param listCss table<string, string?>?
---@return Widget
local function buildFontAwesomeList(icon, entries, listCss)
	return HtmlWidgets.Ul{
		classes = {'fa-ul'},
		css = listCss,
		children = Array.map(entries, function (entry)
			return HtmlWidgets.Li{
				children = WidgetUtil.collect(
					HtmlWidgets.Span{
						classes = {'fa-li'},
						children = icon
					},
					unpack(entry)
				)
			}
		end)
	}
end

---@return Widget[]
function LiquipediaApp:render()
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
						{
							'Available in ',
							Array.interleave(Array.map({'ru', 'br', 'fr', 'es', 'cn', 'de', 'jp'}, function (country)
								return Flags.Icon{shouldLink = false, flag = country}
							end), ' '),
							' and 12 more languages!'
						},
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

return LiquipediaApp
