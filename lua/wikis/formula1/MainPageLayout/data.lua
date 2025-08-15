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
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')
local WantToHelp = Lua.import('Module:Widget/MainPage/WantToHelp')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')
local HOUR_GLASS_HALF = IconFa{
	iconName = 'outoftime',
	color = 'cinnabar-theme-dark-gb',
	size = 'lg',
}

local CONTENT = {
	transfers = {
		heading = 'Transfers',
		body = TransfersList{rumours = true},
		boxid = 1501,
	},
	specialEvents = {
		heading = HtmlWidgets.Fragment{children = {HOUR_GLASS_HALF, '&nbsp;Active and Upcoming Series'}},
		body = '{{Liquipedia:Active Upcoming Series}}',
		boxid = 1502
	},
	filterButtons = {
		noPanel = true,
		body = Div{
			css = { width = '100%', ['margin-bottom'] = '8px' },
			children = { FilterButtonsWidget() }
		},
	},
	tournaments = {
		heading ='<span class="fas fa-trophy cinnabar-theme-dark-gb"></span>&nbsp;F1 & Feeder Series Seasons',
		body = TournamentsTicker{
			upcomingDays = 90,
			completedDays = 90
		},
		boxid = 1503
	},
	seasonOverview = {
		heading ='<span class="fas fa-trophy cinnabar-theme-dark-gb"></span>&nbsp;Current Season Overview',
		body = '{{Liquipedia:Season Overview}}',
		boxid = 1504
	},
	seasonCalendar = {
		heading ='<span class="fas fa-calendar cinnabar-theme-dark-gb"></span>&nbsp;Season Calendar',
		body = '{{Liquipedia:Season Calendar}}',
		boxid = 1505
	},
	wantToHelp = {
		heading = 'Want To Help?',
		body = WantToHelp{},
		padding = true,
		boxid = 1508,
	},
	thisDay = {
		heading = ThisDayWidgets.Title(),
		body = ThisDayWidgets.Content{
			birthdayListPage = 'Birthday list'
		},
		padding = true,
		boxid = 1509,
	},
	upcomingRace = {
		heading ='<span class="fas fa-trophy cinnabar-theme-dark-gb"></span>&nbsp;Upcoming Race',
		body = '{{Liquipedia:Upcoming Grand Prix}}',
		boxid = 1509
	},
	previousRace = {
		heading ='<span class="fas fa-flag-checkered cinnabar-theme-dark-gb"></span>&nbsp;Previous Race Weekend',
		body = '{{Liquipedia:Previous Race Weekend}}',
		boxid = 1511
	},
	allF1Seasons = {
		heading ='<span class="fas fa-landmark cinnabar-theme-dark-gb"></span>&nbsp;Formula 1 Seasons',
		body = '{{Liquipedia:All F1 Seasons}}',
		boxid = 1512
	},
		theGame = {
		heading = 'The Sport',
		body = '{{Liquipedia:Sport Panel}}',
		padding = true,
		boxid = 1513,
	},
}

return {
	banner = {
		lightmode = 'F1_2018_allmode.png',
		darkmode = 'F1_2018_allmode.png',
	},
	metadesc = 'Comprehensive Formula 1 wiki with articles covering everything from drivers, to teams, to seasons, to race chassis and history.',
	title = 'Formula 1',
	navigation = {
		{
			file = '2024 F1 Dutch GP Podium.jpg',
			title = 'Drivers',
			link = 'Portal:Drivers',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'F1 Emilia-Romagna Grand Prix 2025.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'Leclerc vs Hamilton Silverstone.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'FIA Formula One Constructors Championship Trophy 2014.jpg',
			title = 'Championships',
			link = 'Portal:Championships',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'F1 Google Earth Circuit Sao Paulo.jpeg',
			title = 'Circuits',
			link = 'Portal:Circuits',
		},
		{
			file = 'Alonso at Canada 2008.jpg',
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
						mobileOrder = 1,
						content = CONTENT.specialEvents,
					},
					{
						mobileOrder = 6,
						content = CONTENT.filterButtons,
					},
					{
						mobileOrder = 7,
						content = CONTENT.seasonCalendar,
					},
					{
						mobileOrder = 8,
						content = CONTENT.transfers,
					},
				}
			},
			{ -- Right
				size = 6,
				children = {
					{
						mobileOrder = 2,
						content = CONTENT.upcomingRace,
					},
					{
						mobileOrder = 3,
						content = CONTENT.previousRace,
					},
					{
						mobileOrder = 4,
						content = CONTENT.tournaments,
					},
					{
						mobileOrder = 5,
						content = CONTENT.tournaments,
					},
					{
						mobileOrder = 9,
						content = CONTENT.allF1Seasons,
					},
					{
						mobileOrder = 10,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 11,
						content = CONTENT.wantToHelp,
					},
				},
			},
			{
				children = {
					{
						mobileOrder = 12,
						content = CONTENT.theGame,
					},
				},
			},
		},
	},
}
