-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')
local MatchTicker = Lua.import('Module:Widget/MainPage/MatchTicker')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')

local CONTENT = {
	usefulArticles = {
		heading = 'Useful Articles',
		body = '{{Liquipedia:Useful Articles}}',
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
			limit = 10,
			transferPage = 'Player Transfers/' .. os.date('%Y'),
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
		body = '{{Liquipedia:Special_Event}}',
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
		lightmode = 'Chess default lightmode.svg',
		darkmode = 'Chess default darkmode.svg',
	},
	metadesc = 'The Chess sports wiki covering everything from players, teams and transfers, to ' ..
		'tournaments and results.',
	title = 'Chess',
	navigation = {
		{
			file = 'Alireza Firouzja vs Fabiano Caruana at Norway Chess 2023.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'Team India at Chess Olympiad 2016.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'Maxime Vachier-Lagrave Interview at Norway Chess 2019.jpg',
			title = 'Player Signings',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'Round 2 matches at Norway Chess 2023.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'Norway Chess 2023 score sheet.jpg',
			title = 'Statistics',
			link = 'Portal:Statistics',
		},
		{
			file = 'Grischuk at FIDE World Blitz Chess Championship 2019.jpg',
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
