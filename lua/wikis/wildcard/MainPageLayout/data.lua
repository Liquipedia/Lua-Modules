---
-- @Liquipedia
-- wiki=wildcard
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CONTENT = {
	about = {
		heading = 'About Wildcard',
		body = '<nowiki>\n</nowiki>{{Main Page About}}',
		padding = true,
		boxid = 1502,
	},
	updates = {
		heading = 'Updates',
		body = '<nowiki>\n</nowiki>{{Main Page Updates}}',
		padding = true,
		boxid = 1503,
	},
	usefulArticles = {
		heading = 'Useful Articles',
		body = '{{Liquipedia:Useful Articles}}',
		padding = true,
		boxid = 1504,
	},
	wantToHelp = {
		heading = 'Want To Help?',
		body = '{{Liquipedia:Want_to_help}}',
		padding = true,
		boxid = 1505,
	},
	champions = {
		heading = 'Champions',
		body = '{{Liquipedia:championTable}}',
		padding = true,
		boxid = 1501,
	},
	wildcards = {
		heading = 'Wildcards',
		body = '{{Liquipedia:Wildcards}}',
		padding = true,
		boxid = 1506,
	},
		houses = {
		heading = 'Houses',
		body = '{{Liquipedia:Houses}}',
		padding = true,
		boxid = 1508,
	},
		summons = {
		heading = 'Summons',
		body = '{{SummonIconTable}}',
		padding = true,
		boxid = 1507,
	},
}

return {
	banner = {
		lightmode = 'Wildcard full lightmode.svg',
		darkmode = 'Wildcard full darkmode.svg',
	},
	metadesc = 'Comprehensive Wildcard wiki with articles covering everything from champions and summons, ' ..
		'to strategies, to tournaments, to competitive players, and teams.',
	title = 'The Wildcard Wiki',
	navigation = 	{
			{
			file = 'Wildcard gameasset wildcards pill.png',
			title = 'Wildcards',
			link = 'Portal:Wildcards',
		},
		{
			file = 'Wildcard Characters 2.jpg',
			title = 'Champions',
			link = 'Portal:Champions',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::character]]',
			},
		},
		{
			file = 'Wildcard Characters 1.jpg ',
			title = 'Summons',
			link = 'Portal:Summons',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::Summon]]',
			},
		},
		{
			file = 'Wildcard Lushland Arena.jpg',
			title = 'Arenas',
			link = 'Portal:Arenas',
			count = {
				method = 'LPDB',
				table = 'datapoint',
				conditions = '[[type::map]]',
			},
		},
		{
			file = 'Wildcard Frostburn Arena.jpg',
			title = 'Mechanics',
			link = 'Portal:Mechanics',
		},
		{
			file = 'Wildcard gameasset Wildcard Bulwark Boost.png',
			title = 'Decks',
			link = 'Portal:Decks',
		},
	},
	layouts = {
		main = {
			{ -- Left
				size = 6,
				children = {
										{
						mobileOrder = 1,
						content = CONTENT.about,
					},
					{
						mobileOrder = 2,
						content = CONTENT.champions,
					},
					{
						mobileOrder = 3,
						content = CONTENT.summons,
					},
					{
						mobileOrder = 5,
						content = CONTENT.wantToHelp,
					},
				}
			},
			{ -- Right
				size = 6,
				children = {
					{
						mobileOrder = 4,
						content = CONTENT.wildcards,
					},
										{
						mobileOrder = 5,
						content = CONTENT.houses,
					},
					{
						mobileOrder = 6,
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
