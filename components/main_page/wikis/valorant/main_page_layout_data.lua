---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CONTENT = {
	theGame = {
		heading = 'The Game',
		body = '{{Liquipedia:The Game}}',
		padding = true,
		boxid = 1503,
	},
	transfers = {
		heading = 'Transfers',
		body = '{{Transfer List|limit=15}}<div style="display:block; text-align:center; padding:0.5em;">' ..
			'<div style="display:inline; float:left; font-style:italic;">[[#Top|Back to top]]</div>' ..
			'<div style="display:inline; float:right;" class="plainlinks smalledit">' ..
			'&#91;[[Special:EditPage/Player Transfers/{{CURRENTYEAR}}/{{CURRENTMONTHNAME}}|edit]]&#93;</div>' ..
			'<div style="display:inline; margin:0 10px; white-space:nowrap; font-size:15px; font-style:italic;">' ..
			'[[Portal:Transfers|See more transfers]]<span style="font-style:normal; padding:0 5px;">&#8226;</span>' ..
			'[[Transfer query]]</div><div style="display:inline; margin:0 10px; white-space:nowrap; font-size:15px; ' ..
			'font-style:italic;">[[Special:RunQuery/Transfer|Input Form]]<span style="font-style:normal; ' ..
			'padding:0 5px;">&#8226;</span>[[Portal:Rumours|Rumours]]</div></div>',
		boxid = 1509,
	},
	specialEvents = {
		noPanel = true,
		body = '{{Liquipedia:Special Event}}',
	},
	filterButtons = {
		noPanel = true,
		body = '<div style{{=}}"width:100%;margin-bottom:8px;">' ..
			'{{#invoke:Lua|invoke|module=FilterButtons|fn=getFromConfig}}</div>',
	},
	matches = {
		heading = 'Matches',
		body = '{{#invoke:Lua|invoke|module=Widget/Factory|fn=fromTemplate|widget=Match/Ticker/Container}}' ..
			'<div style{{=}}"white-space:nowrap; display: block; margin:0 10px; font-size:15px; font-style:italic; ' ..
			'text-align:center;">[[Liquipedia:Matches|See more matches]]</div>',
		padding = true,
		boxid = 1507,
	},
	tournaments = {
		heading = 'Tournaments',
		body = '{{#invoke:Lua|invoke|module=Widget/Factory|fn=fromTemplate|widget=Tournaments/Ticker' ..
			'|upcomingDays=21|completedDays=14}}',
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
				conditions = '[[type::hero]]',
			},
		},
		{
			file = 'Stalk3r OWCS Finals 2024.jpeg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
			},
		},
		{
			file = 'Valorant-champions-seoul-2024.jpg',
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
						mobileOrder = 8,
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
