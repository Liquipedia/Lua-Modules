---
-- @Liquipedia
-- wiki=formula1
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')
local WantToHelp = Lua.import('Module:Widget/MainPage/WantToHelp')

local CONTENT = {
	theGame = {
		heading = 'The Sport',
		body = '{{Liquipedia:Sport Panel}}',
		padding = true,
		boxid = 1503,
	},
	transfers = {
		heading = 'Transfers',
		body = TransfersList{rumours = true},
		boxid = 1509,
	},
	specialEvents = {
		noPanel = true,
		body = '{{Liquipedia:Active Upcoming Series}}',
		boxid = 1516
	},
	filterButtons = {
		noPanel = true,
		body = Div{
			css = { width = '100%', ['margin-bottom'] = '8px' },
			children = { FilterButtonsWidget() }
		},
	},
	tournaments = {
		noPanel = true,
		body = '{{Liquipedia:Tournaments List}}',
		boxid = 1517
	},
	seasonOverview = {
		noPanel = true,
		body = '{{Liquipedia:Season Overview}}',
		boxid = 1518
	},
	driversLineup = {
		noPanel = true,
		body = '{{Liquipedia:Drivers Line-up}}',
		boxid = 1519
	},
	seasonStandings = {
		heading = '<span class="fas fa-trophy cinnabar-theme-dark-gb"></span>&nbsp;Current Season Standings', -- todo: use icon module here instead
		body = '{{Liquipedia:Season Standing}}',
		boxid = 1520
	},
	seasonCalendar = {
		noPanel = true,
		body = '{{Liquipedia:Season Calendar}}',
		boxid = 1521
	},
	wantToHelp = {
		heading = 'Want To Help?',
		body = WantToHelp{},
		padding = true,
		boxid = 1504,
	},
	thisDay = {
		heading = ThisDayWidgets.Title(),
		body = ThisDayWidgets.Content{
			birthdayListPage = 'Birthday list'
		},
		padding = true,
		boxid = 1510,
	},
	upcomingRace = {
		noPanel = true,
		body = '{{Liquipedia:Upcoming Race Weekend}}',
		boxid = 1522
	},
	upcomingCircuit = {
		noPanel = true,
		body = '{{Liquipedia:Upcoming Circuit}}',
		boxid = 1523
	},
	previousRace = {
		noPanel = true,
		body = '{{Liquipedia:Previous Race Weekend}}',
		boxid = 1524
	},
	allF1Seasons = {
		noPanel = true,
		body = '{{Liquipedia:All F1 Seasons}}',
		boxid = 1525
	},
}

return {
	banner = {
		lightmode = '',
		darkmode = '',
	},
	metadesc = 'Comprehensive Formula 1 wiki with articles covering everything from drivers, to teams, to seasons, to race chassis and history.',
	title = 'Formula 1',
	navigation = {
		{
			file = '',
			title = 'Drivers',
			link = 'Portal:Drivers',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = '',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = '',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = '',
			title = 'Championships',
			link = 'Portal:Championships',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = '',
			title = 'Circuits',
			link = 'Portal:Circuits',
		},
		{
			file = 'F1 Circuit de Monaco Monochrome 2023 lightmode.svg',
			title = 'Circuits',
			link = 'Portal:Circuits',
		},
		{
			file = '',
			title = 'Help',
			link = 'Help:Editing',
		},
	},
	layouts = {
		main = {
			{ -- Left
				size = 6,
				children = {
					{
						mobileOrder = 2,
						content = CONTENT.specialEvents,
					},
					{
						mobileOrder = 5,
						content = CONTENT.seasonOverview,
					},
					{
						mobileOrder = 6,
						content = CONTENT.driversLineup,
					},
					{
						mobileOrder = 7,
						content = CONTENT.seasonStandings,
					},
					{
						mobileOrder = 8,
						content = CONTENT.seasonCalendar,
					},
					{
						mobileOrder = 9,
						content = CONTENT.transfers,
					},
				}
			},
			{ -- Right
				size = 6,
				children = {
					{
						mobileOrder = 3,
						content = CONTENT.upcomingRace,
					},
					{
						mobileOrder = 4,
						content = CONTENT.upcomingCircuit,
					},
					{
						mobileOrder = 10,
						content = CONTENT.previousRace,
					},
					{
						mobileOrder = 11,
						content = CONTENT.tournaments,
					},
					{
						mobileOrder = 12,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 13,
						content = CONTENT.wantToHelp,
					},
					{
						mobileOrder = 14,
						content = CONTENT.allF1Seasons,
					},
				},
			},
			{
				children = {
					{
						mobileOrder = 15,
						content = CONTENT.theGame,
					},
				},
			},
		},
	},
}
