---
-- @Liquipedia
-- wiki=mobilelegends
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DateExt = require('Module:Date/Ext')
local Lua = require('Module:Lua')

local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')
local MatchTickerContainer = Lua.import('Module:Widget/Match/Ticker/Container')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')
local WidgetUtil = Lua.import('Module:Widget/Util')

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
		body = '{{Liquipedia:App}}',
		boxid = 1505,
	},
	transfers = {
		heading = 'Transfers',
		body = TransfersList{
			rumours = true,
			transferPage = function ()
				return 'Player Transfers/' .. os.date('%Y') .. '/' .. os.date('%B')
			end
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
		body = '{{Liquipedia:Special Event}}',
	},
	filterButtons = {
		noPanel = true,
		body = Div{
			css = { width = '100%', ['margin-bottom'] = '8px' },
			children = { FilterButtonsWidget() }
		},
	},
	matches = {
		heading = 'Matches',
		body = WidgetUtil.collect(
			MatchTickerContainer{},
			Div{
				css = {
					['white-space'] = 'nowrap',
					display = 'block',
					margin = '0 10px',
					['font-size'] = '15px',
					['font-style'] = 'italic',
					['text-align'] = 'center',
				},
				children = { Link{ children = 'See more matches', link = 'Liquipedia:Matches'} }
			}
		),
		padding = true,
		boxid = 1507,
	},
	tournaments = {
		heading = 'Tournaments',
		body = TournamentsTicker{
			upcomingDays = 60,
			completedDays = 45
		},
		padding = true,
		boxid = 1508,
	},
}

return {
	banner = {
		lightmode = 'Mobile Legends 2025 full lightmode.svg',
		darkmode = 'Mobile Legends 2025 full darkmode.svg',
	},
	metadesc = 'The Mobile Legends: Bang Bang (MLBB) esports wiki covering everything from players, teams & transfers, ' ..
		'to tournaments and results, heroes, equipment, & patches.',
	title = 'Mobile Legends',
	navigation = {
		{
			file = 'RRQ Hoshi at M6 Knockout Stage.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'TLID Aran at M6 Knockout Stage.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'M6 World Championship Trophy.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'RRQ at M6 World Championship.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'BG Shadow at M5.jpg',
			title = 'Rumours',
			link = 'Portal:Rumours',
		},
		{
			file = 'NPFL Zarate at M6 Knockout Stage.jpg',
			title = 'Statistics',
			link = 'Portal:Statistics',
		},
		{
			file = 'Layla Energy Gunner Revamp.png',
			title = 'Heroes',
			link = 'Portal:Heroes',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::character]]',
			},
		},
		{
			file = 'Item Immortality ML.png',
			title = 'Equipment',
			link = 'Portal:Equipment',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::item]]',
			},
		},
		{
			file = 'Layla Energy Gunner Revamp.png',
			title = 'Patches',
			link = 'Portal:Patches',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::patch]]',
			},
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
						content = CONTENT.transfers,
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
					{
						mobileOrder = 5,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 4,
						content = CONTENT.usefulArticles,
					},
				},
			},
		},
	},
}
