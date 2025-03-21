---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DateExt = require('Module:Date/Ext')
local Lua = require('Module:Lua')

local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')
local RatingsDisplay = Lua.import('Module:Ratings/Display')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local MatchTicker = Lua.import('Module:Widget/MainPage/MatchTicker')
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')

local CONTENT = {
	theGame = {
		heading = 'The Game',
		body = '{{Liquipedia:The Game}}',
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
			transferPortal = 'Transfers',
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
	rlcsEvents = {
		noPanel = true,
		body = '{{Liquipedia:RLCS Events}}',
	},
	specialEvent = {
		noPanel = true,
		body = '{{Liquipedia:Special Event}}',
	},
	rating = {
		heading = 'Liquipedia Rating',
		body = RatingsDisplay.graph{id = 'rating'},
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
		body = TournamentsTicker{},
		padding = true,
		boxid = 1508,
	},
}

return {
	banner = {
		lightmode = 'Rocket League default lightmode.png',
		darkmode = 'Rocket League default darkmode.png',
	},
	metadesc = 'Comprehensive Rocket League wiki with articles covering everything from cars and maps, ' ..
		'to tournaments, to competitive players and teams.',
	title = 'Rocket League',
	navigation = {
		{
			file = 'RLCS Worlds 2024 LAN Michal Konkol zen.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'RLCS Worlds 2024 Media Day Rachel Mathews Team BDS.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = '',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'RLCS Worlds 2024 LAN Michal Konkol Bachi.jpg',
			title = 'Statistics',
			link = 'Portal:Statistics',
		},
		{
			file = 'RLCS Copenhagen Major 2024 LAN Adela Sznajder itachi.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = '',
			title = 'Help',
			link = 'Help:Contents',
		},
	},
	layouts = {
		main = {
			{ -- Left
				size = 6,
				children = {
					{
						mobileOrder = 1,
						content = CONTENT.rlcsEvents,
					},
					{
						mobileOrder = 2,
						content = CONTENT.specialEvent,
					},
					{
						mobileOrder = 4,
						content = CONTENT.transfers,
					},
					{
						mobileOrder = 7,
						content = CONTENT.wantToHelp,
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
					{
						mobileOrder = 5,
						content = CONTENT.rating,
					},
					{
						mobileOrder = 6,
						content = CONTENT.thisDay,
					},
				},
			},
			{
				children = {
					{
						mobileOrder = 8,
						content = CONTENT.theGame,
					}
				},
			},
		},
	},
}
