---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/MainPage/LiquipediaApp
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Lua = require('Module:Lua')

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
	additionalCss = {
		['margin-left'] = '-0.1em',
		['margin-right'] = '0.3em'
	}
}

---@class LiquipediaApp: Widget
---@operator call(table): LiquipediaApp
local LiquipediaApp = Class.new(Widget)

---@param entries (string|Html|Widget|nil|(string|Html|Widget|nil)[])[][]
---@return Widget
function LiquipediaApp._buildDescriptionList(entries)
	return HtmlWidgets.Dl{
		children = Array.map(entries, function (entry)
			return HtmlWidgets.Dd{
				children = WidgetUtil.collect(
					GREEN_CHECK_CIRCLE,
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
				Div{
					css = { ['line-height'] = '2.2em' },
					children = LiquipediaApp._buildDescriptionList{
						{
							'Follow your favorite ',
							Info.name,
							' players and teams!'
						},
						{
							'Get notifications and never miss a match again.'
						},
						{
							'Available in ',
							Array.interleave(Array.map({'ru', 'br', 'fr', 'es', 'cn', 'de', 'jp'}, function (country)
								return Flags.Icon{shouldLink = false, flag = country}
							end), ' '),
							' and 12 more languages!'
						},
						{
							'Spoiler-free version.'
						}
					}
				}
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
