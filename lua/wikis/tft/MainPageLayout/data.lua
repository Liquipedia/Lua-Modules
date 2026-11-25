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
local Headlines = Lua.import('Module:Widget/MainPage/Headlines')
local MatchTicker = Lua.import('Module:Widget/MainPage/MatchTicker')
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')
local WantToHelp = Lua.import('Module:Widget/MainPage/WantToHelp')

local CONTENT = {
	theGame = {
		heading = 'The Game',
		body = '{{Liquipedia:The Game}}',
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
		body = TransfersList(),
		boxid = MainPageLayoutUtil.BoxId.TRANSFERS,
	},
	thisDay = {
		heading = ThisDayWidgets.Title(),
		body = ThisDayWidgets.Content{ birthdayListPage = 'Birthday list' },
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
			upcomingDays = 30,
			completedDays = 30,
		},
		padding = false,
		boxid = MainPageLayoutUtil.BoxId.TOURNAMENTS_TICKER,
	},
	headlines = {
		heading = 'Headlines',
		body = Headlines{},
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.HEADLINES,
	},
}

return {
	banner = {
		lightmode = 'Teamfight Tactics LOGO lightmode.png',
		darkmode = 'Teamfight Tactics LOGO darkmode.png',
	},
	metadesc = 'Comprehensive Teamfight Tactics wiki with articles covering everything from champions, ' ..
		'to strategies, to tournaments, to competitive players and teams.',
	title = 'Teamfight Tactics',
	navigation = {
		{
			file = 'Shiquz TFT Macao Open 2024.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'T1 TFT EWC 2024.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'Scarra and BoxBox TFT Macao Open 2024.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'TFT Macao Open 2024 Champion Belt.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'Chibi T1 Orianna.png',
			title = 'Hall of Fame',
			link = 'Portal:Hall of Fame',
		},
		{
			file = 'Aesah and Mortdog TFT Vegas Open 2023.jpg',
			title = 'Statistics',
			link = 'Portal:Statistics',
		},
	},
	layouts = {
		main = {
			{ -- Top
				size = 12,
				children = {
					{
						mobileOrder = 3,
						noPanel = true,
						content = CONTENT.filterButtons,
					},
					{
						mobileOrder = 4,
						noPanel = true,
						content = CONTENT.matches,
					},
				},
			},
			{ -- Left
				sizes = {xxl = 6, xxxl = 6},
				children = {
					{
						mobileOrder = 2,
						content = CONTENT.specialEvents,
					},
					{
						mobileOrder = 6,
						content = CONTENT.transfers,
					},
					{
						mobileOrder = 8,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 9,
						content = CONTENT.wantToHelp,
					},
				}
			},
			{ -- Right
				sizes = {xxl = 6, xxxl = 6},
				children = {
					{
						mobileOrder = 5,
						content = CONTENT.tournaments,
					},
				},
			},
			{
				children = {
					{
						mobileOrder = 7,
						content = CONTENT.headlines,
					},
					{
						mobileOrder = 10,
						content = CONTENT.theGame,
					},
				},
			},
		},
	},
}
