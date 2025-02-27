---
-- @Liquipedia
-- wiki=marvelrivals
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CONTENT = {
	updates = {
		heading = 'Updates',
		body = '<nowiki>\n</nowiki>{{Main Page Updates}}',
		padding = true,
		boxid = 1502,
	},
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
		body = '{{Transfer List|limit=15}}\n' ..
		'<div style{{=}}"display:block; text-align:center; padding:0.5em;">\n' ..
			'<div style{{=}}"display:inline; float:left; font-style:italic;">\'\'[[#Top|Back to top]]\'\'</div>\n' ..
			'<div style{{=}}"display:inline; float:right;" class="plainlinks smalledit">' ..
			'&#91;[{{FULLURL:Player Transfers/{{CURRENTYEAR}}|action=edit}} edit]&#93;</div>\n' ..
			'<div style{{=}}"white-space:nowrap; display:inline; margin:0 10px font-size:15px; font-style:italic;">' ..
			'[[Portal:Transfers|See more transfers]]<span style="font-style:normal; padding:0 5px;">&#8226;</span>' ..
			'[[Transfer query]]<span style{{=}}"font-style:normal; padding:0 5px;">&#8226;</span>' ..
			'[[lpcommons:Special:RunQuery/Transfer|Input Form]]' ..
			'<span style="font-style:normal; padding:0 5px;">&#8226;</span>' ..
			'[[Portal:Rumours|Rumours]]</center></div>\n</div>',
		boxid = 1509,
	},
	thisDay = {
		heading = 'This day in Marvel Rivals <small id="this-day-date" style = "margin-left: 5px">' ..
			'({{#time:F}} {{Ordinal|{{#time:j}}}})</small>',
		body = '{{Liquipedia:This day}}',
		padding = true,
		boxid = 1510,
	},
	heroes = {
		heading = 'Heroes',
		body = '{{Liquipedia:HeroTable}}',
		padding = true,
		boxid = 1501,

	},
	filterButtons = {
		noPanel = true,
		body = '<div style{{=}}"width:100%;margin-bottom:8px;">' ..
			'{{#invoke:Lua|invoke|module=FilterButtons|fn=getFromConfig}}</div>',
	},
	matches = {
		heading = 'Matches',
		body = '{{#invoke:Lua|invoke|module=Widget/Factory|fn=fromTemplate|widget=Match/Ticker/Container}}' ..
			'<div style{{=}}"white-space:nowrap; display: block; margin:0 10px; ' ..
			'font-size:15px; font-style:italic; text-align:center;">[[Liquipedia:Matches|See more matches]]</div>',
		padding = true,
		boxid = 1507,
	},
	tournaments = {
		heading = 'Tournaments',
		body = '{{#invoke:Lua|invoke|module=Widget/Factory|fn=fromTemplate|widget=Tournaments/Ticker' ..
			'|upcomingDays=60|completedDays=20}}',
		padding = true,
		boxid = 1508,
	},
}

return {
	banner = {
		lightmode = 'Marvel Rivals full lightmode.png',
		darkmode = 'Marvel Rivals full darkmode.png',
	},
	metadesc = 'Comprehensive Marvel Rivals wiki with articles covering everything from heroes and maps, ' ..
	'to strategies, to tournaments, to competitive players, and teams.',
	title = 'The Marvel Rivals Wiki',
	navigation = {
		{
			file = 'Marvel Rivals gameasset Patches allmode.jpg',
			title = 'Patches',
			link = 'Portal:Patches',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::patch]]',
			},
		},
		{
			file = 'Marvel_Rivals_teamup_banner_Planet_X_Pals.png',
			title = 'Heroes',
			link = 'Portal:Heroes',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::character]]',
			},
		},
		{
			file = 'Marvel_Rivals_map_Royal_Palace.jpg',
			title = 'Maps',
			link = 'Portal:Maps',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::map]]',
			},
		},
		{
			file = 'Marvel_Rivals_icon_Planet_x_Pals.png',
			title = 'Mechanics',
			link = 'Mechanics',
			count = {
				method = 'CATEGORY',
				category = 'Mechanics',
			},
		},
		{
			file = 'OWCS Stockholm 2024 Trophy.jpg',
			title = 'Tournaments',
			link = 'Portal:Tournaments',
			count = {
				method = 'LPDB',
				table = 'tournament',
			},
		},
		{
			file = 'Crazy Raccoon 2024 Esports World Cup Champions.jpg',
			title = 'Teams',
			link = 'Portal:Teams',
			count = {
				method = 'LPDB',
				table = 'team',
			},
		},
		{
			file = 'SparkR OWCS Major 2024.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'NTMR Infekted at OWCS 2024 Finals.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
			},
		},
		{
			file = 'NRG hodsic at the ALGS Mannheim Split 2 Playoffs.jpg',
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
						content = CONTENT.heroes,
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
					{
						mobileOrder = 6,
						content = CONTENT.thisDay,
					},
					{
						mobileOrder = 5,
						content = CONTENT.updates,
					},
					{
						mobileOrder = 7,
						content = CONTENT.usefulArticles,
					},
				},
			},
		},
	},
}
