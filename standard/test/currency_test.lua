---
-- @Liquipedia
-- wiki=commons
-- page=Module:Currency/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Currency = Lua.import('Module:Currency', {requireDevIfEnabled = true})
local Variables = Lua.import('Module:Variables', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

local DASH = '-'

function suite:testGetExchangeRate()
	self:assertEquals(1.45, Currency.getExchangeRate{currency = 'EUR', currencyRate = '1.45', setVariables = true})
	self:assertEquals(1.45, tonumber(Variables.varDefault('exchangerate_EUR')))
	self:assertEquals(0.97035563534035, Currency.getExchangeRate{date = '2022-10-10', currency = 'EUR'})
end

function suite:testFormatMoney()
	self:assertEquals(DASH, Currency.formatMoney('abc'))
	self:assertEquals(DASH, Currency.formatMoney(nil))
	self:assertEquals(DASH, Currency.formatMoney('0'))
	self:assertEquals(DASH, Currency.formatMoney(0))
	self:assertEquals(0, Currency.formatMoney('abc', nil, nil, false))
	self:assertEquals(0, Currency.formatMoney(nil, nil, nil, false))
	self:assertEquals('12', Currency.formatMoney(12))
	self:assertEquals('1,200', Currency.formatMoney(1200))
	self:assertEquals('1,200.00', Currency.formatMoney(1200, nil, true))
	self:assertEquals('1,200.12', Currency.formatMoney(1200.12345))
	self:assertEquals('1,200.1', Currency.formatMoney(1200.12345, 1))
	self:assertEquals('1,200.1235', Currency.formatMoney(1200.12345, 4))
end

function suite:testRaw()
	self:assertEquals(nil, Currency.raw())
	self:assertEquals(nil, Currency.raw(''))
	self:assertEquals(nil, Currency.raw('dummy'))
	self:assertDeepEquals({
			code = 'EUR',
			name = 'Euro',
			symbol = {
				hasSpace = false,
				isAfter = false,
				text = '€',
			},
		},
		Currency.raw('EUR')
	)
end

function suite:testDisplay()
	self:assertEquals(nil, Currency.display())
	self:assertEquals(nil, Currency.display(''))
	self:assertEquals(nil, Currency.display('dummy'))
	self:assertEquals(DASH, Currency.display('dummy', 0, {dashIfZero = true}))
	self:assertEquals(DASH, Currency.display('EUR', 0, {dashIfZero = true}))
	self:assertEquals('€1,200&nbsp;<abbr title="Euro">EUR</abbr>', Currency.display('EUR', 1200, {formatValue = true}))
	self:assertEquals('€1200&nbsp;<abbr title="Euro">EUR</abbr>', Currency.display('EUR', 1200))
	self:assertEquals('€&nbsp;<abbr title="Euro">EUR</abbr>', Currency.display('EUR'))
end

return suite
