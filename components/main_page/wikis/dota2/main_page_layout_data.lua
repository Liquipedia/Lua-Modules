---
-- @Liquipedia
-- wiki=dota2
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DateExt = require('Module:Date/Ext')
local Lua = require('Module:Lua')

local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')
local MatchTickerContainer = Lua.import('Module:Widget/Match/Ticker/Container')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')
local WidgetUtil = Lua.import('Module:Widget/Util')

local CONTENT = {
	aboutMain = {
		heading = 'About Liquipedia’s Dota 2 Wiki',
		body = 'We are the largest Dota 2 wiki that anyone can edit, maintained by fans just like you. ' ..
			'This wiki currently covers esports and game content, containing over {{NUMBEROFARTICLES}} ' ..
			'articles managed by {{NUMBEROFACTIVEUSERS}} active users.' ..
			'<div style="display:flex; flex-wrap: wrap; gap:12px; justify-content:center; padding-top: 12px;">' ..
			'{{button|text=View Esports Hub|title=Click here to get to the esports hub|internallink=Portal:Esports' ..
			'|icon=fa-external-link-alt wiki-color-dark|new=true|secondary=true}}' ..
			'{{button|text=View Game Hub|title=Click here to get to the game hub|internallink=Portal:Game' ..
			'|icon=fa-external-link-alt wiki-color-dark|new=true|secondary=true}}' ..
			'</div>',
		padding = true,
		boxid = 1500,
	},
	aboutEsport = {
		heading = 'About Liquipedia’s Dota 2 Wiki',
		body = 'We are the largest Dota 2 wiki that anyone can edit, maintained by fans just like you. ' ..
			'This wiki currently covers esports and game content, containing over {{NUMBEROFARTICLES}} ' ..
			'articles managed by {{NUMBEROFACTIVEUSERS}} active users.' ..
			'<div style="display:flex; flex-wrap: wrap; gap:12px; justify-content:center; padding-top: 12px;">' ..
			'{{button|text=View Main Page|title=Click here to get to the main page|internallink=Main_Page' ..
			'|icon=fa-external-link-alt wiki-color-dark|new=true|secondary=true}}' ..
			'{{button|text=View Game Hub|title=Click here to get to the game hub|internallink=Portal:Game' ..
			'|icon=fa-external-link-alt wiki-color-dark|new=true|secondary=true}}' ..
			'</div>',
		padding = true,
		boxid = 1500,
	},
	aboutGame = {
		heading = 'About Liquipedia’s Dota 2 Wiki',
		body = 'We are the largest Dota 2 wiki that anyone can edit, maintained by fans just like you. ' ..
			'This wiki currently covers esports and game content, containing over {{NUMBEROFARTICLES}} ' ..
			'articles managed by {{NUMBEROFACTIVEUSERS}} active users.' ..
			'<div style="display:flex; flex-wrap: wrap; gap:12px; justify-content:center; padding-top: 12px;">' ..
			'{{button|text=View Main Page|title=Click here to get to the main page|internallink=Main_Page' ..
			'|icon=fa-external-link-alt wiki-color-dark|new=true|secondary=true}}' ..
			'{{button|text=View Esports Hub|title=Click here to get to the esports hub|internallink=Portal:Esports' ..
			'|icon=fa-external-link-alt wiki-color-dark|new=true|secondary=true}}' ..
			'</div>',
		padding = true,
		boxid = 1500,
	},
	heroes = {
		heading = 'Heroes',
		body = '<div class="heroes-panel" data-component="heroes-panel">{{HeroTable}}</div>',
		padding = true,
		boxid = 1501,
	},
	updates = {
		heading = 'Updates',
		body = '<nowiki>\n</nowiki>{{Main Page Updates}}',
		padding = true,
		boxid = 1502,
	},
	usefulArticles = {
		heading = 'Useful Articles',
		body = '{{Main Page Useful Articles}}',
		padding = true,
		boxid = 1503,
	},
	wantToHelp = {
		heading = 'Want To Help?',
		body = '{{Liquipedia:Want_to_help}}',
		padding = true,
		boxid = 1504,
	},
	transfers = {
		heading = 'Transfers',
		body = TransfersList{
			transferPage = function ()
				return 'Transfers/' .. os.date('%Y') .. '/' .. DateExt.quarterOf{ ordinalSuffix = true } .. ' Quarter'
			end
		},
		boxid = 1509,
	},
	thisDay = {
		heading = ThisDayWidgets.Title(),
		body = ThisDayWidgets.Content{ birthdayListPage = 'Birthday list' },
		padding = true,
		boxid = 1510,
	},
	specialEvents = {
		noPanel = true,
		body = '{{Liquipedia:Special Event}}',
	},
	filterButtons = {
		noPanel = true,
		body = Div{
			css = { width = '100%', ['margin-bottom'] = '8px' },
			children = { FilterButtonsWidget() }
		}
	},
	matches = {
		heading = 'Matches',
		body = WidgetUtil.collect(
			MatchTickerContainer{},
			Div{
				css = {
					['white-space'] = 'nowrap',
					display = 'block',
					margin = '0 10px',
					['font-size'] = '15px',
					['font-style'] = 'italic',
					['text-align'] = 'center',
				},
				children = { Link{ children = 'See more matches', link = 'Liquipedia:Matches'} }
			}
		),
		padding = true,
		boxid = 1507,
		panelAttributes = {
			['data-switch-group-container'] = 'countdown',
		},
	},
	tournaments = {
		heading = 'Tournaments',
		body = TournamentsTicker{
			upcomingDays = 30,
			completedDays = 20
		},
		padding = true,
		boxid = 1508,
	},
}

local LAYOUT_MAIN = {
	{ -- Left
		size = 6,
		children = {
			{
				mobileOrder = 1,
				content = CONTENT.aboutMain,
			},
			{
				mobileOrder = 4,
				content = CONTENT.heroes,
			},
			{
				mobileOrder = 5,
				content = CONTENT.updates,
			},
			{
				mobileOrder = 9,
				content = CONTENT.usefulArticles,
			},
			{
				mobileOrder = 7,
				content = CONTENT.wantToHelp,
			},
		},
	},
	{ -- Right
		size = 6,
		children = {
			{
				mobileOrder = 2,
				content = CONTENT.specialEvents
			},
			{
				mobileOrder = 3,
				children = {
					{
						children = {
							{
								noPanel = true,
								content = CONTENT.filterButtons,
							},
						},
					},
					{
						size = 6,
						children = {
							{
								noPanel = true,
								content = CONTENT.matches,
							},
						},
					},
					{
						size = 6,
						children = {
							{
								noPanel = true,
								content = CONTENT.tournaments,
							},
						},
					},
				},
			},
			{
				mobileOrder = 6,
				content = CONTENT.transfers,
			},
			{
				mobileOrder = 9,
				content = CONTENT.thisDay,
			},
		},
	},
}

local LAYOUT_ESPORTS = {
	{ -- Left
		size = 6,
		children = {
			{
				mobileOrder = 1,
				content = CONTENT.aboutEsport,
			},
			{
				mobileOrder = 2,
				content = CONTENT.specialEvents,
			},
			{
				mobileOrder = 4,
				content = CONTENT.transfers,
			},
			{
				mobileOrder = 6,
				content = CONTENT.thisDay,
			},
			{
				mobileOrder = 7,
				content = CONTENT.wantToHelp,
			},
		}
	},
	{ -- Right
		size = 6,
		children = {
			{
				mobileOrder = 3,
				children = {
					{
						children = {
							{
								noPanel = true,
								content = CONTENT.filterButtons,
							},
						},
					},
					{
						size = 6,
						children = {
							{
								noPanel = true,
								content = CONTENT.matches,
							},
						},
					},
					{
						size = 6,
						children = {
							{
								noPanel = true,
								content = CONTENT.tournaments,
							},
						},
					},
				},
			},
			{
				mobileOrder = 5,
				content = CONTENT.updates,
			},
		},
	},
}

local LAYOUT_GAME = {
	{ -- Left
		size = 6,
		children = {
			{
				mobileOrder = 1,
				content = CONTENT.aboutGame,
			},
			{
				mobileOrder = 2,
				content = CONTENT.heroes,
			},
			{
				mobileOrder = 6,
				content = CONTENT.wantToHelp,
			},
		},
	},
	{ -- Right
		size = 6,
		children = {
			{
				mobileOrder = 3,
				content = CONTENT.updates
			},
			{
				mobileOrder = 4,
				content = CONTENT.thisDay,
			},
			{
				mobileOrder = 5,
				content = CONTENT.usefulArticles,
			},
		},
	},
}

return {
	banner = {
		lightmode = 'Dota2logo-light-theme.svg',
		darkmode = 'Dota2logo-dark-theme.svg',
	},
	metadesc = 'Comprehensive Dota 2 wiki with articles covering everything from heroes and items, to strategies, ' ..
		'to tournaments, to competitive players, and teams.',
	title = 'The Dota 2 Wiki',
	navigation = {
		{
			file = 'Morphling_Large.png',
			title = 'Heroes',
			link = 'Heroes',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::hero]] and [[extradata_game::]]',
			},
		},
		{
			file = 'Blink_Dagger Large.png',
			title = 'Items',
			link = 'Items',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::item]]',
			},
		},
		{
			file = 'Dota 2 Rune Arcane preview.png',
			title = 'Mechanics',
			link = 'Mechanics',
			count = {
				method = 'CATEGORY',
				category = 'Mechanics',
			},
		},
		{
			file = 'Main Page Dota 2 Cosmetics.jpg',
			title = 'Cosmetics',
			link = 'Cosmetics',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::cosmetic_item]]',
			},
		},
		{
			file = 'Neutral map.jpg',
			title = 'Updates',
			link = 'Updates',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::version]]',
			},
		},
		{
			file = 'The International 2016.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'Team_Spirit_win_The_International_2023.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = '7ckngMad_EPICENTER_Major_2019.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'Team_Liquid_The_International_2023.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
	},
	layouts = {
		main = LAYOUT_MAIN,
		esports = LAYOUT_ESPORTS,
		game = LAYOUT_GAME,
	},
}
