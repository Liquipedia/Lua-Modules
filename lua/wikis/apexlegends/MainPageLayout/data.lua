---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DateExt = require('Module:Date/Ext')
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
		heading = 'The Game',
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
		body = TransfersList{
			rumours = true,
			transferPage = function ()
				return 'Player Transfers/' .. os.date('%Y') .. '/' .. DateExt.quarterOf{ ordinalSuffix = true } .. ' Quarter'
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
			completedDays = 30
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
}

return {
	banner = {
		lightmode = 'Apex Legends logo lightmode.svg',
		darkmode = 'Apex Legends logo darkmode.svg',
	},
	metadesc = 'Comprehensive Apex Legends wiki with articles covering everything from weapons, to strategies, '..
		'to tournaments, to competitive players and teams.',
	title = 'Apex Legends',
	navigation = {
		{
			file = 'Fnatic at the ALGS Birmingham Championship.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'Falcons ImperialHal at the ALGS Mannheim Split 2 Playoffs.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'ALGS Raleigh Championship Trrophy.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'PVX ShunMi at the ALGS Birmingham Championship.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'NRG hodsic at the ALGS Mannheim Split 2 Playoffs.jpg',
			title = 'Statistics',
			link = 'Portal:Statistics',
		},
		{
			file = 'Alter Banner.png',
			title = 'Legends',
			link = 'Legends',
			count = {
				method = 'CATEGORY',
				category = 'Character',
			},
		},
		{
			file = 'Kings Canyon S3.png',
			title = 'Maps',
			link = 'Portal:Maps',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::map]]',
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
						mobileOrder = 8,
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
						mobileOrder = 4,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 5,
						content = CONTENT.headlines,
					},
					{
						mobileOrder = 7,
						content = CONTENT.usefulArticles,
					},
				},
			},
		},
	},
}
