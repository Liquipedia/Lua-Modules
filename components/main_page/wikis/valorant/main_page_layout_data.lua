---
-- @Liquipedia
-- wiki=valorant
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
	transfers = {
		heading = 'Transfers',
		body = '{{Transfer List|limit=15}}\n<div style{{=}}"display:block; text-align:center; padding:0.5em;">\n' ..
			'<div style{{=}}"display:inline; float:left; font-style:italic;">\'\'[[#Top|Back to top]]\'\'</div>\n' ..
			'<div style{{=}}"display:inline; float:right;" class="plainlinks smalledit">' ..
			'&#91;[{{FULLURL:Player Transfers/{{CURRENTYEAR}}/{{CURRENTMONTHNAME}}|action=edit}} edit]&#93;</div>\n' ..
			'<div style{{=}}"white-space:nowrap; display:inline; margin:0 10px font-size:15px; font-style:italic;">' ..
			'[[Portal:Transfers|See more transfers]]<span style="font-style:normal; padding:0 5px;">&#8226;</span>' ..
			'[[Special:RunQuery/Transfer_history|Transfer query]]<span style{{=}}"font-style:normal; padding:0 5px;">&#8226;</span>' ..
			'[[lpcommons:Special:RunQuery/Transfer|Input Form]]' ..
			'<span style="font-style:normal; padding:0 5px;">&#8226;</span>' ..
			'[[Portal:Rumours|Rumours]]</center></div>\n</div>',
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
		body = '{{MainPageMatches}}<div style{{=}}"white-space:nowrap; display: block; margin:0 10px; ' ..
			'font-size:15px; font-style:italic; text-align:center;">[[Liquipedia:Matches|See more matches]]</div>',
		padding = true,
		boxid = 1507,
	},
	tournaments = {
		heading = 'Tournaments',
		body = '{{#invoke:Lua|invoke|module=TournamentsList|fn=run|defaultTiers=1,2,3|upcomingDays=21|' ..
			'concludedDays=14|ignoreTiers=-1|filterByTierTypes=true|useExternalFilters=true}}',
		padding = true,
		boxid = 1508,
	},
}

return {
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
	},
}
