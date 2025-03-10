--- Triple Comment to Enable our LLS Plugin
describe('currency', function()
	local Currency = require('Module:Currency')
	local Variables = require('Module:Variables')

	local DASH = '-'

	describe('get exchange rate', function()
		it('do it', function()
			assert.are_equal(1.45,
				Currency.getExchangeRate({currency = 'EUR', currencyRate = '1.45', setVariables = true}))
			assert.are_equal(1.45, tonumber(Variables.varDefault('exchangerate_EUR')))
			assert.are_equal(0.97097276906869, Currency.getExchangeRate{date = '2022-10-10', currency = 'EUR'})
		end)
	end)

	describe('formatting money', function()
		it('do it', function()
			assert.are_equal(DASH, Currency.formatMoney('abc'))
			assert.are_equal(DASH, Currency.formatMoney(nil))
			assert.are_equal(DASH, Currency.formatMoney('0'))
			assert.are_equal(DASH, Currency.formatMoney(0))
			assert.are_equal(0, Currency.formatMoney('abc', nil, nil, false))
			assert.are_equal(0, Currency.formatMoney(nil, nil, nil, false))
			assert.are_equal('12', Currency.formatMoney(12))
			assert.are_equal('1,200', Currency.formatMoney(1200))
			assert.are_equal('1,200.00', Currency.formatMoney(1200, nil, true))
			assert.are_equal('1,200.12', Currency.formatMoney(1200.12345))
			assert.are_equal('1,200.1', Currency.formatMoney(1200.12345, 1))
			assert.are_equal('1,200.1235', Currency.formatMoney(1200.12345, 4))
		end)
	end)

	describe('raw', function()
		it('validate incorrect input returns nil', function()
			assert.is_nil(Currency.raw())
			assert.is_nil(Currency.raw(''))
			assert.is_nil(Currency.raw('dummy'))
		end)
		it('correct data works', function()
			assert.are_same({
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
		end)
	end)

	describe('display', function()
		it('validate incorrect input returns nil', function()
			assert.is_nil(Currency.display())
			assert.is_nil(Currency.display(''))
			assert.is_nil(Currency.display('dummy'))
		end)
		it('validate options', function()
			assert.are_equal(DASH, Currency.display('dummy', 0, {dashIfZero = true}))
			assert.are_equal(DASH, Currency.display('EUR', 0, {dashIfZero = true}))
			assert.are_equal('€1,200&nbsp;<abbr title="Euro">EUR</abbr>',
				Currency.display('EUR', 1200, {formatValue = true}))
			assert.are_equal('€1200&nbsp;<abbr title="Euro">EUR</abbr>', Currency.display('EUR', 1200))
			assert.are_equal('€&nbsp;<abbr title="Euro">EUR</abbr>', Currency.display('EUR'))
			assert.are_equal('€ EUR', Currency.display('EUR', nil, {useHtmlStyling = false}))
		end)
	end)
end)
