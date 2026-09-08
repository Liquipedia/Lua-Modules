---
-- @Liquipedia
-- page=Module:Widget/MainPage/WantToHelp
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Page = Lua.import('Module:Page')
local Variables = Lua.import('Module:Variables')
local I18n = Lua.import('Module:I18n')

local Info = Lua.import('Module:Info', {loadData = true})

local Component = Lua.import('Module:Widget/Component')
local Builder = Lua.import('Module:Widget/Builder')
local Button = Lua.import('Module:Widget/Basic/Button')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Link = Lua.import('Module:Widget/Basic/Link')
local WantToHelpList = Lua.import('Module:Widget/WantToHelpList')
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

---@return string
local function getWikiName()
	if Info.wikiName == 'formula1' then
		return 'F1'
	end
	return Info.name
end

---@param content Renderable|Renderable[]?
---@return VNode
local function showWhenLoggedOut(content)
	return Div{
		classes = {'show-when-logged-out'},
		children = content
	}
end

---@return VNode[]
local function WantToHelp()
	return {
		Div{
			css = {['padding-bottom'] = '0.7em'},
			children = I18n.translate(
				'wantToHelp-mainText',
				{
					wikiType = getWikiName(),
				}
			)
		},
		buildFontAwesomeList(
			GREEN_CHECK_CIRCLE,
			{
				{I18n.translate('wantToHelp-checkA')},
				{I18n.translate('wantToHelp-checkB')},
				{I18n.translate('wantToHelp-checkC')},
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
					title = I18n.translate('wantToHelp-button-create-tooltip'),
					variant = 'secondary',
					children = {
						IconFa{iconName = 'createaccount'},
						I18n.translate('wantToHelp-button-create-title')
					}
				}),
				showWhenLoggedOut(Button{
					link = I18n.translate('wantToHelp-button-logIn-link'),
					title = I18n.translate('wantToHelp-button-logIn-tooltip'),
					variant = 'secondary',
					children = {
						IconFa{iconName = 'login'},
						I18n.translate('wantToHelp-button-logIn-title')
					}
				}),
				Button{
					link = 'https://discord.gg/liquipedia',
					linktype = 'external',
					title = I18n.translate('wantToHelp-button-discord-tooltip'),
					variant = 'secondary',
					children = {
						IconFa{iconName = 'discord'},
						I18n.translate('wantToHelp-button-discord-title')
					}
				},
				Page.exists(I18n.translate('wantToHelp-helpArticles-link')) and Button{
					link = I18n.translate('wantToHelp-helpArticles-link'),
					title = I18n.translate('wantToHelp-helpArticles-tooltip'),
					variant = 'secondary',
					children = {
						IconFa{iconName = 'helparticles'},
						I18n.translate('wantToHelp-helpArticles-title')
					}
				} or nil
			)
		},
		Html.Hr{
			css = {['margin-top'] = '1em'}
		},
		Div{
			css = {
				['line-height'] = '2em',
				['margin-top'] = '1em'
			},
			children = {'\n', WantToHelpList{}}
		},
		Html.Br{},
		I18n.translate('wantToHelp-articleCount-preLink'),
		Builder{builder = function () -- need the builder so the var is available when accessing it
			return Link{
				link = 'Liquipedia:Want to help/All',
				children = {Variables.varDefault('total_number_of_todos', 0) .. I18n.translate('wantToHelp-articleCount-pages')}
			}
		end},
		I18n.translate('wantToHelp-articleCount-postLink')
	}
end

return Component.component(WantToHelp)
