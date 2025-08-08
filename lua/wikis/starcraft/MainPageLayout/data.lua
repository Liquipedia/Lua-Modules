---
-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MatchTickerContainer = Lua.import('Module:Widget/Match/Ticker/Container')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local FilterButtons = Lua.import('Module:Widget/FilterButtons')
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local WantToHelp = Lua.import('Module:Widget/MainPage/WantToHelp')

local CONTENT = {
	theGame = {
		heading = 'The Game',
		body = '{{Liquipedia:The Game}}',
		padding = true,
		boxid = 1503,
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
		boxid = 1504,
	},
	liquipediaApp = {
		heading = 'Download the Liquipedia App',
		padding = true,
		body = '{{Liquipedia:App}}',
		boxid = 1505,
	},
	thisDay = {
		heading = ThisDayWidgets.Title(),
		body = ThisDayWidgets.Content(),
		padding = true,
		boxid = 1510,
	},
	specialEvents = {
		noPanel = true,
		body = '{{Liquipedia:Special Event}}',
		boxid = 1516,
	},
	filterButtons = {
		noPanel = true,
		body = Div{
			css = {width = '100%', ['margin-bottom'] = '8px'},
			children = {FilterButtons()},
		},
	},
	matches = {
		heading = 'Matches',
		body = MatchTickerContainer{},
		padding = true,
		boxid = 1507,
		panelAttributes = {
			['data-switch-group-container'] = "countdown"
		},
	},
	tournaments = {
		heading = 'Tournaments',
		body = TournamentsTicker{
			upcomingDays = 7,
			completedDays = 7,
		},
		padding = true,
		boxid = 1508,
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
			{ -- Left
				size = 6,
				children = {
					{
						mobileOrder = 1,
						content = CONTENT.specialEvents,
					},
					{
						mobileOrder = 3,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 4,
						content = CONTENT.starCraftNews,
					},
					{
						mobileOrder = 5,
						content = CONTENT.liquipediaApp,
					},
					{
						mobileOrder = 6,
						content = CONTENT.wantToHelp,
					},
				}
			},
			{ -- Right
				size = 6,
				children = {
					{
						mobileOrder = 2,
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
				},
			},
			{
				children = {
					{
						mobileOrder = 7,
						content = CONTENT.theGame,
					},
				},
			},
		},
	},
}
