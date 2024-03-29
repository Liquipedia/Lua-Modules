--- Triple Comment to Enable our LLS Plugin
describe('logic', function()
	local String = require('Module:StringUtils')


	describe('starts with', function()
		it('check', function()
			assert.is_false(String.startsWith('Cookie', 'banana'))
			assert.is_false(String.startsWith('Banana', 'banana'))
			assert.is_false(String.startsWith('Cookie & banana', 'banana'))
			assert.is_true(String.startsWith('banana', 'banana'))
			assert.is_true(String.startsWith('banana milkshake', 'banana'))
		end)
	end)

	describe('ends with', function()
		it('check', function()
			assert.is_false(String.endsWith('Cookie', 'banana'))
			assert.is_false(String.endsWith('Banana', 'banana'))
			assert.is_true(String.endsWith('Cookie & banana', 'banana'))
			assert.is_true(String.endsWith('banana', 'banana'))
			assert.is_false(String.endsWith('banana milkshake', 'banana'))
		end)
	end)

	describe('split', function()
		it('check', function()
			assert.are_same({''}, String.split())
			assert.are_same({'hello', 'world'}, String.split('hello world'))
			assert.are_same({'he', 'o wor', 'd'}, String.split('hello world', 'l'))
			assert.are_same({'he', 'o world'}, String.split('hello world', 'll'))
		end)
	end)

	describe('trim', function()
		it('check', function()
			assert.are_equal('', String.trim(''))
			assert.are_equal('hello world', String.trim('hello world'))
			assert.are_equal('hello world', String.trim(' hello world'))
			assert.are_equal('hello world', String.trim('hello world '))
			assert.are_equal('hello world', String.trim(' hello world '))
		end)
	end)

	describe('nil if empty', function()
		it('check', function()
			assert.is_nil(String.nilIfEmpty(''))
			assert.is_nil(String.nilIfEmpty())
			assert.is_nil(String.nilIfEmpty(nil))
			assert.are_equal('hello world', String.nilIfEmpty('hello world'))
		end)
	end)

	describe('is empty', function()
		it('check', function()
			assert.is_true(String.isEmpty(''))
			assert.is_true(String.isEmpty())
			assert.is_true(String.isEmpty(nil))
			assert.is_false(String.isEmpty('hello world'))
		end)
	end)

	describe('is not empty', function()
		it('check', function()
			assert.is_false(String.isNotEmpty(''))
			assert.is_false(String.isNotEmpty())
			assert.is_false(String.isNotEmpty(nil))
			assert.is_true(String.isNotEmpty('hello world'))
		end)
	end)

	describe('interpolate', function()
		it('check', function()
			assert.are_equal('', String.interpolate('', {}))
			assert.are_equal('I\'m 40 years old', String.interpolate('I\'m ${age} years old', {age = 40}))
		end)
	end)

	describe('upper case first letter', function()
		it('check', function()
			assert.are_equal('Top', String.upperCaseFirst('top'))
			-- test with non-ascii character (string.upper only works on ascii characters)
			assert.are_equal('Übung', String.upperCaseFirst('übung'))
		end)
	end)
end)
