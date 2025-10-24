---
-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DateExt = Lua.import('Module:Date/Ext')

local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local MatchTicker = Lua.import('Module:Widget/MainPage/MatchTicker')
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')
local WantToHelp = Lua.import('Module:Widget/MainPage/WantToHelp')

local CONTENT = {
	usefulArticles = {
		heading = 'Useful Articles',
		body = '{{Liquipedia:Useful Articles}}',
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
			transferPage = 'Player Transfers/' .. DateExt.getYearOf() .. '/' ..
				DateExt.quarterOf{ ordinalSuffix = true } .. ' Quarter'
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
			upcomingDays = 30,
			completedDays = 20,
			modifierTypeQualifier = -2,
			modifierTier1 = 55,
			modifierTier2 = 55,
			modifierTier3 = 10
		},
		padding = true,
		boxid = 1508,
	},
}

return {
	banner = {
		lightmode = 'Tetris allmode.png',
		darkmode = 'Tetris allmode.png',
	},
	metadesc = 'The Tetris wiki covering everything from players, teams and transfers, ' ..
		'to tournaments and results, strategies, and games.',
	title = 'Tetris',
	navigation = {
		{
			file = 'Dog CTWC2024.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'Meme vs Alex T - CTWC 2025.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'CTWC 2025 Trophies.jpg',
			title = 'Classic Tournaments',
			link = 'S-Tier_Tournaments/Classic',
		},
		{
			file = 'TETRIS Modern banner image.JPG',
			title = 'Modern Tournaments',
			link = 'S-Tier_Tournaments/Modern',
		},
		{
			file = 'SNES Signed - CTWC 2025.jpg',
			title = 'Games',
			link = 'Portal:Games',
		},
		{
			file = 'Tetris on a CRT at 2024 CTWC.jpg',
			title = 'Statistics',
			link = 'Portal:Statistics',
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
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 4,
						content = CONTENT.transfers,
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
						content = CONTENT.usefulArticles,
					},
										{
						mobileOrder = 6,
						content = CONTENT.wantToHelp,
					},
				},
			},
		},
	},
}
