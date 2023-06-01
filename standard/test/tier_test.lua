---
-- @Liquipedia
-- wiki=commons
-- page=Module:Tier/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@diagnostic disable: param-type-mismatch

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Tier = Lua.import('Module:Tier/Utils', {requireDevIfEnabled = true})
local TierData = mw.loadData('Module:Tier/Data')

local suite = ScribuntoUnit:new()

function suite:testToIdentifier()
	self:assertEquals('showmatch', Tier.toIdentifier('ShOW MatCh'))
	self:assertEquals(1, Tier.toIdentifier('1'))
	self:assertEquals(1, Tier.toIdentifier(1))
	self:assertEquals(nil, Tier.toIdentifier(''))
	self:assertEquals(nil, Tier.toIdentifier())
end

function suite:testRaw()
	self:assertDeepEquals({TierData.tiers[1]}, {Tier.raw(1)})
	self:assertDeepEquals({TierData.tiers[1], TierData.tierTypes.misc}, {Tier.raw('1', 'misc')})
	self:assertDeepEquals({TierData.tiers[1]}, {Tier.raw('1', 'bera')})
	self:assertDeepEquals({}, {Tier.raw('bera')})
	self:assertDeepEquals({}, {Tier.raw('sedrvo', 'ergbv')})
end

function suite:testIsValid()
	self:assertTrue(Tier.isValid(1, 'showmatch'))
	self:assertTrue(Tier.isValid(1, 'show match'))
	self:assertTrue(Tier.isValid(1))
	self:assertTrue(Tier.isValid('1', 'showmatch'))
	self:assertFalse(Tier.isValid('sedrvo'))
	self:assertFalse(Tier.isValid(''))
	self:assertFalse(Tier.isValid(1, 'sedrvo'))
	self:assertTrue(Tier.isValid(1, ''))
end

function suite:testToValue()
	self:assertDeepEquals({'1', 'Showmatch'}, {Tier.toValue(1, 'show match')})
	self:assertDeepEquals({'1', 'Showmatch'}, {Tier.toValue('1', 'sho wmatch')})
	self:assertDeepEquals({'1', 'Showmatch'}, {Tier.toValue(1, 'showmatch')})
	self:assertDeepEquals({'1'}, {Tier.toValue(1, 'avberw')})
	self:assertDeepEquals({'1'}, {Tier.toValue(1)})
	self:assertDeepEquals({}, {Tier.toValue(nil, 'avberw')})
	self:assertDeepEquals({}, {Tier.toValue('srntbg', 'avberw')})
end

function suite:testToName()
	self:assertDeepEquals({'S-Tier', 'Showmatch'}, {Tier.toName(1, 'showma tch')})
	self:assertDeepEquals({'S-Tier'}, {Tier.toName(1)})
	self:assertDeepEquals({}, {Tier.toName('sedrvo')})
end

function suite:testToShortName()
	self:assertDeepEquals({'S', 'Showm.'}, {Tier.toShortName(1, 's howmatch')})
	self:assertDeepEquals({'S'}, {Tier.toShortName(1)})
	self:assertDeepEquals({}, {Tier.toShortName('sedrvo')})
end

function suite:testToCategory()
	self:assertDeepEquals({'A-Tier Tournaments', 'Miscellaneous Tournaments'}, {Tier.toCategory(2, 'misc')})
	self:assertDeepEquals({'A-Tier Tournaments'}, {Tier.toCategory(2)})
	self:assertDeepEquals({'A-Tier Tournaments'}, {Tier.toCategory(2, 'dszm')})
	self:assertDeepEquals({}, {Tier.toCategory('seatrh')})
end

function suite:toSortValue()
	self:assertEquals('A1A9', Tier.toSortValue('1', 'misc'))
	self:assertEquals('A1', Tier.toSortValue('1'))
	self:assertThrows(function() return Tier.toSortValue('abtenr') end)
	self:assertThrows(function() return Tier.toSortValue('abtenr', 'misc') end)
end

function suite:testDisplay()
	-- plain display without any options
	self:assertEquals('Showmatch&nbsp;(S-Tier)', Tier.display(1, 'show MaTcH'))
	self:assertEquals('S-Tier', Tier.display(1))

	-- onlyTierTypeIfBoth option
	self:assertEquals('Showmatch', Tier.display(1, 'show MaTcH', {onlyTierTypeIfBoth = 1}))
	self:assertEquals('S-Tier', Tier.display(1, nil, {onlyTierTypeIfBoth = 1}))

	-- short options
	self:assertEquals('Showmatch&nbsp;(S)', Tier.display(1, 'show MaTcH', {tierShort = 1}))
	self:assertEquals('Showm.&nbsp;(S-Tier)', Tier.display(1, 'show MaTcH', {tierTypeShort = 1}))
	self:assertEquals('Showm.&nbsp;(S)', Tier.display(1, 'show MaTcH', {short = 1}))
	self:assertEquals('Showm.&nbsp;(S)', Tier.display(1, 'show MaTcH', {shortIfBoth = 1}))
	self:assertEquals('S-Tier', Tier.display(1, nil, {shortIfBoth = 1}))

	-- link options
	self:assertEquals(mw.text.decode('[[S-Tier Tournaments|S-Tier]]'), Tier.display(1, nil, {link = 1}))
	self:assertEquals(mw.text.decode('[[TEST|S-Tier]]'), Tier.display(1, nil, {link = 'TEST'}))
	self:assertEquals(
		mw.text.decode('[[Showmatches|Showmatch]]') .. '&nbsp;' ..mw.text.decode('([[S-Tier Tournaments|S-Tier]])'),
		Tier.display(1, 'show MaTcH', {link = 1})
	)
	self:assertEquals(
		mw.text.decode('[[TEST|Showmatch]]') .. '&nbsp;' ..mw.text.decode('([[TEST|S-Tier]])'),
		Tier.display(1, 'show MaTcH', {link = 'TEST'})
	)
	self:assertEquals(
		mw.text.decode('[[TEST|Showmatch]]') .. '&nbsp;(S-Tier)',
		Tier.display(1, 'show MaTcH', {tierTypeLink = 'TEST'})
	)
	self:assertEquals(
		mw.text.decode('[[TEST|Showmatch]]') .. '&nbsp;' ..mw.text.decode('([[S-Tier Tournaments|S-Tier]])'),
		Tier.display(1, 'show MaTcH', {link = 1, tierTypeLink = 'TEST'})
	)
	self:assertEquals(
		'Showmatch&nbsp;' ..mw.text.decode('([[TEST|S-Tier]])'),
		Tier.display(1, 'show MaTcH', {tierLink = 'TEST'})
	)
	self:assertEquals(
		mw.text.decode('[[Showmatches|Showmatch]]') .. '&nbsp;' ..mw.text.decode('([[TEST|S-Tier]])'),
		Tier.display(1, 'show MaTcH', {link = 1, tierLink = 'TEST'})
	)
end

return suite
