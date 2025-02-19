---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

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
		body = '{{Transfer List|limit=15}}\n<div style="display:block; text-align:center; padding:0.5em;">' ..
			'<div style="display:inline; float:left; font-style:italic;">[[#Top|Back to top]]</div>' ..
			'<div style="display:inline; float:right;" class="plainlinks smalledit">' ..
			'&#91;[[Special:EditPage/Player Transfers/{{CURRENTYEAR}}/{{CURRENTMONTHNAME}}|edit]]&#93;</div>' ..
			'<div style="white-space:nowrap; display:inline; font-size:15px; font-style:italic; font-weight:bold;">' ..
			'[[Portal:Transfers|See all Transfers]]<span style="font-style:normal; font-weight:normal; ' ..
			'padding:0 5px;">&#8226;</span>[[Transfer query]]<br><span style="font-style:normal; padding:0 5px;">' ..
			'&#8226;</span>[[Special:RunQuery/Transfer|Transfer Generator]]<span style="font-style:normal; padding:0 5px;">' ..
			'&#8226;</span>[[Portal:Rumours|Rumours]]</div></div>',
		boxid = 1509,
	},
	thisDay = {
		heading = 'This day in Overwatch <small id="this-day-date" style = "margin-left: 5px">' ..
			'({{#time:F}} {{Ordinal|{{#time:j}}}})</small>',
		body = '{{Liquipedia:This day}}',
		padding = true,
		boxid = 1509,
	},
	specialEvents = {
		noPanel = true,
		body = '{{Liquipedia:Special Event}}',
		boxid = 1510,
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
			'font-size:15px; font-style:italic; text-align:center;">' ..
			'[[Liquipedia:Matches|See more matches]]</div>',
		padding = true,
		boxid = 1507,
	},
	tournaments = {
		heading = 'Tournaments',
		body = '{{#invoke:Lua|invoke|module=Widget/Factory|fn=fromTemplate|widget=Tournaments/Ticker' ..
			'|upcomingDays=120|completedDays=30}}',
		boxid = 1508,
	},
}

return {
	banner = {
		lightmode = 'Overwatch-logo-lightmode.svg',
		darkmode = 'Overwatch-logo-darkmode.svg',
	},
	metadesc = 'Comprehensive Overwatch wiki with articles covering everything from heroes, to tournaments, ' ..
		'to competitive players and teams.',
	title = 'Overwatch',
	navigation = {
		{
			file = 'Team Falcons ChiYo at the 2024 Esports World Cup.jpg',
			title = 'Players',
			link = 'Portal:Players',
			count = {
				method = 'LPDB',
				table = 'player',
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
			file = 'NTMR Infekted at OWCS 2024 Finals.jpg',
			title = 'Transfers',
			link = 'Portal:Transfers',
			count = {
				method = 'LPDB',
				table = 'transfer',
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
			file = 'Overwatch Heroes NavCard image.jpg',
			title = 'Heroes',
			link = 'Portal:Heroes',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::character]]',
			},
		},
		{
			file = 'Kings row map.jpg',
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
				},
			},
			{
				children = {
					{
						mobileOrder = 7,
						content = CONTENT.usefulArticles,
					},
				},
			},
		},
	},
}
