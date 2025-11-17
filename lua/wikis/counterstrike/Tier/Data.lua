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
			sort = 'C2',
			name = 'Undefined',
			short = '?',
		},
	},

	tierTypes = {
		monthly = {
			value = 'Monthly',
			sort = 'A7',
			name = 'Monthly',
			short = 'Mon.',
			link = 'Monthly Tournaments',
			category = 'Monthly Tournaments',
			prioTierType = false,
		},
		weekly = {
			value = 'Weekly',
			sort = 'A8',
			name = 'Weekly',
			short = 'Week.',
			link = 'Weekly Tournaments',
			category = 'Weekly Tournaments',
			prioTierType = false,
		},
		qualifier = {
			value = 'Qualifier',
			sort = 'A9',
			name = 'Qualifier',
			short = 'Qual.',
			link = 'Qualifier Tournaments',
			category = 'Qualifier Tournaments',
			prioTierType = true,
		},
		showmatch = {
			value = 'Showmatch',
			sort = 'B2',
			name = 'Showmatch',
			short = 'Showm.',
			link = 'Showmatches',
			category = 'Showmatch Tournaments',
			prioTierType = true,
		},
		points = {
			value = 'Points',
			sort = 'B1',
			name = 'Points',
			short = 'Points',
			link = 'Point Rankings',
			category = 'Point Rankings',
			prioTierType = true,
		},
		ladder = {
			value = 'Ladder',
			sort = 'B3',
			name = 'Ladder',
			short = 'Ladder',
			link = 'Ladder Tournaments',
			category = 'Ladder Tournaments',
			prioTierType = true,
		},
		onlinestage = {
			value = 'Online Stage',
			sort = 'A6',
			name = 'Online Stage',
			short = 'Online',
			link = 'Online Stages',
			category = 'Tournament Online Stages',
			prioTierType = false,
		},
	}
}
