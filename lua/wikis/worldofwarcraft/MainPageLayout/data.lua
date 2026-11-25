---
-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MainPageLayoutUtil = Lua.import('Module:MainPageLayout/Util')

local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker/List')

local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local MatchTicker = Lua.import('Module:Widget/MainPage/MatchTicker')
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
	transfers = {
		heading = 'Transfers',
		body = TransfersList{
			transferPage = MainPageLayoutUtil.getYearlyTransferPage()
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
		noPanel = true,
		body = MatchTicker{},
		boxid = MainPageLayoutUtil.BoxId.MATCH_TICKER,
	},
	tournaments = {
		heading = 'Tournaments',
		body = TournamentsTicker{
			upcomingDays = 100,
			completedDays = 100,
			tierColorScheme = 'top3',
			variant = 'collapsible',
		},
		padding = false,
		boxid = MainPageLayoutUtil.BoxId.TOURNAMENTS_TICKER,
	},
}

return {
	banner = {
		lightmode = 'World of Warcraft full almode.png',
		darkmode = 'World of Warcraft full almode.png',
	},
	metadesc = 'The World of Warcraft wiki covering everything from players, teams and transfers, ' ..
		'to tournaments and results, strategies, classes, and maps.',
	title = 'World of Warcraft',
	navigation = {
		{
			file = 'Whaazz Blizzcon2016.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'ABC at the Arena World Championship 2017.png',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'Trophies at the Arena World Championship 2017.png',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'Panda Global at the Arena World Championship 2017.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'World of Warcraft at DreamHack 2014.jpg',
			title = 'Statistics',
			link = 'Portal:Statistics',
		},
		{
			file = 'Empyrean Domain.jpg',
			title = 'Game Mechanics',
			link = 'Portal:Game_Mechanics',
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
						mobileOrder = 8,
						content = CONTENT.wantToHelp,
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
					{
						mobileOrder = 7,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 6,
						content = CONTENT.usefulArticles,
					},
				},
			},
		},
	},
}
