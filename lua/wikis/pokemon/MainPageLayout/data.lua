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
			limit = 10,
			transferPage = MainPageLayoutUtil.getQuarterlyTransferPage()
		},
		boxid = MainPageLayoutUtil.BoxId.TRANSFERS,
	},
	thisDay = {
		heading = ThisDayWidgets.Title(),
		body = ThisDayWidgets.Content{
			birthdayListPage = 'Birthday list'
		},
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
			upcomingDays = 45,
			completedDays = 45,
			displayGameIcons = true,
		},
		padding = false,
		boxid = MainPageLayoutUtil.BoxId.TOURNAMENTS_TICKER,
	},
}

return {
	banner = {
		lightmode = 'Pokemon default allmode.svg',
		darkmode = 'Pokemon default allmode.svg',
	},
	metadesc = 'The Pokémon esports wiki covering everything from players, teams and transfers, ' ..
		'to tournaments, results and games.',
	title = 'Pokémon',
	navigation = {
		{
			file = 'Main_Venue_at_Oceania_IC_2023.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'Wolfey_Vegas_Open_2023.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'Wyndon_Stadium_in Pokemon Sword and Shield.png',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'TCG Cards at Brisbane Regionals 2025.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'Nintendo Switch at Perth Regionals 2024.jpg',
			title = 'Games',
			link = 'Portal:Games',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::game]]',
			},
		},
		{
			file = 'TCG Cards at Melbourne Regionals 2025.jpg',
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
