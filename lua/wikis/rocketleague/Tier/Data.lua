---
-- @Liquipedia
-- page=Module:Tier/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	tiers = {
		{
			value = '1',
			sort = 'A1',
			name = 'S-Tier',
			short = 'S',
			link = 'S-Tier Tournaments',
			category = 'S-Tier Tournaments',
		},
		{
			value = '2',
			sort = 'A2',
			name = 'A-Tier',
			short = 'A',
			link = 'A-Tier Tournaments',
			category = 'A-Tier Tournaments',
		},
		{
			value = '3',
			sort = 'A3',
			name = 'B-Tier',
			short = 'B',
			link = 'B-Tier Tournaments',
			category = 'B-Tier Tournaments',
		},
		{
			value = '4',
			sort = 'A4',
			name = 'C-Tier',
			short = 'C',
			link = 'C-Tier Tournaments',
			category = 'C-Tier Tournaments',
		},
		{
			value = '5',
			sort = 'A5',
			name = 'D-Tier',
			short = 'D',
			link = 'D-Tier Tournaments',
			category = 'D-Tier Tournaments',
		},
		[-1] = {
			value = '-1',
			sort = 'C1',
			name = 'Misc',
			short = 'M.',
			link = 'Miscellaneous Tournaments',
			category = 'Misc Tournaments',
		},
		[''] = {
			value = nil,
			sort = 'B3',
			name = 'Undefined',
			short = '?',
		},
	},

	tierTypes = {
		monthly = {
			value = 'Monthly',
			sort = 'A6',
			name = 'Monthly',
			short = 'Mon.',
			link = 'Monthly Tournaments',
			category = 'Monthly Tournaments',
		},
		weekly = {
			value = 'Weekly',
			sort = 'A7',
			name = 'Weekly',
			short = 'Week.',
			link = 'Weekly Tournaments',
			category = 'Weekly Tournaments',
		},
		qualifier = {
			value = 'Qualifier',
			sort = 'A8',
			name = 'Qualifier',
			short = 'Qual.',
			link = 'Qualifier Tournaments',
			category = 'Qualifier Tournaments',
		},
		showmatch = {
			value = 'Showmatch',
			sort = 'B1',
			name = 'Showmatch',
			short = 'Showm.',
			link = 'Showmatches',
			category = 'Showmatch Tournaments',
		},
		school = {
			value = 'School',
			sort = 'B2',
			name = 'School',
			short = 'School',
			link = 'School Tournaments',
			category = 'School Tournaments',
		},
	},
}
