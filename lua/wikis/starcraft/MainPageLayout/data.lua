---
-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MainPageLayoutUtil = Lua.import('Module:MainPageLayout/Util')

local MainPageMatchTicker = Lua.import('Module:Widget/MainPage/MatchTicker')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local FilterButtons = Lua.import('Module:Widget/FilterButtons')
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local WantToHelp = Lua.import('Module:Widget/MainPage/WantToHelp')

local CONTENT = {
	theGame = {
		heading = 'The Game',
		body = '{{Liquipedia:The Game}}',
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.USEFUL_ARTICLES,
	},
	starCraftNews = {
		heading = 'The Game',
		body = '{{Liquipedia:StarCraft News}}',
		padding = true,
		boxid = 1531,
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
		body = '{{Liquipedia:App}}',
		boxid = MainPageLayoutUtil.BoxId.MOBILE_APP,
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
			css = {width = '100%', ['margin-bottom'] = '8px'},
			children = {FilterButtons()},
		},
	},
	matches = {
		noPanel = true,
		body = MainPageMatchTicker{
			showMatchesPortal = false,
		},
		boxid = MainPageLayoutUtil.BoxId.MATCH_TICKER,
	},
	tournaments = {
		heading = 'Tournaments',
		body = TournamentsTicker{
			upcomingDays = 7,
			completedDays = 7,
		},
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.TOURNAMENTS_TICKER,
	},
}

return {
	banner = {
		lightmode = 'StarCraft default allmode.png',
		darkmode = 'StarCraft default allmode.png',
	},
	metadesc = 'Comprehensive StarCraft Brood War wiki with articles covering everything from units and buildings, ' ..
		'to strategies, to tournaments, to competitive players and teams.',
	title = 'StarCraft Brood War',
	navigation = {
		{
			file = 'Flash17.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'CJ SuperFight 4 SKT1.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'SSL 10 finals sSak trophy.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'Wcg2004podium2.jpg',
			title = 'Korean Scene',
			link = 'Portal:Progaming',
		},
		{
			file = 'ElkyKTFEverLeague03.jpg',
			title = 'Global Scene',
			link = 'Portal:Foreign_Scene',
		},
		{
			file = 'Tasteless starinvitefinals1.jpg',
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
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 6,
						content = CONTENT.starCraftNews,
					},
					{
						mobileOrder = 7,
						content = CONTENT.liquipediaApp,
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
				},
			},
			{
				children = {
					{
						mobileOrder = 9,
						content = CONTENT.theGame,
					},
				},
			},
		},
	},
}
