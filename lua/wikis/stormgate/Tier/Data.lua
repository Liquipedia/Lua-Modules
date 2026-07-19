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
			sort = 'A6',
			name = 'Misc',
			short = 'M.',
			link = 'Misc Tournaments',
			category = 'Misc Tournaments',
		},
		[''] = {
			value = nil,
			sort = 'E1',
			name = 'Undefined',
			short = '?',
		},
	},

	tierTypes = {
		monthly = {
			value = 'Monthly',
			sort = 'B1',
			name = 'Monthly',
			short = 'Mon.',
			link = 'Monthly Tournaments',
			category = 'Monthly Tournaments',
		},
		weekly = {
			value = 'Weekly',
			sort = 'B2',
			name = 'Weekly',
			short = 'Week.',
			link = 'Weekly Tournaments',
			category = 'Weekly Tournaments',
		},
		showmatch = {
			value = 'Showmatch',
			sort = 'B3',
			name = 'Showmatch',
			short = 'Showm.',
			link = 'Showmatches',
			category = 'Showmatch Tournaments',
		},
		qualifier = {
			value = 'Qualifier',
			sort = 'C1',
			name = 'Qualifier',
			short = 'Qual.',
			link = 'Qualifier Tournaments',
			category = 'Qualifier Tournaments',
		},
		charity = {
			value = 'Charity',
			sort = 'D1',
			name = 'Charity',
			short = 'Char.',
			category = 'Charity Tournaments',
		},
	},
}
