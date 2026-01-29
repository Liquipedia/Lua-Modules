---
-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DateExt = Lua.import('Module:Date/Ext')
local MainPageLayoutUtil = Lua.import('Module:MainPageLayout/Util')

local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')
local WantToHelp = Lua.import('Module:Widget/MainPage/WantToHelp')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local ONGOING_SERIES = IconFa{
	iconName = 'ongoing_series',
	color = 'cinnabar-theme-dark-gb',
	size = 'lg',
}

local TROPHY = IconFa{
	iconName = 'firstplace',
	color = 'cinnabar-theme-dark-gb',
	size = 'lg',
}

local CALENDAR = IconFa{
	iconName = 'calendar',
	color = 'cinnabar-theme-dark-gb',
	size = 'lg',
}

local HISTORY = IconFa{
	iconName = 'season_history',
	color = 'cinnabar-theme-dark-gb',
	size = 'lg',
}

local FINISHED_RACE = IconFa{
	iconName = 'finished_race',
	color = 'cinnabar-theme-dark-gb',
	size = 'lg',
}

local CONTENT = {
	transfers = {
		heading = 'Transfers',
		body = TransfersList{
			rumours = true,
			transferPage = 'Driver Transfers/' .. DateExt.getYearOf()
		},
		boxid = MainPageLayoutUtil.BoxId.TRANSFERS,
	},
	specialEvents = {
		heading = HtmlWidgets.Fragment{children = {ONGOING_SERIES, '&nbsp;Active and Upcoming Series'}},
		body = '{{Liquipedia:Active Upcoming Series}}',
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.SPECIAL_EVENTS
	},
	filterButtons = {
		noPanel = true,
		body = Div{
			css = { width = '100%', ['margin-bottom'] = '8px' },
			children = { FilterButtonsWidget() }
		},
	},
	tournaments = {
		heading = HtmlWidgets.Fragment{children = {TROPHY, '&nbsp;F1 & Feeder Series Seasons'}},
		body = TournamentsTicker{
			upcomingDays = 90,
			completedDays = 90
		},
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.TOURNAMENTS_TICKER
	},
	seasonOverview = {
		heading =HtmlWidgets.Fragment{children = {TROPHY, '&nbsp;Current Season Overview'}},
		body = '{{Liquipedia:Season Overview}}',
		padding = true,
		boxid = 1517
	},
	seasonCalendar = {
		heading =HtmlWidgets.Fragment{children = {CALENDAR, '&nbsp;Season Calendar'}},
		body = '{{Liquipedia:Season Calendar}}',
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.MOBILE_APP
	},
	wantToHelp = {
		heading = 'Want To Help?',
		body = WantToHelp{},
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.WANT_TO_HELP,
	},
	thisDay = {
		heading = ThisDayWidgets.Title(),
		body = ThisDayWidgets.Content{
			birthdayListPage = 'Birthday list'
		},
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.THIS_DAY,
	},
	upcomingRace = {
		heading =HtmlWidgets.Fragment{children = {TROPHY, '&nbsp;Upcoming Race'}},
		body = '{{Liquipedia:Upcoming Grand Prix}}',
		padding = true,
		boxid = 1518
	},
	previousRace = {
		heading =HtmlWidgets.Fragment{children = {FINISHED_RACE, '&nbsp;Previous Race Weekend'}},
		body = '{{Liquipedia:Previous Race Weekend}}',
		boxid = 1515
	},
	allF1Seasons = {
		heading =HtmlWidgets.Fragment{children = {HISTORY, '&nbsp;Formula 1 Seasons'}},
		body = '{{Liquipedia:All F1 Seasons}}',
		boxid = 1512
	},
		theGame = {
		heading = 'The Sport',
		body = '{{Liquipedia:Sport Panel}}',
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.USEFUL_ARTICLES,
	},
}

return {
	banner = {
		lightmode = 'F1_2018_allmode.png',
		darkmode = 'F1_2018_allmode.png',
	},
	metadesc = 'Comprehensive Formula 1 wiki with articles covering everything from drivers, to teams, '  ..
		'to seasons, to race chassis and history.',
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
						content = CONTENT.seasonOverview,
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
						content = CONTENT.filterButtons,
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
