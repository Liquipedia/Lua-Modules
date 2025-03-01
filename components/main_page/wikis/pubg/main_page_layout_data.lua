---
-- @Liquipedia
-- wiki=pubg
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Ordinal = require('Module:Ordinal')

local FilterButtons = Lua.import('Module:FilterButtons')
local MatchTickerContainer = Lua.import('Module:Widget/Match/Ticker/Container')
local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Fragment = HtmlWidgets.Fragment
local Link = Lua.import('Module:Widget/Basic/Link')
local Small = HtmlWidgets.Small
local TransfersList = Lua.import('Module:Widget/MainPage/TransfersList')

local CONTENT = {
	usefulArticles = {
		heading = 'Useful Articles',
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
	transfers = {
		heading = 'Transfers',
		body = TransfersList {
			rumours = false,
			transferPage = function ()
				return 'Player Transfers/' .. os.date('%Y') .. '/' .. os.date('%B')
			end
		},
		boxid = 1509,
	},
	thisDay = {
		heading = Fragment{
			children = {
				'This day in PUBG ',
				Small{
					attributes = { id = 'this-day-date' },
					css = { ['margin-left'] = '5px' },
					children = { '(' .. os.date('%B') .. ' ' .. Ordinal.toOrdinal(tonumber(os.date('%d'))) .. ')' }
				}
			}
		},
		body = '{{Liquipedia:This day}}',
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
			children = { FilterButtons.getFromConfig() }
		}
	},
	matches = {
		heading = 'Matches',
		body = Fragment{
			children = {
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
			}
		},
		padding = true,
		boxid = 1507,
		panelAttributes = {
			['data-switch-group-container'] = 'countdown',
		},
	},
	tournaments = {
		heading = 'Tournaments',
		body = TournamentsTicker{
			upcomingDays = 90,
			completedDays = 60
		},
		padding = true,
		boxid = 1508,
	},
}

return {
	banner = {
		lightmode = 'PUBG 2021 default allmode.png',
		darkmode = 'PUBG 2021 default allmode.png',
	},
	metadesc = 'The PUBG esports wiki covering everything from players, teams and transfers, to ' ..
		'tournaments and results, maps, and weapons.',
	title = 'PUBG',
	navigation = {
		{
			file = 'KSV at IEM XII Katowice.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'T1 PUBG at EWC 2024.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'Danawa e-sports at EWC 2024.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'EWC 2024 PUBG Trophy closeup.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'ErangelNew.jpg',
			title = 'Maps',
			link = 'Portal:Maps',
			count = {
				method = 'CATEGORY',
				category = 'Maps',
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
						content = CONTENT.aboutEsport,
					},
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
					{
						mobileOrder = 5,
						content = CONTENT.thisDay,
					},
				},
			},
			{
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
