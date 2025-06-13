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
			name = 'Tier 1',
			short = 'T1',
			link = 'Tier 1 Tournaments',
			category = 'Tier 1 Tournaments',
		},
		{
			value = '2',
			sort = 'A2',
			name = 'Tier 2',
			short = 'T2',
			link = 'Tier 2 Tournaments',
			category = 'Tier 2 Tournaments',
		},
		{
			value = '3',
			sort = 'A3',
			name = 'Tier 3',
			short = 'T3',
			link = 'Tier 3 Tournaments',
			category = 'Tier 3 Tournaments',
		},
		{
			value = '4',
			sort = 'A4',
			name = 'Regional',
			short = 'RE',
			link = 'Regional Tournaments',
			category = 'Regional Tournaments',
		},
		{
			value = '5',
			sort = 'A5',
			name = 'Tier 4',
			short = 'T4',
			link = 'Tier 4 Tournaments',
			category = 'Tier 4 Tournaments',
		},
		{
			value = '6',
			sort = 'A6',
			name = 'Electric',
			short = 'Electric',
			link = 'Electric Tournaments',
			category = 'Electric Tournaments',
		},
		{
			value = '7',
			sort = 'A7',
			name = 'Karting',
			short = 'Karts',
			link = 'Karting Tournaments',
			category = 'Karting Tournaments',
		},
		[-1] = {
			value = '-1',
			sort = 'A8',
			name = 'Misc',
			short = 'M.',
			link = 'Miscellaneous Events',
			category = 'Miscellaneous Events',
		},
		[''] = {
			value = nil,
			sort = 'B5',
			name = 'Undefined',
			short = '?',
		},
	},

	tierTypes = {
		grandprix = {
			value = 'Grand Prix',
			sort = 'A9',
			name = 'Grand Prix',
			short = 'GPs',
			link = 'Grands Prix',
			category = 'Grands Prix',
		},
		test = {
			value = 'Test',
			sort = 'B1',
			name = 'Test',
			short = 'Tests',
			link = 'Test Sessions',
			category = 'Test Sessions',
		},
		nonchampionship = {
			value = 'Non-Championship',
			sort = 'B2',
			name = 'Non-Championship',
			short = 'Non-Champs',
			link = 'Non-Championship Events',
			category = 'Non-Championship Events',
		},
		showmatch = {
			value = 'Showmatch',
			sort = 'B3',
			name = 'Showmatch',
			short = 'Showm.',
			link = 'Showmatches',
			category = 'Showmatch Tournaments',
		},
		award = {
			value = 'Awards',
			sort = 'B4',
			name = 'Awards',
			short = 'Awards',
			link = 'Awards Shows',
			category = 'Awards Shows',
		},
	}
}
