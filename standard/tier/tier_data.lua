---
-- @Liquipedia
-- wiki=commons
-- page=Module:Tier/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	tiers = {
		{
			order = 1,
			value = '1',
			sort = 'A1',
			name = 'S-Tier',
			short = 'S',
			link = 'S-Tier Tournaments',
			category = 'S-Tier Tournaments',
		},
		{
			order = 2,
			value = '2',
			sort = 'A2',
			name = 'A-Tier',
			short = 'A',
			link = 'A-Tier Tournaments',
			category = 'A-Tier Tournaments',
		},
		{
			order = 3,
			value = '3',
			sort = 'A3',
			name = 'B-Tier',
			short = 'B',
			link = 'B-Tier Tournaments',
			category = 'B-Tier Tournaments',
		},
		{
			order = 4,
			value = '4',
			sort = 'A4',
			name = 'C-Tier',
			short = 'C',
			link = 'C-Tier Tournaments',
			category = 'C-Tier Tournaments',
		},
		{
			order = 5,
			value = '5',
			sort = 'A5',
			name = 'D-Tier',
			short = 'D',
			link = 'D-Tier Tournaments',
			category = 'D-Tier Tournaments',
		},
		[''] = {
			order = 6,
			value = nil,
			sort = 'B2',
			name = 'Undefined',
			short = '?',
		},
	},

	tiertypes = {
		monthly = {
			order = 1,
			value = 'Monthly',
			sort = 'A6',
			name = 'Monthly',
			short = 'Mon.',
			link = 'Monthly Tournaments',
			category = 'Monthly Tournaments',
		},
		weekly = {
			order = 2,
			value = 'Weekly',
			sort = 'A7',
			name = 'Weekly',
			short = 'Week.',
			link = 'Weekly Tournaments',
			category = 'Weekly Tournaments',
		},
		qualifier = {
			order = 3,
			value = 'Qualifier',
			sort = 'A8',
			name = 'Qualifier',
			short = 'Qual.',
			link = 'Qualifier Tournaments',
			category = 'Qualifier Tournaments',
		},
		misc = {
			order = 4,
			value = 'Misc',
			sort = 'A9',
			name = 'Misc',
			short = 'Misc',
			link = 'Miscellaneous Tournaments',
			category = 'Miscellaneous Tournaments',
		},
		showmatch = {
			order = 5,
			value = 'Show Match',
			sort = 'B1',
			name = 'Show Match',
			short = 'Show&nbsp;M.',
			link = 'Show Matches',
			category = 'Show Match Tournaments',
		},
	},

	-- only for legacy conversion reasons
	tierToNumber = {
		['s-tier'] = 1,
		['a-tier'] = 2,
		['b-tier'] = 3,
		['c-tier'] = 4,
		['d-tier'] = 5,
	}
}
