---
-- @Liquipedia
-- page=Module:Ordinal/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local position = {
	'one',
	'two',
	'three',
	'four',
	'five',
	'six',
	'seven',
	'eight',
	'nine',
	'ten',
	'eleven',
	'twelve',
	'thirteen',
	'fourteen',
	'fifteen',
	'sixteen',
	'seventeen',
	'eighteen',
	'nineteen',
}

local positionOrdinal = {
	'first',
	'second',
	'third',
	'fourth',
	'fifth',
	'sixth',
	'seventh',
	'eighth',
	'ninth',
	'tenth',
	'eleventh',
	'twelfth',
	'thirteenth',
	'fourteenth',
	'fifteenth',
	'sixteenth',
	'seventeenth',
	'eighteenth',
	'nineteenth',
}

local positionTens = {
	[2] = 'twenty',
	[3] = 'thirty',
	[4] = 'forty',
	[5] = 'fifty',
	[6] = 'sixty',
	[7] = 'seventy',
	[8] = 'eighty',
	[9] = 'ninety'
}

local positionTensOrdinal = {
	[2] = 'twentieth',
	[3] = 'thirtieth',
	[4] = 'fortieth',
	[5] = 'fiftieth',
	[6] = 'sixtieth',
	[7] = 'seventieth',
	[8] = 'eightieth',
	[9] = 'ninetieth'
}

local groups = {
	'thousand',
	'million',
	'billion',
	'trillion',
	'quadrillion',
	'quintillion',
	'sextillion',
	'septillion',
	'octillion',
	'nonillion',
	'decillion',
	'undecillion',
	'duodecillion',
	'tredecillion',
	'quattuordecillion',
	'quindecillion',
	'sexdecillion',
	'septendecillion',
	'octodecillion',
	'novemdecillion',
	'vigintillion',
	'unvigintillion',
	'duovigintillion',
	'tresvigintillion',
	'quattuorvigintillion',
	'quinquavigintillion',
	'sesvigintillion',
	'septemvigintillion',
	'octovigintillion',
	'novemvigintillion',
	'trigintillion',
	'untrigintillion',
	'duotrigintillion',
	'trestrigintillion',
	'quattuortrigintillion',
	'quinquatrigintillion',
	'sestrigintillion',
	'septentrigintillion',
	'octotrigintillion',
	'noventrigintillion',
}

return {
	groups = groups,
	position = position,
	positionOrdinal = positionOrdinal,
	positionTens = positionTens,
	positionTensOrdinal = positionTensOrdinal,
	zeroOrdinal = 'zeroth',
}
