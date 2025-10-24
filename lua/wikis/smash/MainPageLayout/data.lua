---
-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DateExt = Lua.import('Module:Date/Ext')

local TournamentsList = Lua.import('Module:TournamentsList')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
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
			transferPage = 'Player Transfers/' .. DateExt.getYearOf()
		},
		boxid = 1509,
	},
	thisDay = {
		heading = ThisDayWidgets.Title(),
		body = ThisDayWidgets.Content(),
		padding = true,
		boxid = 1510,
	},
	tournaments = {
		heading = 'Tournaments',
		body = HtmlWidgets.Fragment{children = {
			TournamentsList.getFromLpdb(),
			HtmlWidgets.P{
				classes = {'mainpage-editlink'},
				children = HtmlWidgets.Small{children = {
					'&#91;',
					Link{link = 'Special:EditPage/Liquipedia:Tournaments/dynamic', children = 'edit'},
					'&#93;'
				}}
			}
		}},
		padding = true,
		boxid = 1508,
	},
}

return {
	banner = {
		lightmode = 'Smash default lightmode.png',
		darkmode = 'Smash default darkmode.png',
	},
	metadesc = 'The Smash wiki covering everything from competitive players, teams and transfers, to ' ..
		'tournaments, games, and characters.',
	title = 'Smash',
	navigation = {
		{
			file = 'IBDW SmashSummit12.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'Smash Summit 5 Cardboards.jpeg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'Hungrybox vs Mang0 GENESIS X.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
			{
			file = 'Melee GENESIS X.jpg',
			title = 'Melee Majors',
			link = 'Major_Tournaments/Melee',
		},
			{
			file = 'Ultimate GENESIS X.jpg',
			title = 'Ultimate Majors',
			link = 'Major_Tournaments/Ultimate',
		},
		{
			file = 'AMSa and Axe GENESIS X.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'Acola Trophy ultimate summit 5.jpeg',
			title = 'Statistics',
			link = 'Portal:Statistics',
		},
	},
	layouts = {
		main = {
			{ -- Left
				size = 7,
				children = {
					{
						mobileOrder = 2,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 3,
						content = CONTENT.transfers,
					},
					{
						mobileOrder = 6,
						content = CONTENT.wantToHelp,
					},
				}
			},
			{ -- Right
				size = 5,
				children = {
					{
						mobileOrder = 1,
						children = {
							{
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
			{ -- Bottom
				children = {
					{
						mobileOrder = 4,
						content = CONTENT.usefulArticles,
					},
				},
			},
		},
	},
}
