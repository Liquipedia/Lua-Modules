---
-- @Liquipedia
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
local MatchTicker = Lua.import('Module:Widget/MainPage/MatchTicker')
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
			transferPage = 'Player Transfers/' .. os.date('%Y') .. '/' ..
				DateExt.quarterOf{ ordinalSuffix = true } .. ' Quarter'
		},
		boxid = 1509,
	},
	thisDay = {
		heading = ThisDayWidgets.Title(),
		body = ThisDayWidgets.Content{ birthdayListPage = 'Birthday list' },
		padding = true,
		boxid = 1510,
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
	},
	tournaments = {
		heading = 'Tournaments',
		body = TournamentsTicker{
			upcomingDays = 60,
			completedDays = 60
		},
		padding = true,
		boxid = 1508,
	},
}

return {
	banner = {
		lightmode = 'Dota_Underlords full lightmode.png',
		darkmode = 'Dota_Underlords full darkmode.png',
	},
	metadesc = 'Comprehensive Dota Underlords wiki with articles covering everything from heroes, ' ..
		'to strategies, to tournaments, to competitive players and teams.',
	title = 'Dota Underlords',
	navigation = {
		{
			file = '1437 SL i-League.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'T1 TFT EWC 2024.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'Scarra and BoxBox TFT Macao Open 2024.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'The International 2016.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'Gyrocopter underlords.png',
			title = 'Heroes',
			link = 'Portal:Heroes',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::hero]]',
			},
		},
		{
			file = 'Underlords Champion Alliance.png',
			title = 'Alliances',
			link = 'Portal:Alliances',
			count = {
				method = 'CATEGORY',
				category = 'Alliances',
			},
		},
	},
	layouts = {
		main = {
			{ -- Left
				size = 6,
				children = {
					{
						mobileOrder = 2,
						content = CONTENT.transfers,
					},
					{
						mobileOrder = 3,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 4,
						content = CONTENT.wantToHelp,
					},
				}
			},
			{ -- Right
				size = 6,
				children = {
					{
						mobileOrder = 1,
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
						content = CONTENT.theGame,
					},
				},
			},
		},
	},
}
