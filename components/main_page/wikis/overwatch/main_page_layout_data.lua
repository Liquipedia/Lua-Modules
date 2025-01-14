---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CONTENT = {
	wantToHelp = {
		heading = 'Want To Help?',
		body = '{{Liquipedia:Want_to_help}}',
		padding = true,
		boxid = 1504,
	},
	transfers = {
		heading = 'Transfers',
		body = '{{Transfer List|limit=15}}\n<div style{{=}}"display:block; text-align:center; padding:0.5em;">\n' ..
			'<div style{{=}}"display:inline; float:left; font-style:italic;">\'\'[[#Top|Back to top]]\'\'</div>\n' ..
			'<div style{{=}}"display:inline; float:right;" class="plainlinks smalledit">' ..
			'&#91;[{{FULLURL:Player Transfers/{{CURRENTYEAR}}/{{CURRENTMONTHNAME}}|action=edit}} edit]&#93;</div>\n' ..
			'<div style{{=}}"white-space:nowrap; display:inline; margin:0 10px font-size:15px; font-style:italic;">' ..
			'[[Portal:Transfers|See more transfers]]<span style="font-style:normal; padding:0 5px;">&#8226;</span>' ..
			'[[Transfer query]]<span style{{=}}"font-style:normal; padding:0 5px;">&#8226;</span>' ..
			'[[lpcommons:Special:RunQuery/Transfer|Input Form]]' ..
			'<span style="font-style:normal; padding:0 5px;">&#8226;</span>' ..
			'[[Portal:Rumours|Rumours]]</center></div>\n</div>',
		boxid = 1509,
	},
	thisDay = {
		heading = 'This day in Overwatch <small id="this-day-date" style = "margin-left: 5px">' ..
			'({{#time:F}} {{Ordinal|{{#time:j}}}})</small>',
		body = '{{Liquipedia:This day}}',
		padding = true,
		boxid = 1510,
	},
	specialEvents = {
		noPanel = true,
		body = '{{Liquipedia:Special Event}}',
		boxid = 1511,
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
		body = '{{#invoke:Lua|invoke|module=TournamentsList|fn=run|upcomingDays=120|' ..
			'completedDays=30|filterByTierTypes=true|useExternalFilters=true}}',
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
					content = CONTENT.specialEvents,
				},
								{
					mobileOrder = 6,
					content = CONTENT.thisDay,
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
			},
		},
	},
}
