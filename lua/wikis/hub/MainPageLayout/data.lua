---
-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Link = Lua.import('Module:Widget/Basic/Link')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Li = HtmlWidgets.Li
local Ul = HtmlWidgets.Ul

local CONTENT = {
	contribute = {
		heading = 'Want to Contribute?',
		body = Ul{children = {
			Li{
				children = HtmlWidgets.B{children = Link{
					link = 'Support/Getting started',
					children = 'Getting started'
				}}
			},
			Li{children = Link{
				link = 'https://tl.net/mytlnet/register',
				children = 'Create an account',
				linktype = 'external',
			}},
			Li{children = Link{
				link = 'lpcommons:Main Page',
				children = 'Liquipedia Commons',
			}},
			Li{children = Link{
				link = 'Support',
			}},
			Li{children = Link{
				link = 'lpcommons:Special:NewFiles',
				children = 'Latest uploads',
			}},
		}},
		padding = true,
	},
	liquipedia = {
		heading = 'Liquipedia',
		body = HtmlWidgets.Fragment{children = {
			Ul{children = {
				Li{children = Link{
					link = 'Support/Liquipedia',
					children = 'Liquipedia',
				}},
				Li{children = Link{
					link = 'Liquipedia:Alpha Wikis Program',
					children = 'Starting a new wiki',
				}},
				Li{children = Link{
					link = 'Liquipedia:Policy',
					children = 'Policies',
				}},
				Li{children = Link{
					link = 'Community Showcase',
					children = 'Community Showcase',
				}},
			}},
			HtmlWidgets.Br{classes = {'mobile-hide'}},
		}},
		padding = true,
	},
	dev = {
		heading = 'LP Dev',
		body = HtmlWidgets.Fragment{children = {
			Ul{children = {
				Li{children = Link{
					link = 'Liquipedia:Changelogs',
					children = 'Dev updates',
				}},
			}},
			HtmlWidgets.Br{classes = {'mobile-hide'}},
			HtmlWidgets.Br{classes = {'mobile-hide'}},
			HtmlWidgets.Br{classes = {'mobile-hide'}},
		}},
		padding = true,
	},
	contact = {
		heading = 'Contact',
		body = HtmlWidgets.Fragment{children = {
			Ul{children = {
				Li{
					children = HtmlWidgets.B{children = Link{
						link = 'https://discord.gg/liquipedia',
						children = 'Join our Discord',
						linktype = 'external',
					}},
				},
				Li{children = Link{
					link = 'Support/Using our Discord server',
					children = 'Using our Discord server',
				}},
				Li{children = Link{
					link = 'Contact',
				}},
			}},
			HtmlWidgets.Br{classes = {'mobile-hide'}},
		}},
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
						content = CONTENT.contribute,
					},
				}
			},
			{
				size = 3,
				children = {
					{
						mobileOrder = 2,
						content = CONTENT.liquipedia,
					},
				}
			},
			{
				size = 3,
				children = {
					{
						mobileOrder = 3,
						content = CONTENT.dev,
					},
				}
			},
			{
				size = 3,
				children = {
					{
						mobileOrder = 4,
						content = CONTENT.contact,
					},
				}
			},
		},
	},
}
