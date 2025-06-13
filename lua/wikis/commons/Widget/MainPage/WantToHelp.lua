---
-- @Liquipedia
-- page=Module:Widget/MainPage/WantToHelp
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Page = Lua.import('Module:Page')
local Variables = Lua.import('Module:Variables')

local Info = Lua.import('Module:Info', {loadData = true})

local Widget = Lua.import('Module:Widget')
local Builder = Lua.import('Module:Widget/Builder')
local Button = Lua.import('Module:Widget/Basic/Button')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Link = Lua.import('Module:Widget/Basic/Link')
local WantToHelpList = Lua.import('Module:Widget/WantToHelpList')
local WidgetUtil = Lua.import('Module:Widget/Util')

local GREEN_CHECK_CIRCLE = IconFa{
	iconName = 'checkcircle',
	color = 'forest-green-non-text',
	size = 'lg',
}

---@class WantToHelp: Widget
---@operator call(table): WantToHelp
local WantToHelp = Class.new(Widget)

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

---@return string
local function getWikiType()
	if Info.wikiName == 'formula1' then
		return 'F1'
	end
	return 'esports'
end

---@param content Widget?
---@return Widget
local function showWhenLoggedOut(content)
	return Div{
		classes = {'show-when-logged-out'},
		children = content
	}
end

---@return Widget[]
function WantToHelp:render()
	return {
		Div{
			css = {['padding-bottom'] = '0.7em'},
			children = 'Create your free account and join the community to start making a difference by ' ..
					'sharing your knowledge and insights with fellow ' .. getWikiType() ..
					' fans!'
		},
		buildFontAwesomeList(
			GREEN_CHECK_CIRCLE,
			{
				{'Join our community and grow the scene(s) you care about.'},
				{'Be a hero for fans worldwide by keeping the site updated.'},
				{'Develop valuable skills in research, writing, and collaboration.'},
			},
			{
				margin = '0 0 0 2.5rem',
				['line-height'] = '2.2em'
			}
		),
		Div{
			css = {
				display = 'flex',
				['flex-wrap'] = 'wrap',
				gap = '12px',
				['justify-content'] = 'center'
			},
			children = WidgetUtil.collect(
				showWhenLoggedOut(Button{
					link = 'https://tl.net/mytlnet/register?utm_source=Liquipedia&utm_medium=Website' ..
						'&utm_campaign=Want+to+Help+' .. mw.uri.encode(mw.site.siteName) .. '&utm_id=Want+to+Help',
					linktype = 'external',
					title = 'Click here to create an account',
					children = {
						IconFa{iconName = 'createaccount'},
						' Create Account'
					}
				}),
				showWhenLoggedOut(Button{
					link = 'Special:UserLogin',
					title = 'Click here to log in',
					variant = 'secondary',
					children = {
						IconFa{iconName = 'login'},
						' Log In'
					}
				}),
				Button{
					link = 'https://discord.gg/liquipedia',
					linktype = 'external',
					title = 'Click here to join our discord server',
					variant = 'secondary',
					children = {
						IconFa{iconName = 'discord'},
						' Join Our Discord'
					}
				},
				Page.exists('Help:Contents') and Button{
					link = 'Help:Contents',
					title = 'Click Here to Read our Help Articles',
					variant = 'secondary',
					children = {
						IconFa{iconName = 'helparticles'},
						' Help Articles'
					}
				} or nil
			)
		},
		HtmlWidgets.Hr{
			css = {['margin-top'] = '1em'}
		},
		Div{
			css = {
				['line-height'] = '2em',
				['margin-top'] = '1em'
			},
			children = {'\n', WantToHelpList{}}
		},
		HtmlWidgets.Br{},
		'In total there are ',
		Builder{builder = function () -- need the builder so the var is available when accessing it
			return Link{
				link = 'Liquipedia:Want to help/All',
				children = {Variables.varDefault('total_number_of_todos', 0) .. ' pages'}
			}
		end},
		' listed needing help.'
	}
end

return WantToHelp
