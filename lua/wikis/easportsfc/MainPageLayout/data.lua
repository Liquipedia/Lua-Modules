---
-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MainPageLayoutUtil = Lua.import('Module:MainPageLayout/Util')

local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')
local MatchTicker = Lua.import('Module:Widget/MainPage/MatchTicker')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local Html = Lua.import('Module:Widget/Html')
local LiquipediaApp = Lua.import('Module:Widget/MainPage/LiquipediaApp')
local Div = Html.Div
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')
local WantToHelp = Lua.import('Module:Widget/MainPage/WantToHelp')

local CONTENT = {
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
	liquipediaApp = {
		heading = 'Download the Liquipedia App',
		padding = true,
		body = LiquipediaApp{},
		boxid = MainPageLayoutUtil.BoxId.MOBILE_APP,
	},
	transfers = {
		heading = 'Transfers',
		body = TransfersList{
			transferPage = MainPageLayoutUtil.getQuarterlyTransferPage()
		},
		boxid = MainPageLayoutUtil.BoxId.TRANSFERS,
	},
	thisDay = {
		heading = ThisDayWidgets.Title(),
		body = ThisDayWidgets.Content(),
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.THIS_DAY,
	},
	specialEvents = {
		noPanel = true,
		body = '{{Liquipedia:Eventbox}}',
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
		noPanel = true,
		body = MatchTicker{},
		boxid = MainPageLayoutUtil.BoxId.MATCH_TICKER,
	},
	tournaments = {
		heading = 'Tournaments',
		body = TournamentsTicker{
			upcomingDays = 40,
			modifierTier1 = 50,
			completedDays = 20,
		},
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.TOURNAMENTS_TICKER,
	},
}

return {
	banner = {
		lightmode = 'EA Sports FC full lightmode.png',
		darkmode = 'EA Sports FC full darkmode.png',
	},
	metadesc = 'The EA SPORTS FC wiki covering everything from players, teams and transfers, to ' ..
		'tournaments and results.',
	title = 'EA SPORTS FC',
	navigation = {
		{
			file = 'EmreYilmaz at the Esports World Cup 2024.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'Nathansr22 at the Esports World Cup 2024.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'Jafonsogv and ManuBachoore at the Esports World Cup 2024.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'eChampions League 2025 Trophy.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'TL vs Fnatic EAFC at the Esports World Cup 2024.jpg',
			title = 'Statistics',
			link = 'Portal:Statistics',
		},
		{
			file = 'PHzin at the Esports World Cup 2024.jpg',
			title = 'Help Portal',
			link = 'Help:Contents',
		},
	},
	layouts = {
		main = {
			{ -- Top
				size = 12,
				children = {
					{
						mobileOrder = 2,
						noPanel = true,
						content = CONTENT.filterButtons,
					},
					{
						mobileOrder = 3,
						noPanel = true,
						content = CONTENT.matches,
					},
				},
			},
			{ -- Left
				sizes = {xxl = 6, xxxl = 6},
				children = {
					{
						mobileOrder = 1,
						content = CONTENT.specialEvents,
					},
					{
						mobileOrder = 5,
						content = CONTENT.transfers,
					},
					{
						mobileOrder = 7,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 8,
						content = CONTENT.wantToHelp,
					},
					{
						mobileOrder = 9,
						content = CONTENT.liquipediaApp,
					},
				}
			},
			{ -- Right
				sizes = {xxl = 6, xxxl = 6},
				children = {
					{
						mobileOrder = 4,
						content = CONTENT.tournaments,
					},
				},
			},
			{ -- Bottom
				children = {
					{
						mobileOrder = 7,
						content = CONTENT.usefulArticles,
					},
				},
			},
		},
	},
}
