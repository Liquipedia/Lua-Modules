--- Triple Comment to Enable our LLS Plugin
describe('Variables', function()
	local Locale = require('Module:Locale')

	local NON_BREAKING_SPACE = '&nbsp;'

	describe('format location', function()
		it('verify', function()
			assert.are_equal('', Locale.formatLocation{})
			assert.are_equal('abc,' .. NON_BREAKING_SPACE, Locale.formatLocation{city = 'abc'})
			assert.are_equal('Sweden', Locale.formatLocation{country = 'Sweden'})
			assert.are_equal('abc,' .. NON_BREAKING_SPACE .. 'Sweden',
				Locale.formatLocation{city = 'abc', country = 'Sweden'})
		end)
	end)

	describe('format locations', function()
		it('verify', function()
			local test1 = {venue = 'Abc', country1 = 'Sweden', country2 = 'Europe'}
			local result1 = {country1 = 'se', region2 = 'Europe', venue1 = 'Abc'}

			local test2 = {venue = 'Abc', country1 = 'Sweden', region1 = 'Europe', venuelink = 'https://lmgtfy.app/'}
			local result2 = {country1 = 'se', region1 = 'Europe', venue1 = 'Abc', venuelink1 = 'https://lmgtfy.app/'}

			assert.are_same(result1, Locale.formatLocations(test1))
			assert.are_same(result2, Locale.formatLocations(test2))
			assert.are_same({}, Locale.formatLocations{dummy = true})
		end)
	end)
end)
