---
-- @Liquipedia
-- wiki=tft
-- page=Module:Tier/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	tiers = {
		{
			value = '1',
			sort = 'A1',
			name = 'Tier 1',
			short = '1',
			link = 'Tier 1 Tournaments',
			category = 'Tier 1 Tournaments',
		},
		{
			value = '2',
			sort = 'A2',
			name = 'Tier 2',
			short = '2',
			link = 'Tier 2 Tournaments',
			category = 'Tier 2 Tournaments',
		},
		{
			value = '3',
			sort = 'A3',
			name = 'Tier 3',
			short = '3',
			link = 'Tier 3 Tournaments',
			category = 'Tier 3 Tournaments',
		},
		[''] = {
			value = nil,
			sort = 'D1',
			name = 'Undefined',
			short = '?',
		},

		-- for legacy reasons until tft switches to standardized tier/tiertype
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
			link = 'Show Matches',
			category = 'Showmatch Tournaments',
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
			link = 'Show Matches',
			category = 'Showmatch Tournaments',
		},
	},
}
