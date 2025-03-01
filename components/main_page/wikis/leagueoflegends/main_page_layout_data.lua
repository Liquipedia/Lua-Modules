---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local TournamentsTicker = Lua.import('Module:Widget/Tournaments/Ticker')

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
		body = '{{Transfer List|limit=15|title=}}\n<div style{{=}}"display:block; text-align:center; padding:0.5em;">\n' ..
			'<div style{{=}}"display:inline; float:left; font-style:italic;">\'\'[[#Top|Back to top]]\'\'</div>\n' ..
			'<div style{{=}}"display:inline; float:right;" class="plainlinks smalledit">' ..
			'&#91;[[Special:EditPage/Player Transfers/{{CURRENTYEAR}}/{{CURRENTMONTHNAME}}|edit]]&#93;</div>\n' ..
			'<div style{{=}}"white-space:nowrap; display:inline; margin:0 10px font-size:15px; font-style:italic;">' ..
			'[[Portal:Transfers|See more transfers]]<span style="font-style:normal; padding:0 5px;">&#8226;</span>' ..
			'[[Transfer query]]<span style{{=}}"font-style:normal; padding:0 5px;">&#8226;</span>' ..
			'[[lpcommons:Special:RunQuery/Transfer|Input Form]]' ..
			'<span style="font-style:normal; padding:0 5px;">&#8226;</span>' ..
			'[[Portal:Rumours|Rumours]]</center></div>\n</div>',
		boxid = 1509,
	},
	thisDay = {
		heading = 'This day in League of Legends <small id="this-day-date" style = "margin-left: 5px">' ..
			'({{#time:F}} {{Ordinal|{{#time:j}}}})</small>',
		body = '{{Liquipedia:This day}}',
		padding = true,
		boxid = 1510,
	},
	specialEvents = {
		noPanel = true,
		body = '{{Liquipedia:Eventbox}}',
	},
	filterButtons = {
		noPanel = true,
		body = '<div style{{=}}"width:100%;margin-bottom:8px;">' ..
			'{{#invoke:Lua|invoke|module=Widget/Factory|fn=fromTemplate|widget=FilterButtons}}</div>',
	},
	matches = {
		heading = 'Matches',
		body = '{{#invoke:Lua|invoke|module=Widget/Factory|fn=fromTemplate|widget=Match/Ticker/Container}}' ..
			'<div style{{=}}"white-space:nowrap; display: block; margin:0 10px; ' ..
			'font-size:15px; font-style:italic; text-align:center;">[[Liquipedia:Matches|See more matches]]</div>',
		padding = true,
		boxid = 1507,
		panelAttributes = {
			['data-switch-group-container'] = 'countdown',
		},
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
	headlines = {
		heading = 'Headlines',
		body = '{{ExternalMediaList|subject=!|limit=4}}' ..
			'<div style{{=}}"display:block; text-align:center; padding:0.5em;">' ..
			'<div style{{=}}"white-space:nowrap; display:inline; margin:0 10px; font-size:15px; font-style:italic;">' ..
			'[[Portal:News|See all Headlines]]<span style{{=}}"font-style:normal; padding:0 5px;">&#8226;</span>' ..
			'[[Special:FormEdit/ExternalMediaLinks|Add a Headline]]</div></div>',
		padding = true,
		boxid = 1511,
	},
	references = {
		heading = 'References',
		body = '{{reflist|2}}',
		padding = true,
		boxid = 1512,
	},
}

return {
	banner = {
		lightmode = 'League of Legends full allmode.png',
		darkmode = 'League of Legends full allmode.png',
	},
	metadesc = 'Comprehensive League of Legends (LOL) wiki with articles covering everything from champions, ' ..
		'to strategies, to tournaments, to competitive players and teams.',
	title = 'League of Legends',
	navigation = {
		{
			file = 'DRX Deft Worlds 2022 Champion.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'T1 Worlds 2024.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'G2 Worlds 2024.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'Worlds Trophy 2024.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'T1 Worlds23 Skins Splash Art.jpg',
			title = 'Champions',
			link = 'Champions',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::hero]]',
			},
		},
		{
			file = 'LoL Patch 14.24 Art.jpg',
			title = 'Patches',
			link = 'Patches',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::patch]]',
			},
		},
		{
			file = 'Worlds 2024 Finalists.jpg',
			title = 'News',
			link = 'Portal:News',
			count = {
				method = 'LPDB',
				table = 'externalmedialink',
			},
		},
		{
			file = 'Gen.G Mata Worlds 2024.jpg',
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
						mobileOrder = 6,
						content = CONTENT.thisDay,
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
						mobileOrder = 5,
						content = CONTENT.headlines,
					},
					{
						mobileOrder = 8,
						content = CONTENT.usefulArticles,
					},
					{
						mobileOrder = 9,
						content = CONTENT.references,
					},
				},
			},
		},
	},
}
