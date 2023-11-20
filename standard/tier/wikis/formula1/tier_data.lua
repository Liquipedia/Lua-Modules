---
-- @Liquipedia
-- wiki=formula1
-- page=Module:Tier/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	tiers = {
		{
			value = '1',
			sort = 'A1',
			name = 'Formula 1',
			short = 'F1',
			link = 'Formula 1 Tournaments',
			category = 'Formula 1 Tournaments',
		},
		{
			value = '2',
			sort = 'A2',
			name = 'Formula 2',
			short = 'F2',
			link = 'Formula 2 Tournaments',
			category = 'Formula 2 Tournaments',
		},
		{
			value = '3',
			sort = 'A3',
			name = 'Formula 3',
			short = 'F3',
			link = 'Formula 3 Tournaments',
			category = 'Formula 3 Tournaments',
		},
		{
			value = '4',
			sort = 'A4',
			name = 'Formula Regional',
			short = 'FR',
			link = 'Formula Regional Tournaments',
			category = 'Formula Regional Tournaments',
		},
		{
			value = '5',
			sort = 'A5',
			name = 'Formula 4',
			short = 'F4',
			link = 'Formula 4 Tournaments',
			category = 'Formula 4 Tournaments',
		},
		{
			value = '6',
			sort = 'A6',
			name = 'Karting',
			short = 'Karts',
			link = 'Karting Tournaments',
			category = 'Karting Tournaments',
		},
		[''] = {
			value = nil,
			sort = 'B2',
			name = 'Undefined',
			short = '?',
		},
	},

	tierTypes = {
		grandprix = {
			value = 'Grand Prix',
			sort = 'A7',
			name = 'Grand Prix',
			short = 'GPs',
			link = 'Grands Prix',
			category = 'Grands Prix',
		},
		test = {
			value = 'Test',
			sort = 'A8',
			name = 'Test',
			short = 'Tests',
			link = 'Test Sessions',
			category = 'Test Sessions',
		},
		nonchampionship = {
			value = 'Non-Championship',
			sort = 'A9',
			name = 'Non-Championship',
			short = 'Non-Champs',
			link = 'Non-Championship Events',
			category = 'Non-Championship Events',
		},
		misc = {
			value = 'Misc',
			sort = 'A10',
			name = 'Misc',
			short = 'Misc',
			link = 'Miscellaneous Tournaments',
			category = 'Miscellaneous Tournaments',
		},
		showmatch = {
			value = 'Showmatch',
			sort = 'B1',
			name = 'Showmatch',
			short = 'Showm.',
			link = 'Showmatches',
			category = 'Showmatch Tournaments',
		},
	}
}
