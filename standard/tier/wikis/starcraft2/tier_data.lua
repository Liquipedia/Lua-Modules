---
-- @Liquipedia
-- wiki=starcraft2
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
		{
			value = '4',
			sort = 'A4',
			name = 'Basic',
			short = 'Basic',
			link = 'Basic Tournaments',
			category = 'Basic Tournaments',
		},
		[-1] = {
			value = '-1',
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
		daily = {
			value = 'Daily',
			sort = 'B5',
			name = 'Daily',
			short = 'Daily',
			category = 'Daily Tournaments',
		},
		['2v2'] = {
			value = '2v2',
			sort = 'B6',
			name = '2v2',
			short = '2v2',
			category = '2v2 Tournaments',
		},
		['3v3'] = {
			value = '3v3',
			sort = 'B6',
			name = '3v3',
			short = '3v3',
			category = '3v3 Tournaments',
		},
		['4v4'] = {
			value = '4v4',
			sort = 'B6',
			name = '4v4',
			short = '4v4',
			category = '4v4 Tournaments',
		},
		['1v2'] = {
			value = '1v2',
			sort = 'B6',
			name = '1v2',
			short = '1v2',
			category = '1v2 Tournaments',
		},
		archon = {
			value = 'Archon',
			sort = 'B6',
			name = 'Archon',
			short = 'Archon',
			category = 'Archon Tournaments',
		},
		ffa = {
			value = 'FFA',
			sort = 'B6',
			name = 'FFA',
			short = 'FFA',
			category = 'FFA Tournaments',
		},
		qualifier = {
			value = 'Qualifier',
			sort = 'B7',
			name = 'Qualifier',
			short = 'Qual.',
			category = 'Qualifier Tournaments',
		},
		charity = {
			value = 'Charity',
			sort = 'B8',
			name = 'Charity',
			short = 'Char.',
			category = 'Charity Tournaments',
		},
	},
}
