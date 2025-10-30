---
-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Condition = Lua.import('Module:Condition')
local MainPageLayoutUtil = Lua.import('Module:MainPageLayout/Util')
local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local MatchTicker = Lua.import('Module:Widget/MainPage/MatchTicker')
local ThisDayWidgets = Lua.import('Module:Widget/MainPage/ThisDay')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')
local WantToHelp = Lua.import('Module:Widget/MainPage/WantToHelp')

local BooleanOperator = Condition.BooleanOperator
local Comparator = Condition.Comparator


local CONTENT = {
	usefulArticles = {
		heading = 'Useful Articles',
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
		body = '{{Liquipedia:Special Event}}',
		boxid = MainPageLayoutUtil.BoxId.SPECIAL_EVENTS,
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
		boxid = MainPageLayoutUtil.BoxId.MATCH_TICKER,
	},
	tournaments = {
		heading = 'Tournaments',
		body = TournamentsTicker{
			upcomingDays = 60,
			completedDays = 60,
		},
		padding = true,
		boxid = MainPageLayoutUtil.BoxId.TOURNAMENTS_TICKER,
	},
}

return {
	banner = {
		lightmode = 'Clash Royale allmode.png',
		darkmode = 'Clash Royale allmode.png',
	},
	metadesc = 'The Clash Royale wiki covering everything from players, teams and transfers, ' ..
		'to tournaments and results, strategies and cards.',
	title = 'Clash Royale',
	navigation = {
		{
			file = 'Mohamed_Light_CRL_2024_World_Finals.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'TL_Crl_World_Finals-2019.png',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'Mugi_CRL_2023_World_Finals.jpeg ',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'Clash_Royale_Classic_2018_Card_Illustration_allmode.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'Clash_Royale_Evergreen_Illustration_allmode.png',
			title = 'Cards ',
			link = 'Portal:Cards',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = Condition.Tree(BooleanOperator.all):add{
					Condition.Node(Condition.ColumnName('type'), Comparator.eq, 'card'),
					Condition.Tree(BooleanOperator.any):add{
						Condition.Node(Condition.ColumnName('extradata_type'), Comparator.eq, 'Troop'),
						Condition.Node(Condition.ColumnName('extradata_type'), Comparator.eq, 'Tower Troop'),
						Condition.Node(Condition.ColumnName('extradata_type'), Comparator.eq, 'Spell'),
						Condition.Node(Condition.ColumnName('extradata_type'), Comparator.eq, 'Building'),
					}
				}:toString()
			},
		},
		{
			file = 'Clash_Royale_Illustration_Card_Evolution.png',
			title = 'Evolved Cards',
			link = 'Portal:Evolved Cards',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = Condition.Tree(BooleanOperator.all):add{
					Condition.Node(Condition.ColumnName('type'), Comparator.eq, 'card'),
					Condition.Tree(BooleanOperator.any):add{
						Condition.Node(Condition.ColumnName('extradata_type'), Comparator.eq, 'Evolved Troop'),
						Condition.Node(Condition.ColumnName('extradata_type'), Comparator.eq, 'Evolved Tower Troop'),
						Condition.Node(Condition.ColumnName('extradata_type'), Comparator.eq, 'Evolved Spell'),
						Condition.Node(Condition.ColumnName('extradata_type'), Comparator.eq, 'Evolved Building'),
					}
				}:toString()
			},
		},
		{
			file = 'Clash_Royale_Illustration_Merge_Tactics.png',
			title = 'Merge Tactics',
			link = 'Portal:Merge Tactics',
		},
		{
			file = 'Nova_Crl_2018_World_Finals.jpg',
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
						content = CONTENT.transfers,
					},
					{
						mobileOrder = 6,
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
					{
						mobileOrder = 5,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 4,
						content = CONTENT.usefulArticles,
					},
				},
			},
		},
	},
}
