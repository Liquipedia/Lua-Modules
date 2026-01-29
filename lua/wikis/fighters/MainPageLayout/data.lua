---
-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MainPageLayoutUtil = Lua.import('Module:MainPageLayout/Util')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')
local WantToHelp = Lua.import('Module:Widget/MainPage/WantToHelp')

local CONTENT = {
	usefulArticles = {
		heading = 'The Fighting Game Community',
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
			transferPage = MainPageLayoutUtil.getYearlyTransferPage()
		},
		boxid = MainPageLayoutUtil.BoxId.TRANSFERS,
	},
	thisDay = {
		heading = ThisDayWidgets.Title(),
		body = ThisDayWidgets.Content(),
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.THIS_DAY,
	},
	specialEvents = {
		noPanel = true,
		body = '{{Liquipedia:Special_Event}}',
		boxid = MainPageLayoutUtil.BoxId.SPECIAL_EVENTS,
	},
	tournaments = {
		heading = 'Tournaments',
		body = Div{
			children = {
				mw.getCurrentFrame():preprocess('<tournaments />'),
				Div{
					classes = {'mainpage-editlink'},
					children = {
						mw.text.nowiki('['),
						Link{
							link = 'Special:EditPage/Liquipedia:Tournaments',
							children = mw.text.nowiki('edit')
						},
						mw.text.nowiki(']'),
					}
				}
			}
		},
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.TOURNAMENTS_TICKER,
	},
}

return {
	banner = {
		lightmode = 'Fighters-lightmode.svg',
		darkmode = 'Fighters-darkmode.svg',
	},
	metadesc = 'The Fighting Games wiki covering everything from players, teams and transfers, to ' ..
		'tournaments, strategies, games, and characters.',
	title = 'Fighting Games',
	navigation = {
		{
			file = 'Arslan Ash at EVO 2024.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'Bandits Gaming winning the 2023 SFL World Championship.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'EVO 2023 Crowd Shot.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
			{
			file = 'SonicFox and GO1 at EVO 2019.jpg',
			title = 'Recent Results',
			link = 'Recent_Tournament_Results',
		},
		{
			file = 'Mago_Daigo_Tokido_Team_Madcatz.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'Daigo_Umehara_LG_Cup_2012.jpg',
			title = 'Fighting Games',
			link = 'Portal:Fighting_Games',
		},
	},
	layouts = {
		main = {
			{ -- Left
				size = 7,
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
						mobileOrder = 4,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 5,
						content = CONTENT.wantToHelp,
					},
				}
			},
			{ -- Right
				size = 5,
				children = {
					{
						mobileOrder = 2,
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
						mobileOrder = 6,
						content = CONTENT.usefulArticles,
					},
				},
			},
		},
	},
}
