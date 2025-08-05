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
			link = 'Portal:Championships/Tier_1',
			category = 'Tier 1 Championships',
		},
		{
			value = '2',
			sort = 'A2',
			name = 'Tier 2',
			short = 'T2',
			link = 'Portal:Championships/Tier_2',
			category = 'Tier 2 Championships',
		},
		{
			value = '3',
			sort = 'A3',
			name = 'Tier 3',
			short = 'T3',
			link = 'Portal:Championships/Tier_3',
			category = 'Tier 3 Championships',
		},
		{
			value = '4',
			sort = 'A4',
			name = 'Regional',
			short = 'RE',
			link = 'Portal:Championships/Regionals',
			category = 'Regional Championships',
		},
		{
			value = '5',
			sort = 'A5',
			name = 'Tier 4',
			short = 'T4',
			link = 'Portal:Championships/Tier_4',
			category = 'Tier 4 Championships',
		},
		{
			value = '6',
			sort = 'A6',
			name = 'Electric',
			short = 'Electric',
			link = 'Portal:Championships/Electric',
			category = 'Electric Championships',
		},
		{
			value = '7',
			sort = 'A7',
			name = 'Karting',
			short = 'Karts',
			link = 'Portal:Championships/Karting',
			category = 'Karting Championships',
		},
		[-1] = {
			value = '-1',
			sort = 'A8',
			name = 'Misc',
			short = 'M.',
			link = 'Portal:Championships/Miscellaneous Events',
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
			category = 'Showmatch Events',
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
