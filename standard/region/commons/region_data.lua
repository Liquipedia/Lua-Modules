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

		['middle east north africa'] = 'mena',

		africa = 'af',

		['asia pacific'] = 'apac',
		['asia-pacific'] = 'apac',
		ap = 'apac',

		['malaysia/singapore/philippines'] = 'msp',
		['malaysia, singapore, philippines'] = 'msp',
		['malaysia, singapore, and the philippines'] = 'msp',

		['latin america north'] = 'latam north',
		['latin america south'] = 'latam south',

		['apacn'] = 'apac north',
		['asia pacific north'] = 'apac north',
		['asia-pacific north'] = 'apac north',

		['apacs'] = 'apac south',
		['asia pacific south'] = 'apac south',
		['asia-pacific south'] = 'apac south',

		['ssa'] = 'sub-saharan africa',
		['sub saharan africa'] = 'sub-saharan africa',

		['global'] = 'world',

		-- "country" regions
		kr = 'korea',
		sk = 'korea',
		['south korea'] = 'korea',

		tr = 'turkey',
		tw = 'taiwan',
		jp = 'japan',
		br = 'brazil',
		vn = 'vietnam',
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
	['latin america'] = {
		region = 'Latin America',
		flag = 'latin america',
	},
	['latam north'] = {
		region = 'Latin America North',
		flag = 'latin america north',
	},
	['latam south'] = {
		region = 'Latin America South',
		flag = 'latin america south',
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
	['east asia'] = {
		region = 'East Asia',
		flag = 'east asia',
	},
	['central asia'] = {
		region = 'Central Asia',
		flag = 'central asia',
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
		region = 'Asia-Pacific',
		flag = 'asia-pacific',
	},
	['apac north'] = {
		region = 'Asia-Pacific North',
		flag = 'asia-pacific',
	},
	['apac south'] = {
		region = 'Asia-Pacific South',
		flag = 'asia-pacific',
	},
	['pacific'] = {
		region = 'Pacific',
		flag = 'asia',
	},
	msp = {
		region = 'MSP',
		flag = 'msp',
	},
	benelux = {
		region = 'Benelux',
		flag = 'benelux',
	},
	iberia = {
		region = 'Iberia',
		flag = 'iberia',
	},
	['nordic countries'] = {
		region = 'Nordic Countries',
		flag = 'nordic countries',
	},
	arabia = {
		region = 'Arabia',
		flag = 'arabia',
	},
	['arab states'] = {
		region = 'Arab States',
		flag = 'arab states',
	},
	levant = {
		region = 'Levant',
		flag = 'levant',
	},
	mena = {
		region = 'MENA',
		flag = 'mena',
	},
	['persian gulf states'] = {
		region = 'Persian Gulf States',
		flag = 'persian gulf states',
	},
	['sub-saharan africa'] = {
		region = 'Sub-Saharan Africa',
		flag = 'sub saharan africa',
	},
	['north africa'] = {
		region = 'North Africa',
		flag = 'north africa',
	},
	world = {
		region = 'World',
		flag = 'world',
	},

	-- "country" regions
	china = {
		region = 'China',
		flag = 'china',
	},
	korea = {
		region = 'Korea',
		flag = 'south korea',
	},
	turkey = {
		region = 'Turkey',
		flag = 'turkey',
	},
	taiwan = {
		region = 'Taiwan',
		flag = 'taiwan',
	},
	japan = {
		region = 'Japan',
		flag = 'japan',
	},
	brazil = {
		region = 'Brazil',
		flag = 'brazil',
	},
	vietnam = {
		region = 'Vietnam',
		flag = 'vietnam',
	},
}
