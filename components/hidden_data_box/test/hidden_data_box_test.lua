---
-- @Liquipedia
-- wiki=commons
-- page=Module:HiddenDataBox/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local HDB = Lua.import('Module:HiddenDataBox', {requireDevIfEnabled = true})
local LpdbMock = Lua.import('Module:Mock/Lpdb', {requireDevIfEnabled = true})
local String = Lua.import('Module:StringUtils', {requireDevIfEnabled = true})
local Variables = Lua.import('Module:Variables', {requireDevIfEnabled = true})
local WarningBox = Lua.import('Module:WarningBox', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testTier()
	self:assertEquals(nil, HDB.validateTier())
	self:assertEquals('1', HDB.validateTier('1', 'tiers'))
	self:assertEquals('Qualifier', HDB.validateTier('Qualifier', 'types'))

	local warning, _

	_, warning = HDB.validateTier('Qualifier', 'tiers')
	self:assertEquals(
		'Qualifier is not a known Liquipedia Tier[[Category:Pages with invalid Tier]]',
		warning
	)

	_, warning = HDB.validateTier('Abc', 'types')
	self:assertEquals(
		'Abc is not a known Liquipedia Tier Type[[Category:Pages with invalid Tier Type]]',
		warning
	)
end

function suite:testMissingParent()
	local title = tostring(mw.title.getCurrentTitle().basePageTitle):gsub(' ', '_')
	self:assertEquals(
		tostring(WarningBox.display(title .. ' is not a Liquipedia Tournament[[Category:Pages with invalid parent]]')),
		HDB.run()
	)
	self:assertEquals(
		tostring(WarningBox.display('DummyPage is not a Liquipedia Tournament[[Category:Pages with invalid parent]]')),
		HDB.run({parent = 'DummyPage'})
	)
end

function suite:testComplete()
	LpdbMock.setUp()

	local warning = HDB.run{parent = 'Six_Lounge_Series/4'}
	-- Check empty warning
	self:assertTrue(String.isEmpty(warning))

	-- Check tournament wiki variables
	self:assertEquals('Six_Lounge_Series/4', Variables.varDefault('tournament_parent'))
	self:assertEquals('Six Lounge Series #4 - Finals', Variables.varDefault('tournament_name'))
	self:assertEquals('2017-12-17', Variables.varDefault('tournament_startdate'))

	-- Check player wiki variables
	self:assertEquals('Xy_G', Variables.varDefault('BUTEO eSports_p5'))
	self:assertEquals('xy_G', Variables.varDefault('BUTEO eSports_p5dn'))
	self:assertEquals('Germany', Variables.varDefault('BUTEO eSports_p5flag'))

	LpdbMock.tearDown()
end

return suite
