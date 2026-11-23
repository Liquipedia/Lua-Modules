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
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker/List')

local Html = Lua.import('Module:Widget/Html')
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
	transfers = {
		heading = 'Transfers',
		body = TransfersList{
			limit = 10,
			transferPage = MainPageLayoutUtil.getYearlyTransferPage(),
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
		body = '{{Liquipedia:Special_Event}}',
		boxid = MainPageLayoutUtil.BoxId.WANT_TO_HELP,
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
			variant = 'collapsible',
		},
		padding = false,
		boxid = MainPageLayoutUtil.BoxId.TOURNAMENTS_TICKER,
	},
}

return {
	banner = {
		lightmode = 'Standoff 2 allmode.svg',
		darkmode = 'Standoff 2 allmode.svg',
	},
	metadesc = 'The Standoff 2 (SO2) esports wiki covering everything from players, teams and transfers, ' ..
		'to tournaments and results, maps and game contents.',
	title = 'Standoff 2',
	navigation = {
		{
			file = 'Revial_Gaming_at_EPIC_Standoff_2_Winter_Major_2023.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'CH_xZise_at_EPIC_Standoff_2_Fall_Major_2024.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'EPIC_Standoff_2_Cosmo_Major_trophy.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'Velya_and_GentlemaN_at_EPIC_Standoff_2_Summer_Major_2024.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'Breeze_Standoff_2_Map.jpg',
			title = 'Maps',
			link = 'Portal:Maps',
		},
		{
			file = 'Necessary_at_Standoff_2_Major_2022_autograph_session.jpg',
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
