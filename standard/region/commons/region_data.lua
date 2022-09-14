---
-- @Liquipedia
-- wiki=commons
-- page=Module:Region/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	aliases = {
		europe = 'eu',

		america = 'na',
		americas = 'na',
		['north america'] = 'na',
		['northern america'] = 'na',

		la = 'sa',
		sam = 'sa',
		['south america'] = 'sa',
		['southern america'] = 'sa',
		['latin america'] = 'sa',

		['middle america'] = 'central america',

		['southeast asia'] = 'sea',

		['australia/new zealand'] = 'oce',
		anz = 'oce',
		oceania = 'oce',

		['middle east'] = 'me',

		africa = 'af',

		['asia pacific'] = 'apac',
		['asia-pacific'] = 'apac',
		ap = 'apac',

		['malaysia/singapore/philippines'] = 'msp',
		['malaysia, singapore, philippines'] = 'msp',
		['malaysia, singapore, and the philippines'] = 'msp',
	},

	cis = {
		region = 'CIS',
		flag = 'cis',
	},
	eu = {
		region = 'Europe',
		flag = 'eu',
	},
	na = {
		region = 'North America',
		flag = 'north america',
	},
	sa = {
		region = 'South America',
		file = 'unasur.png',
	},
	['central america'] = {
		region = 'Central America',
		flag = 'central america',
	},
	sea = {
		region = 'Southeast Asia',
		flag = 'sea',
	},
	['south asia'] = {
		region = 'South Asia',
		flag = 'south asia',
	},
	['northeast asia'] = {
		region = 'Northeast Asia',
		flag = 'northeast asia',
	},
	oce = {
		region = 'Oceania',
		flag = 'anz',
	},
	me = {
		region = 'Middle East',
		flag = 'middle east',
	},
	af = {
		region = 'Africa',
		flag = 'africa',
	},
	asia = {
		region = 'Asia',
		flag = 'asia',
	},
	apac = {
		region = 'Asia Pacific',
		flag = 'asia',
	},
	msp = {
		region = 'MSP',
		flag = 'msp',
	},
}
