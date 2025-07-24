-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DateExt = require('Module:Date/Ext')
local Lua = require('Module:Lua')

local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')
local MatchTicker = Lua.import('Module:Widget/MainPage/MatchTicker')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local LiquipediaApp = Lua.import('Module:Widget/MainPage/LiquipediaApp')
local Div = HtmlWidgets.Div
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')
local WantToHelp = Lua.import('Module:Widget/MainPage/WantToHelp')

local CONTENT = {
	usefulArticles = {
		heading = 'Useful Articles',
		body = '{{Liquipedia:Useful Articles}}',
		padding = true,
		boxid = 1503,
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
		body = LiquipediaApp{},
		boxid = 1505,
	},
	transfers = {
		heading = 'Transfers',
		body = TransfersList{
			transferPage = 'Player Transfers/' .. os.date('%Y') .. '/' ..
				DateExt.quarterOf{ ordinalSuffix = true } .. ' Quarter'
		},
		boxid = 1509,
	},
	thisDay = {
		heading = ThisDayWidgets.Title(),
		body = ThisDayWidgets.Content(),
		padding = true,
		boxid = 1510,
	},
	specialEvents = {
		noPanel = true,
		body = '{{Liquipedia:Eventbox}}',
		boxid = 1516,
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
		boxid = 1507,
		panelAttributes = {
			['data-switch-group-container'] = 'countdown',
		},
	},
	tournaments = {
		heading = 'Tournaments',
		body = TournamentsTicker{
			upcomingDays = 40,
			modifierTier1 = 50,
			completedDays = 20,
		},
		padding = true,
		boxid = 1508,
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
			{ -- Left
				size = 5,
				children = {
					{
						mobileOrder = 1,
						content = CONTENT.specialEvents,
					},
					{
						mobileOrder = 3,
						content = CONTENT.transfers,
					},
					{
						mobileOrder = 5,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 6,
						content = CONTENT.wantToHelp,
					},
					{
						mobileOrder = 7,
						content = CONTENT.liquipediaApp,
					},
				}
			},
			{ -- Right
				size = 7,
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
								size = 7,
								children = {
									{
										noPanel = true,
										content = CONTENT.matches,
									},
								},
							},
							{
								size = 5,
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
			{ -- Bottom
				children = {
					{
						mobileOrder = 5,
						content = CONTENT.usefulArticles,
					},
				},
			},
		},
	},
}
