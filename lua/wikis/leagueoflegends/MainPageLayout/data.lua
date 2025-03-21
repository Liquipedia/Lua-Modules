---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Headlines = Lua.import('Module:Widget/MainPage/Headlines')
local LiquipediaApp = Lua.import('Module:Widget/MainPage/LiquipediaApp')
local MatchTicker = Lua.import('Module:Widget/MainPage/MatchTicker')
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
	liquipediaApp = {
		heading = 'Download the Liquipedia App',
		padding = true,
		body = LiquipediaApp{},
		boxid = 1505,
	},
	transfers = {
		heading = 'Transfers',
		body = TransfersList{rumours = true},
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
			upcomingDays = 30,
			completedDays = 20,
			modifierTypeQualifier = -2,
			modifierTier1 = 55,
			modifierTier2 = 55,
			modifierTier3 = 10
		},
		padding = true,
		boxid = 1508,
	},
	headlines = {
		heading = 'Headlines',
		body = Headlines{},
		padding = true,
		boxid = 1511,
	},
	references = {
		heading = 'References',
		body = '{{reflist|2}}',
		padding = true,
		boxid = 1512,
	},
}

return {
	banner = {
		lightmode = 'League of Legends full allmode.png',
		darkmode = 'League of Legends full allmode.png',
	},
	metadesc = 'Comprehensive League of Legends (LOL) wiki with articles covering everything from champions, ' ..
		'to strategies, to tournaments, to competitive players and teams.',
	title = 'League of Legends',
	navigation = {
		{
			file = 'DRX Deft Worlds 2022 Champion.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'T1 Worlds 2024.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'G2 Worlds 2024.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'Worlds Trophy 2024.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'T1 Worlds23 Skins Splash Art.jpg',
			title = 'Champions',
			link = 'Champions',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::character]]',
			},
		},
		{
			file = 'LoL Patch 14.24 Art.jpg',
			title = 'Patches',
			link = 'Patches',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::patch]]',
			},
		},
		{
			file = 'Worlds 2024 Finalists.jpg',
			title = 'News',
			link = 'Portal:News',
			count = {
				method = 'LPDB',
				table = 'externalmedialink',
			},
		},
		{
			file = 'Gen.G Mata Worlds 2024.jpg',
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
						content = CONTENT.aboutEsport,
					},
					{
						mobileOrder = 2,
						content = CONTENT.specialEvents,
					},
					{
						mobileOrder = 4,
						content = CONTENT.transfers,
					},
					{
						mobileOrder = 6,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 7,
						content = CONTENT.wantToHelp,
					},
					{
						mobileOrder = 8,
						content = CONTENT.liquipediaApp,
					},
				}
			},
			{ -- Right
				size = 6,
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
				},
			},
			{
				children = {
					{
						mobileOrder = 5,
						content = CONTENT.headlines,
					},
					{
						mobileOrder = 9,
						content = CONTENT.usefulArticles,
					},
					{
						mobileOrder = 10,
						content = CONTENT.references,
					},
				},
			},
		},
	},
}
