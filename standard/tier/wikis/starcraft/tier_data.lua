---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Tier/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	tiers = {
		{
			value = '1',
			sort = 'A1',
			name = 'Premier',
			short = 'Prem.',
			link = 'Premier Tournaments',
			category = 'Premier Tournaments',
		},
		{
			value = '2',
			sort = 'A2',
			name = 'Major',
			short = 'Maj.',
			link = 'Major Tournaments',
			category = 'Major Tournaments',
		},
		{
			value = '3',
			sort = 'A3',
			name = 'Minor',
			short = 'Min.',
			link = 'Minor Tournaments',
			category = 'Minor Tournaments',
		},
		[-1] = {
			value = '9',
			sort = 'A5',
			name = 'Misc',
			short = 'Misc',
		},
		[''] = {
			value = nil,
			sort = 'D1',
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
			category = 'Monthly Tournaments',
		},
		weekly = {
			value = 'Weekly',
			sort = 'B2',
			name = 'Weekly',
			short = 'Week.',
			category = 'Weekly Tournaments',
		},
		biweekly = {
			value = 'Biweekly',
			sort = 'B3',
			name = 'Biweekly',
			short = 'Biw.',
			category = 'Biweekly Tournaments',
		},
		showmatch = {
			value = 'Showmatch',
			sort = 'B4',
			name = 'Showmatch',
			short = 'Showm.',
			category = 'Showmatch Tournaments',
		},
		qualifier = {
			value = 'Qualifier',
			sort = 'B5',
			name = 'Qualifier',
			short = 'Qual.',
			category = 'Qualifier Tournaments',
		},
		charity = {
			value = 'Charity',
			sort = 'B6',
			name = 'Charity',
			short = 'Char.',
			category = 'Charity Tournaments',
		},
	},
}
