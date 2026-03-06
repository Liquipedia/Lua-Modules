---
-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MainPageLayoutUtil = Lua.import('Module:MainPageLayout/Util')
local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')
local Template = Lua.import('Module:Template')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
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
		body = TransfersList{
			transferPortal = 'Transfers',
			transferPage = MainPageLayoutUtil.getQuarterlyTransferPage(),
			rumours = true
		},
		boxid = MainPageLayoutUtil.BoxId.TRANSFERS,
	},
	thisDay = {
		heading = ThisDayWidgets.Title(),
		body = ThisDayWidgets.Content(),
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.THIS_DAY,
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
		body = HtmlWidgets.Fragment{children = {
			Template.safeExpand(mw.getCurrentFrame(), 'Liquipedia:Upcoming_and_ongoing_matches_on_mainpage'),
			Div{
				css = {
					['text-align'] = 'center',
					padding = '5px',
				},
				children = HtmlWidgets.I{
					children = Link{
						link = 'Liquipedia:Upcoming and ongoing matches',
						children = 'See more matches'
					}
				}
			}
		}},
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.MATCH_TICKER,
	},
	tournaments = {
		heading = 'Tournaments',
		body = TournamentsTicker{
			upcomingDays = 60,
			completedDays = 60,
			displayGameIcons = true,
		},
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.TOURNAMENTS_TICKER,
	},
}

return {
	banner = {
		lightmode = 'Sim Racing full default lightmode.svg',
		darkmode = 'Sim Racing full default darkmode.svg',
	},
	metadesc = 'Comprehensive Sim Racing wiki with articles covering everything from circuits and games, ' ..
		'to tournaments, to competitive players and teams.',
	title = 'Sim Racing',
	navigation = {
		{
			file = 'Luke_Bennett at the 2025 Esports World Cup.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'Team Redline at the 2025 Esports World Cup.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'Rennsport Trophy at the 2025 Esports World Cup.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'Willams and BS at the 2025 Esports World Cup.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			}
		},
		{
			file = 'Rennsport at the 2025 Esports World Cup.jpg',
			title = 'Statistics',
			link = 'Portal:Statistics',
		},
		{
			file = 'Nurburgring.jpg',
			title = 'Circuits',
			link = 'Portal:Circuits',
			count = {
				method = 'CATEGORY',
				category = 'Maps',
			},
		},
	},
	layouts = {
		main = {
			{ -- Left
				sizes = {xxl = 5, xxxl = 6},
				children = {
					{
						mobileOrder = 2,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 3,
						content = CONTENT.transfers,
					},
					{
						mobileOrder = 4,
						content = CONTENT.wantToHelp,
					},
				}
			},
			{ -- Right
				sizes = {xxl = 7, xxxl = 6},
				children = {
					{
						mobileOrder = 1,
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
								size = 5,
								children = {
									{
										noPanel = true,
										content = CONTENT.matches,
									},
								},
							},
							{
								size = 7,
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
						mobileOrder = 5,
						content = CONTENT.theGame,
					}
				},
			},
		},
	},
}
