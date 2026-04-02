---
-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MainPageLayoutUtil = Lua.import('Module:MainPageLayout/Util')

local WantToHelp = Lua.import('Module:Widget/MainPage/WantToHelp')

local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker/List')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

local CONTENT = {
	about = {
		heading = 'About Wildcard',
		body = '<b>Wildcard</b> is a third-person, 2v2 Collectible Card Action Game (CCAG) that ' ..
		'seamlessly blends fast-paced arena combat with strategic deck-building. As a champion, you battle ' ..
		'in real-time, summoning powerful creature-companions from your deck to fight alongside you. Master ' ..
		'dynamic abilities, outplay opponents with skillful action mechanics, and harness the power of your ' ..
		'summons in a thrilling fusion of collectible card strategy and third-person action combat.',
		padding = true,
		boxid = 1502,
	},
	updates = {
		heading = 'Updates',
		body = '{{Main Page Updates}}',
		padding = true,
		boxid = 1502,
	},
	usefulArticles = {
		heading = 'Useful Articles',
		body = '{{Liquipedia:Useful Articles}}',
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.USEFUL_ARTICLES,
	},
	wantToHelp = {
		heading = 'Want To Help?',
		body = WantToHelp{},
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.WANT_TO_HELP,
	},
	champions = {
		heading = 'Champions',
		body = '{{Liquipedia:championTable}}',
		padding = true,
		boxid = 1501,
	},
	wildcards = {
		heading = 'Wild Cards',
		body = '{{Liquipedia:Wild Cards}}',
		padding = true,
		boxid = 1513,
	},
	houses = {
		heading = 'Houses',
		body = '{{Liquipedia:Houses}}',
		padding = true,
		boxid = 1514,
	},
	summons = {
		heading = 'Summons',
		body = '{{SummonIconTable}}',
		padding = true,
		boxid = 1515,
	},
	filterButtons = {
		noPanel = true,
		body = Div{
			css = { width = '100%', ['margin-bottom'] = '8px' },
			children = { FilterButtonsWidget() }
		}
	},
	tournaments = {
		heading = 'Tournaments',
		body = TournamentsTicker{
			upcomingDays = 30,
			completedDays = 20,
			tierColorScheme = 'top3',
			variant = 'collapsible',
		},
		padding = false,
		boxid = MainPageLayoutUtil.BoxId.TOURNAMENTS_TICKER,
	},
}

return {
	banner = {
		lightmode = 'Wildcard full lightmode.svg',
		darkmode = 'Wildcard full darkmode.svg',
	},
	metadesc = 'Comprehensive Wildcard wiki with articles covering everything from champions and summons, ' ..
		'to strategies, to tournaments, to competitive players, and teams.',
	title = 'The Wildcard Wiki',
	navigation = {
		{
			file = 'Wildcard header Wildcards.webp',
			title = 'Wild Cards',
			link = 'Portal:Wild Cards',
		},
		{
			file = 'Wildcard header Champions.webp',
			title = 'Champions',
			link = 'Portal:Champions',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::character]]',
			},
		},
		{
			file = 'Wildcard header Summons.webp',
			title = 'Summons',
			link = 'Portal:Summons',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::Summon]]',
			},
		},
		{
			file = 'Wildcard header Arenas.webp',
			title = 'Arenas',
			link = 'Portal:Arenas',
			count = {
				method = 'CATEGORY',
				category = 'Maps',
			},
		},
		{
			file = 'Wildcard header Mechanics.webp',
			title = 'Mechanics',
			link = 'Portal:Mechanics',
		},
		{
			file = 'Wildcard header Decks.webp',
			title = 'Decks',
			link = 'Portal:Decks',
		},
	},
	layouts = {
		main = {
			{ -- Left
				sizes = {xxl = 5, xxxl = 6},
				children = {
					{
						mobileOrder = 1,
						content = CONTENT.about,
					},
					{
						mobileOrder = 2,
						content = CONTENT.champions,
					},
					{
						mobileOrder = 3,
						content = CONTENT.summons,
					},
					{
						mobileOrder = 5,
						content = CONTENT.wantToHelp,
					},
				}
			},
			{ -- Right
				sizes = {xxl = 7, xxxl = 6},
				children = {
					{
						mobileOrder = 4,
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
						content = CONTENT.wildcards,
					},
					{
						mobileOrder = 6,
						content = CONTENT.houses,
					},
					{
						mobileOrder = 7,
						content = CONTENT.updates,
					},
					{
						mobileOrder = 8,
						content = CONTENT.usefulArticles,
					},
				},
			},
		},
	},
}
