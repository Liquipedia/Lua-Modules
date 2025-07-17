---
-- @Liquipedia
-- wiki=hub
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local LiquipediaApp = Lua.import('Module:Widget/MainPage/LiquipediaApp')
local MatchTicker = Lua.import('Module:Widget/MainPage/MatchTicker')
local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')

local CONTENT = {
	supporthub1 = {
		heading = 'Want to Contribute?',
		body = '\n*<b>[[Support/Getting_started|Getting started]]</b>\n*[https://tl.net/mytlnet/register Create an account]\n*[[Support]]\n*[[Special:NewFiles|Latest uploads]]\n',
		padding = true,
	},
	supporthub2 = {
		heading = 'Liquipedia',
		body = '\n*[[Support/Liquipedia|Liquipedia]]\n*[[Liquipedia:Alpha Wikis Program|Starting a new wiki]]\n*[[Liquipedia:Policy|Policies]]\n',
		padding = true,
	},
	supporthub3 = {
		heading = 'LP Dev',
		body = '\n*[[Liquipedia:Changelogs|Dev updates]]\n<br>\n\n',
		padding = true,
	},
	supporthub4 = {
		heading = 'Contact',
		body = '\n*<b>[https://discord.gg/liquipedia Join our Discord]</b>\n*[[Support/Using_our_Discord_server|Using our Discord]]\n*[[Contact]]\n',
		padding = true,
	},
}

return {
	banner = {
		lightmode = 'Hub-light-theme.svg',
		darkmode = 'Hub-dark-theme.svg',
	},
	metadesc = '',
	title = 'Hub',
	navigation = {
		{
			iconName = 'getting_started',
			title = 'Getting Started',
			link = 'Support/Getting_started',
			count = {},
		},
		{
			iconName = 'upload',
			title = 'Upload an image',
			link = 'lpcommons:Special:Upload',
			count = {},
		},
		{
			iconName = 'support_hub',
			title = 'Support',
			link = 'Support',
			count = {},
		},
		{
			iconName = 'copyright',
			title = 'Copyright Guide',
			link = 'A_Liquipedia_Guide_to_Copyright',
			count = {},
		},
		{
			iconName = 'file_standards_guide',
			title = 'File Standards Guide',
			link = 'File Standards Guide',
			count = {},
		},
	},
	layouts = {
		main = {
			{
				size = 3,
				children = {
					{
						mobileOrder = 1,
						content = CONTENT.supporthub1,
					},
				}
			},
			{
				size = 3,
				children = {
					{
						mobileOrder = 2,
						content = CONTENT.supporthub2,
					},
				}
			},
			{
				size = 3,
				children = {
					{
						mobileOrder = 3,
						content = CONTENT.supporthub3,
					},
				}
			},
			{
				size = 3,
				children = {
					{
						mobileOrder = 4,
						content = CONTENT.supporthub4,
					},
				}
			},
		},
	},
}
