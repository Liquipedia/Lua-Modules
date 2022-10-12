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

function suite:testGetExchangeRate()
	self:assertEquals(1.45, Currency.getExchangeRate{currency = 'EUR', currencyRate = '1.45', setVariables = true})
	self:assertEquals(1.45, tonumber(Variables.varDefault('exchangerate_EUR')))
	self:assertEquals(0.97035563534035, Currency.getExchangeRate{date = '2022-10-10', currency = 'EUR'})
end

function suite:testFormatMoney()
	self:assertEquals(0, Currency.formatMoney('abc'))
	self:assertEquals(0, Currency.formatMoney(nil))
	self:assertEquals('12', Currency.formatMoney(12))
	self:assertEquals('1,200', Currency.formatMoney(1200))
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
			symbol = '€',
			text = {
				prefix = '€',
				suffix = '&nbsp;<abbr title="Euro">EUR</abbr>',
			},
		},
		Currency.raw('EUR')
	)
end

function suite:testDisplay()
	self:assertEquals(nil, Currency.display())
	self:assertEquals(nil, Currency.display(''))
	self:assertEquals(nil, Currency.display('dummy'))
	self:assertEquals('€1,200&nbsp;<abbr title="Euro">EUR</abbr>', Currency.display('EUR', 1200, {formatValue = true}))
	self:assertEquals('€1200&nbsp;<abbr title="Euro">EUR</abbr>', Currency.display('EUR', 1200))
	self:assertEquals('€&nbsp;<abbr title="Euro">EUR</abbr>', Currency.display('EUR'))
end

return suite
