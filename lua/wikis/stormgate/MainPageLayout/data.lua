---
-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DateExt = Lua.import('Module:Date/Ext')

local MatchTickerContainer = Lua.import('Module:Widget/Match/Ticker/Container')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local FilterButtons = Lua.import('Module:Widget/FilterButtons')
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')
local WantToHelp = Lua.import('Module:Widget/MainPage/WantToHelp')

local CONTENT = {
	theGame = {
		heading = 'The Game',
		body = '{{Liquipedia:The Game}}',
		padding = true,
		boxid = 1503,
	},
	wantToHelp = {
		heading = 'Want To Help?',
		body = WantToHelp{},
		padding = true,
		boxid = 1504,
	},
	transfers = {
		heading = 'Transfers',
		body = TransfersList{
			transferQuery = false,
			onlyNotableTransfers = true,
			transferPage = 'Player Transfers/' .. DateExt.quarterOf{ordinalSuffix = true} .. ' Quarter ' .. os.date('%Y')
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
		boxid = 1516,
	},
	filterButtons = {
		noPanel = true,
		body = Div{
			css = {width = '100%', ['margin-bottom'] = '8px'},
			children = {FilterButtons()},
		},
	},
	matches = {
		heading = 'Matches',
		body = MatchTickerContainer{},
		padding = true,
		boxid = 1507,
		panelAttributes = {
			['data-switch-group-container'] = "countdown"
		},
	},
	tournaments = {
		heading = 'Tournaments',
		body = TournamentsTicker{
			upcomingDays = 60,
			completedDays = 60,
		},
		padding = true,
		boxid = 1508,
	},
}

return {
	banner = {
		lightmode = 'Stormgate full allmode.png',
		darkmode = 'Stormgate full allmode.png',
	},
	metadesc = 'Comprehensive Stormgate wiki with articles covering everything from units, heroes and buildings, ' ..
		'to strategies, to tournaments, to competitive players and teams.',
	title = 'Stormgate',
	navigation = {
		{
			file = 'PartinGMLGWinterCh2012.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'TeamStarTale.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'WCS 2014 Stage.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'WCSFall19 player handshake.jpg',
			title = 'Transfers',
			link = 'Portal:Player transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'Blizzcon2019 WCS2 catsers analyzing.jpg',
			title = 'Statistics',
			link = 'Portal:Statistics',
		},
		{
			file = 'Boneyard.jpg',
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
						mobileOrder = 6,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 4,
						content = CONTENT.transfers,
					},
					{
						mobileOrder = 8,
						content = CONTENT.wantToHelp,
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
				},
			},
			{
				children = {
					{
						mobileOrder = 9,
						content = CONTENT.theGame,
					},
				},
			},
		},
	},
}
