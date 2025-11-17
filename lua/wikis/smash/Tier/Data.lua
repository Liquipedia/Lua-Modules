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
			name = 'National',
			short = 'Nat.',
			category = 'National Tournaments',
		},
		-- this is a proper (4th) tier and does not indicate missing tier
		{
			value = '4',
			sort = 'A4',
			name = 'No Tier',
			short = 'None',
			link = 'No Tier Tournaments',
			category = 'No Tier Tournaments',
		},
		-- `-99` denotes tournament overview pages
		[-99] = {
			value = '-99',
			sort = 'D1',
			name = 'Multi game',
			short = 'Multi',
		},
		-- legacy??? to be replaced by `-1` ???
		[''] = {
			value = nil,
			sort = 'D1',
			name = 'Undefined',
			short = '?',
		},
	},

	tierTypes = {
		invitational = {
			value = 'Invitational',
			sort = 'B1',
			name = 'Invitational',
			short = 'Inv.',
			category = 'Invitational Tournaments',
		},
		monthly = {
			value = 'Monthly',
			sort = 'B2',
			name = 'Monthly',
			short = 'Mon.',
			category = 'Monthly Tournaments',
		},
		bimonthly = {
			value = 'Bimonthly',
			sort = 'B3',
			name = 'Bimonthly',
			short = 'Bim.',
			category = 'Bimonthly Tournaments',
		},
		weekly = {
			value = 'Weekly',
			sort = 'B4',
			name = 'Weekly',
			short = 'Week.',
			category = 'Weekly Tournaments',
		},
		biweekly = {
			value = 'Biweekly',
			sort = 'B5',
			name = 'Biweekly',
			short = 'Biw.',
			category = 'Biweekly Tournaments',
		},
		crews = {
			value = 'Crews',
			sort = 'B6',
			name = 'Crews',
			short = 'Crw.',
			category = 'Crews Tournaments',
		},
		doubles = {
			value = 'Doubles',
			sort = 'B7',
			name = 'Doubles',
			short = 'Dbl.',
			category = 'Doubles Tournaments',
		},
		exhibition = {
			value = 'Exhibition',
			sort = 'B8',
			name = 'Exhibition',
			short = 'Exhib.',
			category = 'Exhibition Tournaments',
		},
		regional = {
			value = 'Regional',
			sort = 'B9',
			name = 'Regional',
			short = 'Reg.',
			category = 'Regional Tournaments',
		},
		arcadian = {
			value = 'Arcadian',
			sort = 'C2',
			name = 'Arcadian',
			short = 'Arcdn.',
			category = 'Arcadian Tournaments',
		},
		qualifier = {
			value = 'Qualifier',
			sort = 'C1',
			name = 'Qualifier',
			short = 'Qual.',
			category = 'Qualifier Tournaments',
		},
	},
}
