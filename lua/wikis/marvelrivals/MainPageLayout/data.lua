---
-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MainPageLayoutUtil = Lua.import('Module:MainPageLayout/Util')

local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local MatchTicker = Lua.import('Module:Widget/MainPage/MatchTicker')
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')
local WantToHelp = Lua.import('Module:Widget/MainPage/WantToHelp')

local CONTENT = {
	updates = {
		heading = 'Updates',
		body = '<nowiki>\n</nowiki>{{Main Page Updates}}',
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
	transfers = {
		heading = 'Transfers',
		body = TransfersList{
			rumours = true,
			transferPage = MainPageLayoutUtil.getQuarterlyTransferPage()
		},
		boxid = MainPageLayoutUtil.BoxId.TRANSFERS,
	},
	thisDay = {
		heading = ThisDayWidgets.Title(),
		body = ThisDayWidgets.Content{
			birthdayListPage = 'Birthday list'
		},
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.THIS_DAY,
	},
	specialEvents = {
		noPanel = true,
		body = '{{Liquipedia:Special Event}}',
		boxid = MainPageLayoutUtil.BoxId.SPECIAL_EVENTS,
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
		body = MatchTicker{},
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.MATCH_TICKER,
	},
	tournaments = {
		heading = 'Tournaments',
		body = TournamentsTicker{
			upcomingDays = 60,
			completedDays = 20
		},
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.TOURNAMENTS_TICKER,
	},
}

return {
	banner = {
		lightmode = 'Marvel Rivals full lightmode.png',
		darkmode = 'Marvel Rivals full darkmode.png',
	},
	metadesc = 'Comprehensive Marvel Rivals wiki with articles covering everything from heroes and maps, ' ..
	'to strategies, to tournaments, to competitive players, and teams.',
	title = 'The Marvel Rivals Wiki',
	navigation = {
		{
			file = '100T at MRIG Mid Season Finals 2025.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'Rad EU MRIG Mid Season Finals 2025 Champions.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'Cozy & Coluge at MRIG Mid Season Finals 2025.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'Ignite 2025 Mid Season Finals Trophy.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'Season 0 Heroes Marvel Rivals.jpg',
			title = 'Heroes',
			link = 'Portal:Heroes',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::character]]',
			},
		},
		{
			file = 'Marvel Rivals Old Hulk and Iron Man Team-Up.png',
			title = 'Mechanics',
			link = 'Mechanics',
			count = {
				method = 'CATEGORY',
				category = 'Mechanics',
			},
		},
		{
			file = 'Marvel Rivals map Celestial Husk.jpg',
			title = 'Maps',
			link = 'Portal:Maps',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::map]]',
			},
		},
		{
			file = 'Marvel Rivals gameasset Patches allmode.jpg',
			title = 'Patches',
			link = 'Portal:Patches',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::patch]]',
			},
		},
		{
			file = 'Gator at the MRIG Mid Season Finals 2025.jpg',
			title = 'Statistics',
			link = 'Portal:Statistics',
		},
	},
	layouts = {
		main = {
			{ -- Left
				sizes = {xxl = 5, xxxl = 6},
				children = {
					{
						mobileOrder = 1,
						noPanel = true,
						content = CONTENT.specialEvents,
					},
					{
						mobileOrder = 4,
						content = CONTENT.transfers,
					},
					{
						mobileOrder = 8,
						content = CONTENT.wantToHelp,
					},
				}
			},
			{ -- Right
				sizes = {xxl = 7, xxxl = 6},
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
						mobileOrder = 6,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 5,
						content = CONTENT.updates,
					},
					{
						mobileOrder = 7,
						content = CONTENT.usefulArticles,
					},
				},
			},
		},
	},
}
