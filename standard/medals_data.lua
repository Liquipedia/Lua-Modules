---
-- @Liquipedia
-- wiki=commons
-- page=Module:Medals/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	aliases = {
		-- numbered ordnials
		['1st'] = 1,
		['2nd'] = 2,
		['3rd'] = 3,
		['4th'] = 4,

		-- written ordinals
		['first'] = 1,
		['second'] = 2,
		['third'] = 3,
		['fourth'] = 4,

		-- medal names
		gold = 1,
		silver = 2,
		bronze = 3,
		copper = 4,

		-- medal name abbreviations
		g = 1,
		s = 2,
		b = 3,
		c = 4,

		-- various aliases for `'3-4'`
		['sf'] = '3-4',
		['3/4'] = '3-4',
		['semi'] = '3-4',
		['semifinal'] = '3-4',
		['semifinalist'] = '3-4',
		['semifinalists'] = '3-4',

		-- misc
		winner = 1,
		['runner-up'] = 2,
		qual = 'qualified',
	},

	medals = {
		{
			title = 'First Place',
			file = 'File:Gold.png',
		},
		{
			title = 'Second Place',
			file = 'File:Silver.png',
		},
		{
			title = 'Third Place',
			file = 'File:Bronze.png',
		},
		{
			title = 'Fourth Place',
			file = 'File:Copper.png',
		},
		['3-4'] = {
			title = 'Semifinalist(s)',
			file = 'File:SF.png',
		},
		qualified = {
			title = 'Qualified',
			file = 'File:Medal Icon qualified.png',
		},
	},
}