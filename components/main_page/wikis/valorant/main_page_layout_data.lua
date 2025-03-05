---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MatchTickerContainer = Lua.import('Module:Widget/Match/Ticker/Container')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')
local WidgetUtil = Lua.import('Module:Widget/Util')

local CONTENT = {
	theGame = {
		heading = 'The Game',
		body = '{{Liquipedia:The Game}}',
		padding = true,
		boxid = 1503,
	},
	transfers = {
		heading = 'Transfers',
		body = TransfersList{rumours = true},
		boxid = 1509,
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
		}
	},
	matches = {
		heading = 'Matches',
		body = WidgetUtil.collect(
			MatchTickerContainer{},
			Div{
				css = {
					['white-space'] = 'nowrap',
					display = 'block',
					margin = '0 10px',
					['font-size'] = '15px',
					['font-style'] = 'italic',
					['text-align'] = 'center',
				},
				children = { Link{ children = 'See more matches', link = 'Liquipedia:Matches'} }
			}
		),
		padding = true,
		boxid = 1507,
		panelAttributes = {
			['data-switch-group-container'] = 'countdown',
		},
	},
	tournaments = {
		heading = 'Tournaments',
		body = TournamentsTicker{
			upcomingDays = 21,
			completedDays = 14,
		},
		padding = true,
		boxid = 1508,
	},
}

return {
	banner = {
		lightmode = 'VALORANT.svg',
		darkmode = 'VALORANT-darkmode.svg',
	},
	metadesc = 'The VALORANT esports wiki covering everything from players, teams and transfers, ' ..
		'to tournaments and results, to maps, weapons, and agents.',
	title = 'VALORANT',
	navigation = {
		{
			file = 'ShopifyRebellion VCT Game Changers Championship 2024.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'Valorant-champions-seoul-2024.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'Valorant-champions-trophy-2024-2.jpeg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'Raze-lockin-2023.jpeg',
			title = 'Agents',
			link = 'Portal:Agents',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::character]]',
			},
		},
		{
			file = 'EDward Gaming VALORANT Masters Shanghai 2024.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'MIBR GC Coaches VCT GC Championship 2024.jpg',
			title = 'Statistics',
			link = 'Portal:Statistics',
		},
		{
			file = 'Sunset Map.png',
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
						mobileOrder = 2,
						content = CONTENT.specialEvents,
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
				},
			},
			{
				children = {
					{
						mobileOrder = 8,
						content = CONTENT.theGame,
					},
				},
			},
		},
	},
}
