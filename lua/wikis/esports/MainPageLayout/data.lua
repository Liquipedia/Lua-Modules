---
-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

local WantToHelp = Lua.import('Module:Widget/MainPage/WantToHelp')

local CONTENT = {
	wantToHelp = {
		heading = 'Want To Help?',
		body = WantToHelp{},
		padding = true,
		boxid = 1504,
	},
	specialEvents = {
		noPanel = true,
		body = '{{Liquipedia:Special Event}}',
		boxid = 1516,
	},
	popularEsports = {
		heading = 'Popular Esports',
		body = '{{Liquipedia:Popular Esports}}',
		boxid = 1529,
	},
	tournaments = {
		heading = 'Tournaments',
		body = TournamentsTicker{
			upcomingDays = 365,
			completedDays = 365
		},
		padding = true,
		boxid = 1508,
	},
}

return {
	banner = {
		lightmode = 'Esports wiki full lightmode.svg',
		darkmode = 'Esports wiki full darkmode.svg',
	},
	metadesc = 'Comprehensive esports wiki with everything related to esports.',
	title = 'Esports',
	navigation = {
		{
			file = 'DreamHack Japan 2023 BYOC Stage.jpg',
			title = 'Games',
			link = 'Portal:Games',
			count = {
				method = 'CATEGORY',
				category = 'Games',
			},
		},
		{
			file = 'T1 Homeground 2025 Arena.jpg',
			title = 'Organizations',
			link = 'Portal:Organizations',
			count = {
				method = 'CATEGORY',
				category = 'Companies',
			},
		},
		{
			file = 'EA at the ALGS Sapporo Championship.jpg',
			title = 'Developers',
			link = 'Portal:Developers',
		},
		{
			file = 'ESL IEM Katowice 2014 World Championship Arena.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'CATEGORY',
				category = 'Tournaments',
			},
		},
		{
			file = 'DreamHack Japan 2023 Fighters Bracket.jpg',
			title = 'Tournament Formats',
			link = 'Portal:Tournament Formats',
		},
		{
			file = 'MSI 2025 Stage.jpg',
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
						mobileOrder = 4,
						content = CONTENT.transfers,
					},
					{
						mobileOrder = 5,
						content = CONTENT.thisDay,
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
										content = CONTENT.popularEsports,
									},
								},
							},
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
					{
						mobileOrder = 6,
						content = CONTENT.wantToHelp,
					},
				},
			},
			{
				children = {
					{
						mobileOrder = 7,
						content = CONTENT.theGame,
					},
				},
			},
		},
	},
}
