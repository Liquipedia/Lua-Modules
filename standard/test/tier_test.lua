---
-- @Liquipedia
-- wiki=commons
-- page=Module:Tier/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Tier = Lua.import('Module:Tier/Utils', {requireDevIfEnabled = true})
local TierData = mw.loadData('Module:Tier/Data')

local suite = ScribuntoUnit:new()

function suite:testToIdentifier()
	self:assertEquals('showmatch', Tier.toIdentifier('ShOW MatCh'))
	self:assertEquals(1, Tier.toIdentifier('1'))
	self:assertEquals(1, Tier.toIdentifier(1))
	self:assertEquals('', Tier.toIdentifier(''))
	self:assertEquals('', Tier.toIdentifier())
end

function suite:testIsValid()
	self:assertTrue(Tier.isValid('showmatch', 'tierTypes'))
	self:assertFalse(Tier.isValid('1', 'tiers'))
	self:assertTrue(Tier.isValid(1, 'tiers'))
	self:assertTrue(Tier.isValid('', 'tiers'))
	self:assertTrue(Tier.isValid(nil, 'tierTypes'))
	self:assertFalse(Tier.isValid('sedrvo', 'tiers'))
	self:assertFalse(Tier.isValid('sedrvo', 'tierTypes'))
end

function suite:testToValue()
	self:assertEquals('Show Match', Tier.toValue('showmatch', 'tierTypes'))
	self:assertEquals('1', Tier.toValue(1, 'tiers'))
	self:assertEquals(nil, Tier.toValue('sedrvo', 'tiers'))
end

function suite:testToName()
	self:assertEquals('Show Match', Tier.toName('showmatch', 'tierTypes'))
	self:assertEquals('S-Tier', Tier.toName(1, 'tiers'))
	self:assertEquals(nil, Tier.toName('sedrvo', 'tiers'))
end

function suite:testToShortName()
	self:assertEquals('Show&nbsp;M.', Tier.toShortName('showmatch', 'tierTypes'))
	self:assertEquals('S', Tier.toShortName(1, 'tiers'))
	self:assertEquals(nil, Tier.toShortName('sedrvo', 'tiers'))
end

function suite:testToCategory()
	self:assertEquals('Miscellaneous Tournaments', Tier.toCategory('misc', 'tierTypes'))
	self:assertEquals('Show Match Tournaments', Tier.toCategory('showmatch', 'tierTypes'))
	self:assertEquals(nil, Tier.toCategory('showmatch', 'tiers'))
	self:assertEquals('S-Tier Tournaments', Tier.toCategory(1, 'tiers'))
	self:assertEquals(nil, Tier.toCategory('sedrvo', 'tiers'))
	self:assertEquals(nil, Tier.toCategory('', 'tiers'))
	self:assertEquals(nil, Tier.toCategory('', 'tierTypes'))
end

function suite:testRaw()
	self:assertDeepEquals(TierData.tiers[1], Tier.raw(1, 'tiers'))
	self:assertDeepEquals(TierData.tierTypes.misc, Tier.raw('misc', 'tierTypes'))
	self:assertEquals(nil, Tier.raw('misc', 'tiers'))
	self:assertEquals(nil, Tier.raw(1, 'tierTypes'))
	self:assertEquals(nil, Tier.raw('sedrvo', 'tierTypes'))
end

function suite:testDisplay()
	self:assertEquals('Show Match&nbsp;(S-Tier)', Tier.display(Tier.parseArgsForDisplay{tier = 1, tiertype = 'ShOW MatCh'}))
	self:assertEquals('Show&nbsp;M.&nbsp;(S)', Tier.display(Tier.parseArgsForDisplay{
		tier = 1, tiershort = 1,
		tiertype = 'ShOW MatCh', tiertypeshort = 1,
	}))
	self:assertEquals(mw.text.decode('[[S-Tier Tournaments|S-Tier]]'),
		Tier.display(Tier.parseArgsForDisplay{tier = 1, tierlink = 1}))
	self:assertEquals(mw.text.decode('[[S-Tier Tournaments|S-Tier]]'),
		Tier.display(Tier.parseArgsForDisplay{tier = 1, tierlink = 1}))
	self:assertEquals(mw.text.decode('<span style=\"display:none\">A1</span>[[S-Tier Tournaments|S-Tier]]'),
		Tier.display(Tier.parseArgsForDisplay{tier = 1, tierlink = 1, tiersort = 1}))
	self:assertEquals(
		mw.text.decode('[[Show Matches|Show')
			.. '&nbsp;' .. mw.text.decode('M.]]') .. '&nbsp;(Undefined)',
		Tier.display(Tier.parseArgsForDisplay{tiertype = 'ShOW MatCh', tiertypeshort = 1, tiertypelink = 1})
	)
	self:assertEquals(mw.text.decode('<span style=\"display:none\">A1</span>[[S-Tier Tournaments|S-Tier]]'),
		Tier.display(Tier.parseArgsForDisplay{tier = 1, tierlink = 1, tiersort = 1}))
	self:assertEquals(
		mw.text.decode('[[Show Matches|Show') .. '&nbsp;' .. mw.text.decode('M.]]')
			.. '&nbsp;' .. mw.text.decode('([[S-Tier Tournaments|S]])'),
		Tier.display(Tier.parseArgsForDisplay{
			tier = 1, tiershort = 1, tierlink = 1,
			tiertype = 'ShOW MatCh', tiertypeshort = 1, tiertypelink = 1,
		})
	)
end

return suite
